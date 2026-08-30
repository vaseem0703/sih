import os
import sys
import time
import requests

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

print("="*60)
print("VERIFYING INDICCONFORMER ASR MODEL LOADING & INFERENCE")
print("="*60)

import local_ai_server

print("\n[1] Calling local_ai_server.load_asr_model()...")
start_t = time.time()
local_ai_server.load_asr_model()
dur = time.time() - start_t

if local_ai_server.asr_model is not None:
    print(f"✅ SUCCESS: IndicConformer ASR model loaded in {dur:.2f}s!")
    print(f"   Model Type: {type(local_ai_server.asr_model)}")
else:
    print("❌ FAILURE: IndicConformer asr_model is None!")

wav1_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase1.wav")
wav2_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase2.wav")

if os.path.exists(wav1_path):
    print(f"\n[2] Testing transcribe_hindi_audio on WAV 1 ({wav1_path})...")
    res1 = local_ai_server.transcribe_hindi_audio(wav1_path)
    print(f"   WAV 1 Output: '{res1}'")

if os.path.exists(wav2_path):
    print(f"\n[3] Testing transcribe_hindi_audio on WAV 2 ({wav2_path})...")
    res2 = local_ai_server.transcribe_hindi_audio(wav2_path)
    print(f"   WAV 2 Output: '{res2}'")

print("="*60)
