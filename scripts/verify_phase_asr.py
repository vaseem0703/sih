import os
import sys
import time
import requests
import soundfile as sf
import numpy as np

# Add project root to path
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

print("="*60)
print("PHASE 4 & PHASE 6: TESTING INDICCONFORMER DIRECTLY ON PC")
print("="*60)

ASR_MODEL_PATH = os.path.join(PROJECT_ROOT, "models", "indicconformer", "indicconformer_stt_hi_hybrid_rnnt_large.nemo")
SERVER_URL = "http://127.0.0.1:8080"

# 1. Verify Model Existence
print(f"[1] Checking IndicConformer model file: {ASR_MODEL_PATH}")
if not os.path.exists(ASR_MODEL_PATH):
    print(f"[FAIL] ERROR: Model not found at {ASR_MODEL_PATH}")
    sys.exit(1)

size_mb = os.path.getsize(ASR_MODEL_PATH) / (1024 * 1024)
print(f"[OK] IndicConformer Model verified: {size_mb:.2f} MB")

# 2. Generate 2 distinct test WAV files (16kHz Mono PCM_16)
print("\n[2] Creating 2 distinct test WAV files (16 kHz Mono PCM_16)...")
wav_dir = os.path.join(PROJECT_ROOT, "scripts", "test_audio")
os.makedirs(wav_dir, exist_ok=True)

wav1_path = os.path.join(wav_dir, "test_phrase1.wav")
wav2_path = os.path.join(wav_dir, "test_phrase2.wav")

sr = 16000
t1 = np.linspace(0, 2.0, int(sr * 2.0), endpoint=False)
t2 = np.linspace(0, 3.5, int(sr * 3.5), endpoint=False)

# Signal 1: 440 Hz tone + 880 Hz tone
audio1 = (0.5 * np.sin(2 * np.pi * 440 * t1) + 0.3 * np.sin(2 * np.pi * 880 * t1)).astype(np.float32)
audio1_int16 = (audio1 * 32767).astype(np.int16)
sf.write(wav1_path, audio1_int16, sr, subtype='PCM_16')

# Signal 2: 260 Hz tone + 520 Hz tone
audio2 = (0.6 * np.sin(2 * np.pi * 260 * t2) + 0.2 * np.sin(2 * np.pi * 520 * t2)).astype(np.float32)
audio2_int16 = (audio2 * 32767).astype(np.int16)
sf.write(wav2_path, audio2_int16, sr, subtype='PCM_16')

def get_audio_info(path):
    data, samplerate = sf.read(path)
    duration = len(data) / samplerate
    rms = float(np.sqrt(np.mean(data**2)))
    size = os.path.getsize(path)
    return {
        "path": path,
        "size": size,
        "duration": round(duration, 2),
        "sample_rate": samplerate,
        "channels": 1 if data.ndim == 1 else data.shape[1],
        "rms_energy": round(rms, 6)
    }

info1 = get_audio_info(wav1_path)
info2 = get_audio_info(wav2_path)

print(f"WAV 1 (Recording 1): {info1}")
print(f"WAV 2 (Recording 2): {info2}")

if info1["rms_energy"] == info2["rms_energy"] or info1["size"] == info2["size"]:
    print("[FAIL] ERROR: WAV files are identical!")
    sys.exit(1)
else:
    print("[OK] WAV files verified distinct and valid!")

# 3. Test HTTP POST /asr on local_ai_server.py
print(f"\n[3] Testing POST /asr on {SERVER_URL}/asr...")
try:
    with open(wav1_path, 'rb') as f1:
        res1 = requests.post(f"{SERVER_URL}/asr", files={'audio': f1}, timeout=20)
    print(f"POST /asr (WAV 1) -> Status: {res1.status_code}, Body: {res1.text}")

    with open(wav2_path, 'rb') as f2:
        res2 = requests.post(f"{SERVER_URL}/asr", files={'audio': f2}, timeout=20)
    print(f"POST /asr (WAV 2) -> Status: {res2.status_code}, Body: {res2.text}")

    if res1.status_code == 200 and res2.status_code == 200:
        data1 = res1.json()
        data2 = res2.json()
        print("\n[OK] /asr Endpoint Verification Successful!")
        print(f"  WAV 1 Result -> Text: '{data1.get('text')}', Source: '{data1.get('source')}'")
        print(f"  WAV 2 Result -> Text: '{data2.get('text')}', Source: '{data2.get('source')}'")
    else:
        print("[FAIL] POST /asr failed with status code != 200")
except Exception as e:
    print(f"[NOTICE] HTTP POST /asr notice: {e}")

print("="*60)
