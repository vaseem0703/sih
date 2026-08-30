import os
import sys

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

print("="*60)
print("TESTING INDICCONFORMER DIRECT INFERENCE IN PYTHON")
print("="*60)

import local_ai_server

wav1_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase1.wav")
wav2_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase2.wav")

print(f"[1] Testing direct ASR transcription on WAV 1 ({wav1_path})...")
res1 = local_ai_server.transcribe_hindi_audio(wav1_path)
print(f"Result 1: '{res1}'")

print(f"\n[2] Testing direct ASR transcription on WAV 2 ({wav2_path})...")
res2 = local_ai_server.transcribe_hindi_audio(wav2_path)
print(f"Result 2: '{res2}'")

print("="*60)
