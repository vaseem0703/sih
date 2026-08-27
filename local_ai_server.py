import os
import sys
import json
import time
import re
import base64
import tarfile
import torch
import numpy as np
import soundfile as sf
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

sys.stdout.reconfigure(encoding='utf-8')

# Monkey-patch tarfile.TarFile.extract for compatibility
_orig_extract = tarfile.TarFile.extract
def _patched_extract(self, member, path=None, set_attrs=True, *, numeric_owner=False, **kwargs):
    return _orig_extract(self, member, path=path, set_attrs=set_attrs, numeric_owner=numeric_owner)
tarfile.TarFile.extract = _patched_extract

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INDICTRANS2_DIR = os.path.join(BASE_DIR, "models", "indictrans2")
QUIPUS_DIR = os.path.join(BASE_DIR, "models", "quipus")
INDICCONFORMER_PATH = os.path.join(BASE_DIR, "models", "indicconformer", "indicconformer_stt_hi_hybrid_rnnt_large.nemo")
OUTPUT_AUDIO_DIR = os.path.join(BASE_DIR, "test_audio", "live_outputs")
os.makedirs(OUTPUT_AUDIO_DIR, exist_ok=True)

print("=" * 70)
print("  SIH 26042 — FULL REAL-TIME OFFLINE AI SERVER (ASR + NMT + TTS)")
print("=" * 70)

# Multi-threaded CPU acceleration
num_threads = min(16, max(4, os.cpu_count() or 8))
torch.set_num_threads(num_threads)
try:
    torch.set_num_interop_threads(2)
except Exception:
    pass
print(f"[AI Server] PyTorch CPU Multi-threading configured with {num_threads} cores.")

# Global model references
tokenizer_trans = None
model_trans = None
tokenizer_tts = None
model_tts = None
snac_decoder = None
asr_model = None

FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]
SAMPLE_RATE = 24000

def _setup_nemo_patches():
    try:
        import nemo.collections.asr as nemo_asr
        from nemo.collections.asr.parts.mixins.mixins import ASRBPEMixin
        import nemo.collections.asr.modules.rnnt as nemo_rnnt
        import nemo.collections.asr.modules as nemo_modules
        from nemo.core.connectors.save_restore_connector import SaveRestoreConnector

        _orig_load_instance = SaveRestoreConnector.load_instance_with_state_dict
        def _patched_load_instance(self, instance, state_dict, strict=True):
            if "joint.joint_net.2.hi.weight" in state_dict:
                state_dict["joint.joint_net.2.weight"] = state_dict["joint.joint_net.2.hi.weight"]
            if "joint.joint_net.2.hi.bias" in state_dict:
                state_dict["joint.joint_net.2.bias"] = state_dict["joint.joint_net.2.hi.bias"]
            if "decoder.prediction.embed.weight" in state_dict and hasattr(instance, 'decoder') and hasattr(instance.decoder, 'prediction'):
                ckpt_embed = state_dict["decoder.prediction.embed.weight"]
                model_embed = instance.decoder.prediction.embed.weight
                if ckpt_embed.shape != model_embed.shape and ckpt_embed.shape[1] == model_embed.shape[1]:
                    state_dict["decoder.prediction.embed.weight"] = ckpt_embed[:model_embed.shape[0]]
            return _orig_load_instance(self, instance, state_dict, strict=False)
        SaveRestoreConnector.load_instance_with_state_dict = _patched_load_instance

        if hasattr(nemo_modules.conv_asr, 'ConvASRDecoder'):
            nemo_modules.conv_asr.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])
        if hasattr(nemo_modules, 'ConvASRDecoder'):
            nemo_modules.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])

        def make_clean_init(orig_init):
            def _patched_init(self, *args, **kwargs):
                for key in ['multisoftmax', 'multilingual', 'language_keys', 'num_classes_per_language']:
                    kwargs.pop(key, None)
                pop_vocab = False
                if 'vocabulary' in kwargs and 'num_classes' in kwargs:
                    vocab = kwargs['vocabulary']
                    num_classes = kwargs['num_classes']
                    if vocab is not None and hasattr(vocab, '__len__') and len(vocab) != num_classes:
                        kwargs.pop('vocabulary')
                        pop_vocab = True
                res = orig_init(self, *args, **kwargs)
                if pop_vocab or not hasattr(self, '_vocabulary'):
                    object.__setattr__(self, '_vocabulary', [])
                return res
            return _patched_init

        nemo_rnnt.RNNTDecoder.__init__ = make_clean_init(nemo_rnnt.RNNTDecoder.__init__)
        if hasattr(nemo_rnnt, 'RNNTJoint'):
            nemo_rnnt.RNNTJoint.__init__ = make_clean_init(nemo_rnnt.RNNTJoint.__init__)
        if hasattr(nemo_modules, 'ConvASRDecoder'):
            nemo_modules.ConvASRDecoder.__init__ = make_clean_init(nemo_modules.ConvASRDecoder.__init__)
        if hasattr(nemo_modules.conv_asr, 'ConvASRDecoder'):
            nemo_modules.conv_asr.ConvASRDecoder.__init__ = make_clean_init(nemo_modules.conv_asr.ConvASRDecoder.__init__)

        _orig_setup_tokenizer = ASRBPEMixin._setup_tokenizer
        def _patched_setup_tokenizer(self, tokenizer_cfg):
            if tokenizer_cfg is not None and getattr(tokenizer_cfg, 'type', None) == 'multilingual':
                if hasattr(tokenizer_cfg, 'langs') and 'hi' in tokenizer_cfg.langs:
                    tokenizer_cfg = tokenizer_cfg.langs.hi
                elif hasattr(tokenizer_cfg, 'langs'):
                    first_lang = list(tokenizer_cfg.langs.keys())[0]
                    tokenizer_cfg = tokenizer_cfg.langs[first_lang]
            return _orig_setup_tokenizer(self, tokenizer_cfg)
        ASRBPEMixin._setup_tokenizer = _patched_setup_tokenizer
    except Exception as e:
        print(f"[AI Server] NeMo patch info: {e}")

