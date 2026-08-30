import os
import requests
import json
import time

SERVER_URL = "http://127.0.0.1:8080"
AUDIO_PATH = "test_audio/hindi_test.wav"

print(f"Testing {SERVER_URL}/status ...")
try:
    r = requests.get(f"{SERVER_URL}/status", timeout=10)
    print("Status:", r.status_code, r.json())
except Exception as e:
    print("Status error:", e)

if os.path.exists(AUDIO_PATH):
    print(f"\nTesting {SERVER_URL}/asr with {AUDIO_PATH} ...")
    try:
        with open(AUDIO_PATH, 'rb') as f:
            files = {'audio': ('hindi_test.wav', f, 'audio/wav')}
            t0 = time.time()
            r = requests.post(f"{SERVER_URL}/asr", files=files, timeout=90)
            elapsed = time.time() - t0
            print(f"ASR Status ({elapsed:.2f}s):", r.status_code)
            print("ASR Response:", r.json())
    except Exception as e:
        print("ASR error:", e)

print(f"\nTesting {SERVER_URL}/translate ...")
try:
    t0 = time.time()
    r = requests.post(f"{SERVER_URL}/translate", json={"text": "आज हम संख्याएँ सीखेंगे", "src": "hin_Deva", "tgt": "sat_Olck"}, timeout=30)
    elapsed = time.time() - t0
    print(f"Translate Status ({elapsed:.2f}s):", r.status_code)
    print("Translate Response:", r.json())
except Exception as e:
    print("Translate error:", e)
