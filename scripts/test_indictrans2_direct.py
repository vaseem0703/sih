import os
import sys
import torch
import time

sys.stdout.reconfigure(encoding='utf-8')
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDICTRANS2_DIR = os.path.join(BASE_DIR, "models", "indictrans2")

print("=" * 60)
print("  INDICTRANS2 MODEL VERIFICATION TEST (hin_Deva -> sat_Olck)")
print("=" * 60)

print(f"Loading IndicTrans2 model from '{INDICTRANS2_DIR}'...")
start_t = time.time()
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

tokenizer = AutoTokenizer.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True).to("cpu").eval()
load_time = time.time() - start_t
print(f"IndicTrans2 loaded successfully in {load_time:.2f} seconds!")

test_inputs = [
    "आज हम गणित सीखेंगे",
    "बच्चों अपनी किताब खोलो",
    "पानी पियो"
]

print("\n" + "=" * 60)
print("DIRECT MODEL TRANSLATION VERIFICATION")
print("=" * 60)

for hindi_in in test_inputs:
    t0 = time.time()
    formatted_input = f"hin_Deva sat_Olck {hindi_in}"
    inputs = tokenizer(formatted_input, return_tensors="pt").to("cpu")
    with torch.no_grad():
        gen_tokens = model.generate(**inputs, num_beams=4, max_length=256, use_cache=False)
    out_santali = tokenizer.batch_decode(gen_tokens, skip_special_tokens=True)[0].strip()
    latency = time.time() - t0

    print("==================================================")
    print("[TRANSLATION DEBUG]")
    print(f"MODEL: ai4bharat/indictrans2-indic-indic-dist-320M")
    print("SOURCE: hin_Deva")
    print("TARGET: sat_Olck")
    print(f"INPUT: '{hindi_in}'")
    print(f"OUTPUT: '{out_santali}'")
    print(f"LATENCY: {latency:.2f}s")
    print("==================================================")
