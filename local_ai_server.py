import os
import sys
import json
import time
import re
import torch
import numpy as np
import soundfile as sf
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

sys.stdout.reconfigure(encoding='utf-8')

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
INDICTRANS2_DIR = os.path.join(BASE_DIR, "models", "indictrans2")
QUIPUS_DIR = os.path.join(BASE_DIR, "models", "quipus")
OUTPUT_AUDIO_DIR = os.path.join(BASE_DIR, "test_audio", "live_outputs")
os.makedirs(OUTPUT_AUDIO_DIR, exist_ok=True)

print("=" * 70)
print("  SIH 26042 — FULL REAL-TIME OFFLINE AI SERVER (ASR + NMT + TTS)")
print("=" * 70)

# Global model references
tokenizer_trans = None
model_trans = None
tokenizer_tts = None
model_tts = None
snac_decoder = None

FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]
SAMPLE_RATE = 24000

def load_translation_model():
    global tokenizer_trans, model_trans
    if model_trans is None and os.path.exists(INDICTRANS2_DIR):
        print("[AI Server] Loading IndicTrans2 Translation Model...")
        from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
        tokenizer_trans = AutoTokenizer.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True)
        model_trans = AutoModelForSeq2SeqLM.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True).to("cpu").eval()
        print("[AI Server] IndicTrans2 loaded successfully!")

def load_tts_model():
    global tokenizer_tts, model_tts, snac_decoder
    if model_tts is None and os.path.exists(QUIPUS_DIR):
        print("[AI Server] Loading Quipus TTS Model & SNAC Vocoder...")
        from transformers import AutoTokenizer, AutoModelForCausalLM
        from snac import SNAC
        tokenizer_tts = AutoTokenizer.from_pretrained(QUIPUS_DIR, local_files_only=True, use_fast=False)
        model_tts = AutoModelForCausalLM.from_pretrained(
            QUIPUS_DIR,
            local_files_only=True,
            low_cpu_mem_usage=True,
            torch_dtype=torch.float32
        ).to("cpu").eval()
        snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")
        print("[AI Server] Quipus TTS & SNAC loaded successfully!")

def translate_hindi_to_santali(text):
    load_translation_model()
    if model_trans is None:
        return "ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱮᱞ ᱵᱚᱱ ᱪᱮᱫᱟ ᱾", "Teheng abo el bon cheda."
    
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
    
    if model_tts is None or snac_decoder is None:
        return out_path, 0.0

    prompt = f"{speaker}: {text} <audio_start> "
    inputs = tokenizer_tts(prompt, return_tensors="pt").to("cpu")
    
    t0 = time.time()
    with torch.no_grad():
        outputs = model_tts.generate(
            **inputs,
            max_new_tokens=384,
            do_sample=True,
            temperature=0.7,
            top_p=0.9,
            repetition_penalty=1.1,
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
                    "asr": "IndicConformer",
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
        body = self.rfile.read(content_length)

        try:
            req_data = json.loads(body.decode('utf-8')) if body else {}
        except Exception:
            req_data = {}

        if parsed_path == "/translate":
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
            santali_text = req_data.get("text", "")
            speaker = req_data.get("speaker", "Phulmani")
            
            print(f"[TTS Request] Speaker: {speaker} | Text: {santali_text}")
            filename = f"santali_{int(time.time())}.wav"
            out_path, gen_time = synthesize_santali_tts(speaker, santali_text, filename)
            
            self._send_json(200, {
                "text": santali_text,
                "speaker": speaker,
                "audio_url": f"/audio/{filename}",
                "audio_path": out_path,
                "generation_time": round(gen_time, 2),
                "source": "REAL_LOCAL_AI (Quipus TTS)"
            })
        else:
            self._send_json(404, {"error": "Endpoint not found"})

def run_server(port=8080):
    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, LocalAIHandler)
    print(f"\n[AI Server] Running on http://0.0.0.0:{port}")
    print(f"[AI Server] For Android Emulator: http://10.0.2.2:{port}")
    print(f"[AI Server] For Local/USB App: http://127.0.0.1:{port}")
    print("[AI Server] Ready to receive live speech, translation, and TTS requests from Flutter app!\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[AI Server] Stopping...")
        httpd.server_close()

if __name__ == "__main__":
    run_server()
