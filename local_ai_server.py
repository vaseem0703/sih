import os
import sys
import json
import time
import re
import base64
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
print("  SIH 26042 — LOCAL AI SERVER (INDIC-TRANS2 NMT + QUIPUS TTS)")
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

FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]
SAMPLE_RATE = 24000

import threading

trans_lock = threading.Lock()
tts_lock = threading.Lock()

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

def translate_hindi_to_santali(text):
    load_translation_model()
    if model_trans is None or tokenizer_trans is None:
        return None, "Translation model unavailable"
    
    formatted_input = f"hin_Deva sat_Olck {text}"
    inputs = tokenizer_trans(formatted_input, return_tensors="pt").to("cpu")
    
    with torch.no_grad():
        gen_tokens = model_trans.generate(
            **inputs,
            num_beams=4,
            max_length=256,
        )
    
    raw_output = tokenizer_trans.batch_decode(gen_tokens, skip_special_tokens=True)[0].strip()
    return raw_output, raw_output

def synthesize_santali_tts(speaker_name, text, out_filename):
    load_tts_model()
    if model_tts is None or tokenizer_tts is None or snac_decoder is None:
        return None, 0.0

    start_t = time.time()
    try:
        prompt = f"<speaker:{speaker_name}> {text}"
        inputs = tokenizer_tts(prompt, return_tensors="pt").to("cpu")
        with torch.no_grad():
            outputs = model_tts.generate(**inputs, max_new_tokens=500)
        gen_tokens = outputs[0][inputs.input_ids.shape[1]:].tolist()

        codes = [[], [], []]
        layer_idx = 0
        for token in gen_tokens:
            token_str = tokenizer_tts.decode([token])
            match = re.search(r'<custom_token_(\d+)>', token_str)
            if match:
                val = int(match.group(1))
                codes[FRAME_LAYER_PATTERN[layer_idx]].append(val)
                layer_idx = (layer_idx + 1) % len(FRAME_LAYER_PATTERN)

        min_frames = min(
            len(codes[0]),
            len(codes[1]) // 2,
            len(codes[2]) // 4
        )

        if min_frames > 0:
            c0 = torch.tensor(codes[0][:min_frames], dtype=torch.long).unsqueeze(0).to("cpu")
            c1 = torch.tensor(codes[1][:min_frames * 2], dtype=torch.long).unsqueeze(0).to("cpu")
            c2 = torch.tensor(codes[2][:min_frames * 4], dtype=torch.long).unsqueeze(0).to("cpu")
            
            with torch.no_grad():
                audio_hat = snac_decoder.decode([c0, c1, c2])
            
            audio_samples = audio_hat.squeeze().cpu().numpy()
            out_path = os.path.join(OUTPUT_AUDIO_DIR, out_filename)
            sf.write(out_path, audio_samples, SAMPLE_RATE)
            gen_time = time.time() - start_t
            return out_path, gen_time
    except Exception as e:
        print(f"[AI Server] TTS Synthesis error: {e}")

    return None, 0.0

class LocalAIHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def do_OPTIONS(self):
        self._send_json(200, {"status": "ok"})

    def do_GET(self):
        parsed_path = urlparse(self.path).path

        if parsed_path in ["/", "/status"]:
            self._send_json(200, {
                "status": "online",
                "device": "cpu",
                "models": {
                    "translation": "IndicTrans2 (hin_Deva -> sat_Olck)",
                    "tts": "Quipus 0.6 + SNAC",
                    "asr": "Sherpa-ONNX (100% On-Device on Phone)"
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

        if parsed_path == "/translate":
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
                    "generation_time": round(gen_time, 2)
                })
            else:
                self._send_json(500, {"error": "TTS synthesis failed"})
        else:
            self._send_json(404, {"error": "Endpoint not found"})

import socketserver

class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True

def warmup_models():
    print("[AI Server Warmup] Background model initialization starting...")
    load_translation_model()
    load_tts_model()
    print("[AI Server Warmup] All NMT + TTS models ready for instant inference!")

def run_server(port=8080):
    server_address = ('0.0.0.0', port)
    httpd = ThreadedHTTPServer(server_address, LocalAIHandler)
    print(f"\n[AI Server] Running on http://0.0.0.0:{port}")
    print("[AI Server] Ready to receive translation (NMT) and TTS requests!\n")
    
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
