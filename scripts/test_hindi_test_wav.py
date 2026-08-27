import os
import sys
import soundfile as sf
import numpy as np

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

import local_ai_server

hindi_wav = os.path.join(PROJECT_ROOT, "test_audio", "hindi_test.wav")

print("="*60)
print("TESTING REAL HINDI WAV FILE (hindi_test.wav)")
print("="*60)

if os.path.exists(hindi_wav):
    size = os.path.getsize(hindi_wav)
    data, sr = sf.read(hindi_wav)
    duration = len(data) / sr if sr > 0 else 0
    rms = float(np.sqrt(np.mean(data**2)))
    peak = float(np.max(np.abs(data)))
    
    print(f"File: {hindi_wav}")
    print(f"Size: {size} bytes | Duration: {duration:.2f}s | SR: {sr} Hz | Channels: {1 if data.ndim == 1 else data.shape[1]}")
    print(f"RMS Energy: {rms:.6f} | Peak Amplitude: {peak:.6f}")
    
    print("\nRunning IndicConformer ASR transcription...")
    local_ai_server.load_asr_model()
    text = local_ai_server.transcribe_hindi_audio(hindi_wav)
    print(f"\n📝 IndicConformer Transcription Output: '{text}'")
else:
    print(f"File not found: {hindi_wav}")
print("="*60)