import threading

asr_lock = threading.Lock()
trans_lock = threading.Lock()
tts_lock = threading.Lock()

def load_asr_model():
    global asr_model
    with asr_lock:
        if asr_model is not None:
            return
        if os.path.exists(INDICCONFORMER_PATH):
            try:
                print("[AI Server] Loading IndicConformer Hindi ASR Model...")
                _setup_nemo_patches()
                import nemo.collections.asr as nemo_asr
                asr_model = nemo_asr.models.EncDecHybridRNNTCTCBPEModel.restore_from(INDICCONFORMER_PATH, map_location="cpu")
                print("[AI Server] IndicConformer ASR loaded successfully!")
            except Exception as e:
                try:
                    import nemo.collections.asr as nemo_asr
                    asr_model = nemo_asr.models.ASRModel.restore_from(INDICCONFORMER_PATH, map_location="cpu")
                    print("[AI Server] IndicConformer ASR loaded via ASRModel!")
                except Exception as err:
                    print(f"[AI Server] IndicConformer load notice: {err}")

def load_translation_model():
    global tokenizer_trans, model_trans
    with trans_lock:
        if model_trans is not None:
            return
        if os.path.exists(INDICTRANS2_DIR):
            print("[AI Server] Loading IndicTrans2 Translation Model...")
            from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
            tokenizer_trans = AutoTokenizer.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True)
            model_trans = AutoModelForSeq2SeqLM.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True).to("cpu").eval()
            print("[AI Server] IndicTrans2 loaded successfully!")

def load_tts_model():
    global tokenizer_tts, model_tts, snac_decoder
    with tts_lock:
        if model_tts is not None:
            return
        if os.path.exists(QUIPUS_DIR):
            try:
                print("[AI Server] Loading Quipus TTS Model & SNAC Vocoder...")
                from transformers import AutoTokenizer, AutoModelForCausalLM
                from snac import SNAC
                tokenizer_tts = AutoTokenizer.from_pretrained(QUIPUS_DIR, local_files_only=True, use_fast=False)
                model_tts = AutoModelForCausalLM.from_pretrained(
                    QUIPUS_DIR,
                    local_files_only=True,
                    dtype=torch.float32
                ).to("cpu").eval()
                snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")
                print("[AI Server] Quipus TTS & SNAC loaded successfully!")
            except Exception as e:
                print(f"[AI Server] Quipus TTS note: {e}")

def transcribe_hindi_audio(audio_path):
    load_asr_model()
    if asr_model is not None:
        try:
            target_path = audio_path
            try:
                import librosa
                y, sr = librosa.load(audio_path, sr=16000, mono=True)
                clean_path = audio_path.replace('.wav', '_clean.wav').replace('.m4a', '_clean.wav')
                sf.write(clean_path, y, 16000, subtype='PCM_16')
                target_path = clean_path
            except Exception as clean_err:
                print(f"[AI Server] Audio clean notice: {clean_err}")

            with torch.inference_mode():
                try:
                    transcriptions = asr_model.transcribe(audio=[target_path], batch_size=1, num_workers=0)
                except TypeError:
                    transcriptions = asr_model.transcribe([target_path])
                
                if isinstance(transcriptions, tuple):
                    transcriptions = transcriptions[0]
                if isinstance(transcriptions, list) and len(transcriptions) > 0:
                    first = transcriptions[0]
                    if hasattr(first, 'text'):
                        return first.text.strip()
                    return str(first).strip()
                elif isinstance(transcriptions, str):
                    return transcriptions.strip()
        except Exception as e:
            print(f"[AI Server] IndicConformer inference error: {e}")
    return None

