import os
import sys
import glob
import numpy as np
import soundfile as sf

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

import local_ai_server

folder = os.path.join(PROJECT_ROOT, "test_audio", "live_outputs")
wav_files = sorted(glob.glob(os.path.join(folder, "*.wav")))

print("="*80)
print(f"INSPECTING ALL {len(wav_files)} RECORDED WAV FILES IN live_outputs")
print("="*80)

local_ai_server.load_asr_model()

results = []

for wav in wav_files:
    fname = os.path.basename(wav)
    size = os.path.getsize(wav)
    try:
        data, sr = sf.read(wav)
        duration = len(data) / sr if sr > 0 else 0
        channels = 1 if data.ndim == 1 else data.shape[1]
        rms = float(np.sqrt(np.mean(data**2)))
        peak = float(np.max(np.abs(data)))
        
        # Run IndicConformer transcription
        transcript = local_ai_server.transcribe_hindi_audio(wav)
        
        res = {
            "file": fname,
            "size": size,
            "duration": round(duration, 2),
            "sr": sr,
            "channels": channels,
            "rms": round(rms, 6),
            "peak": round(peak, 6),
            "transcript": transcript or ""
        }
        results.append(res)
        print(f"\n📁 File: {fname}")
        print(f"   Size: {size} bytes | Duration: {res['duration']}s | SR: {sr} | Channels: {channels}")
        print(f"   RMS: {res['rms']} | Peak: {res['peak']}")
        print(f"   📝 IndicConformer ASR Output: '{res['transcript']}'")
    except Exception as e:
        print(f"\n❌ File {fname} error: {e}")

print("\n" + "="*80)
print("SUMMARY OF ALL RECORDINGS:")
print("="*80)
for r in results:
    status = f"TEXT: '{r['transcript']}'" if r['transcript'] else "EMPTY TRANSCRIPTION"
    print(f"{r['file']:<35} | Size: {r['size']:<8} | Duration: {r['duration']}s | RMS: {r['rms']:<8} | Peak: {r['peak']:<8} | {status}")
print("="*80)
