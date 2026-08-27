import os
import sys
import torch

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

import local_ai_server

print("Loading IndicConformer model...")
local_ai_server.load_asr_model()
m = local_ai_server.asr_model

print("Model Class:", type(m))
print("Available Methods:", [d for d in dir(m) if 'transcribe' in d or 'decod' in d])

def robust_transcribe(audio_path):
    print(f"\n--- Transcribing {audio_path} ---")
    with torch.inference_mode():
        try:
            res = m.transcribe([audio_path])
        except Exception as e:
            res = m.transcribe(audio=[audio_path], batch_size=1, num_workers=0)
        
        print("Raw result:", repr(res))
        
        extracted = ""
        if isinstance(res, tuple):
            res = res[0]
        if isinstance(res, list) and len(res) > 0:
            item = res[0]
            if hasattr(item, 'text'):
                extracted = item.text
            elif isinstance(item, str):
                extracted = item
            else:
                extracted = str(item)
        elif isinstance(res, str):
            extracted = res

        print(f"Extracted Text: '{extracted}'")
        return extracted

wav1_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase1.wav")
robust_transcribe(wav1_path)