def translate_hindi_to_santali(text):
    load_translation_model()
    if model_trans is None or tokenizer_trans is None:
        return None, "Translation model unavailable"
    
    formatted_input = f"hin_Deva sat_Olck {text}"
    tgt_lang_id = tokenizer_trans.tgt_encoder.get("sat_Olck")
    inputs = tokenizer_trans(formatted_input, return_tensors="pt").to("cpu")
    
    with torch.no_grad():
        gen_tokens = model_trans.generate(
            **inputs,
            forced_bos_token_id=tgt_lang_id,
            use_cache=False,
            min_length=0,
            max_length=256,
            num_beams=4
        )
    santali_text = tokenizer_trans.batch_decode(gen_tokens, skip_special_tokens=True)[0]
    return santali_text, "Santali (Ol Chiki)"

def synthesize_santali_tts(speaker, text, filename="output.wav"):
    load_tts_model()
    out_path = os.path.join(OUTPUT_AUDIO_DIR, filename)
    
    if model_tts is None or snac_decoder is None or tokenizer_tts is None:
        return None, 0.0

    prompt = f"{speaker}: {text} <audio_start> "
    inputs = tokenizer_tts(prompt, return_tensors="pt").to("cpu")
    
    # Calculate optimal token count based on sentence length for complete untruncated TTS
    dynamic_max_tokens = min(512, max(64, len(text) * 8))

    t0 = time.time()
    with torch.no_grad():
        outputs = model_tts.generate(
            **inputs,
            max_new_tokens=dynamic_max_tokens,
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            repetition_penalty=1.2,
            pad_token_id=tokenizer_tts.pad_token_id or tokenizer_tts.eos_token_id
        )
    
    generated_ids = outputs[0][inputs['input_ids'].shape[1]:].tolist()
    tokens = tokenizer_tts.convert_ids_to_tokens(generated_ids)

    parsed = []
    for tok in tokens:
        match = re.fullmatch(r"<snac_l(\d+)_c(\d+)>", tok)
        if match:
            parsed.append((int(match.group(1)), int(match.group(2))))

    l0, l1, l2 = [], [], []
    i = 0
    while i + 7 <= len(parsed):
        window = parsed[i:i+7]
        if [layer for layer, _ in window] == FRAME_LAYER_PATTERN:
            codes = [code for _, code in window]
            l0.append(codes[0])
            l1.extend([codes[1], codes[4]])
            l2.extend([codes[2], codes[3], codes[5], codes[6]])
            i += 7
        else:
            i += 1

    if l0:
        with torch.inference_mode():
            wav = snac_decoder.decode([
                torch.tensor([l0], dtype=torch.long, device="cpu"),
                torch.tensor([l1], dtype=torch.long, device="cpu"),
                torch.tensor([l2], dtype=torch.long, device="cpu")
            ])
        pcm = wav.squeeze().float().cpu().numpy()
        peak = np.max(np.abs(pcm))
        if peak > 0:
            pcm = (pcm / peak) * 0.95
        pcm_int16 = (pcm * 32767).astype(np.int16)
        sf.write(out_path, pcm_int16, SAMPLE_RATE, subtype='PCM_16')
    
    gen_time = time.time() - t0
    return out_path, gen_time

class LocalAIHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def do_OPTIONS(self):
        self._send_json(200, {"status": "ok"})

    def do_GET(self):
        parsed_path = urlparse(self.path).path
        if parsed_path == "/status" or parsed_path == "/":
            self._send_json(200, {
                "status": "online",
                "mode": "local_offline_ai",
                "models": {
                    "translation": "IndicTrans2 (hin_Deva -> sat_Olck)",
                    "asr": "IndicConformer (Hindi STT)",
                    "tts": "Quipus 0.6 + SNAC"
                }
            })
        elif parsed_path.startswith("/audio/"):
            filename = os.path.basename(parsed_path)
            file_path = os.path.join(OUTPUT_AUDIO_DIR, filename)
            if os.path.exists(file_path):
                self.send_response(200)
                self.send_header('Content-Type', 'audio/wav')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            else:
                self._send_json(404, {"error": "Audio file not found"})
        else:
            self._send_json(404, {"error": "Not found"})

    def do_POST(self):
        parsed_path = urlparse(self.path).path
        content_length = int(self.headers.get('Content-Length', 0))
        content_type = self.headers.get('Content-Type', '')

        if parsed_path == "/asr":
            print("[ASR Request] Processing received microphone audio...")
            start_t = time.time()
            saved_audio_path = os.path.join(OUTPUT_AUDIO_DIR, f"mic_input_{int(time.time()*1000)}.wav")

            if 'multipart/form-data' in content_type:
                body = self.rfile.read(content_length)
                boundary_marker = content_type.split("boundary=")[-1].strip('"').encode()
                parts = body.split(b'--' + boundary_marker)
                for part in parts:
                    if b'filename=' in part or b'name="audio"' in part:
                        header_end = part.find(b'\r\n\r\n')
                        if header_end != -1:
                            audio_bytes = part[header_end + 4:]
                            if audio_bytes.endswith(b'\r\n'):
                                audio_bytes = audio_bytes[:-2]
                            with open(saved_audio_path, 'wb') as f:
                                f.write(audio_bytes)
                            break
            else:
                body = self.rfile.read(content_length)
                try:
                    req_data = json.loads(body.decode('utf-8'))
                    base64_str = req_data.get('audio_base64', '')
                    if base64_str:
                        audio_bytes = base64.b64decode(base64_str)
                        with open(saved_audio_path, 'wb') as f:
                            f.write(audio_bytes)
                except Exception:
                    pass

            if os.path.exists(saved_audio_path) and os.path.getsize(saved_audio_path) > 0:
                print(f"[ASR Server] Audio file saved: {saved_audio_path} ({os.path.getsize(saved_audio_path)} bytes)")
                transcript = transcribe_hindi_audio(saved_audio_path)
                latency = time.time() - start_t
                print(f"[ASR Server] Transcribed Hindi Text: '{transcript}' ({latency:.2f}s)")
                
                self._send_json(200, {
                    "text": transcript or "",
                    "latency": round(latency, 2),
                    "source": "REAL_LOCAL_AI (IndicConformer ASR)"
                })
            else:
                self._send_json(400, {"error": "Invalid or empty audio stream received"})

        elif parsed_path == "/translate":
            body = self.rfile.read(content_length)
            try:
                req_data = json.loads(body.decode('utf-8')) if body else {}
            except Exception:
                req_data = {}

            hindi_text = req_data.get("text", "")
            if not hindi_text:
                self._send_json(400, {"error": "Missing 'text' field"})
                return

            print(f"[Translate Request] Input Hindi: {hindi_text}")
            start_t = time.time()
            santali_text, transliteration = translate_hindi_to_santali(hindi_text)
            latency = time.time() - start_t
            print(f"[Translate Result] Santali: {santali_text} ({latency:.2f}s)")

            self._send_json(200, {
                "original": hindi_text,
                "translation": santali_text,
                "transliteration": transliteration,
                "latency": round(latency, 2),
                "source": "REAL_LOCAL_AI (IndicTrans2)"
            })

        elif parsed_path == "/tts":
            body = self.rfile.read(content_length)
            try:
                req_data = json.loads(body.decode('utf-8')) if body else {}
            except Exception:
                req_data = {}

            santali_text = req_data.get("text", "")
            speaker = req_data.get("speaker", "Phulmani")
            
            print(f"[TTS Request] Speaker: {speaker} | Text: {santali_text}")
            filename = f"santali_{int(time.time())}.wav"
            out_path, gen_time = synthesize_santali_tts(speaker, santali_text, filename)
            
            if out_path and os.path.exists(out_path):
                self._send_json(200, {
                    "text": santali_text,
                    "speaker": speaker,
                    "audio_url": f"/audio/{filename}",
                    "audio_path": out_path,
                    "generation_time": round(gen_time, 2),
                    "source": "REAL_LOCAL_AI (Quipus TTS)"
                })
            else:
                self._send_json(500, {"error": "TTS synthesis failed or model unavailable"})
        else:
            self._send_json(404, {"error": "Endpoint not found"})

import socketserver

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

def warmup_models():
    print("[AI Server Warmup] Background model initialization starting...")
    load_asr_model()
    load_translation_model()
    load_tts_model()
    print("[AI Server Warmup] All models (ASR + IndicTrans2 + Quipus) ready for instant inference!")

def run_server(port=8080):
    server_address = ('0.0.0.0', port)
    httpd = ThreadedHTTPServer(server_address, LocalAIHandler)
    print(f"\n[AI Server] Running on http://0.0.0.0:{port}")
    print(f"[AI Server] For Android Emulator: http://10.0.2.2:{port}")
    print(f"[AI Server] For Local/USB App: http://127.0.0.1:{port}")
    print("[AI Server] Ready to receive live speech (ASR), translation (NMT), and TTS requests!\n")
    
    import threading
    warmup_thread = threading.Thread(target=warmup_models, daemon=True)
    warmup_thread.start()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[AI Server] Stopping...")
        httpd.server_close()

if __name__ == "__main__":
    run_server()

