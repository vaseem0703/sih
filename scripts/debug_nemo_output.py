import os
import sys
import torch

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

import local_ai_server

print("Loading IndicConformer...")
local_ai_server.load_asr_model()
m = local_ai_server.asr_model

wav_path = os.path.join(PROJECT_ROOT, "scripts", "test_audio", "test_phrase1.wav")
print(f"Running transcribe on {wav_path}...")
with torch.inference_mode():
    try:
        out = m.transcribe(audio=[wav_path], batch_size=1, num_workers=0)
    except Exception as e:
        out = m.transcribe([wav_path])

print("RAW OUT TYPE:", type(out))
print("RAW OUT REPR:", repr(out))
if isinstance(out, (list, tuple)) and len(out) > 0:
    elem = out[0]
    print("ELEM TYPE:", type(elem))
    print("ELEM REPR:", repr(elem))
    print("ELEM DIR:", [d for d in dir(elem) if not d.startswith('_')])
