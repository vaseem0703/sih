import os
import sys
import time
import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

sys.stdout.reconfigure(encoding='utf-8')

print("=" * 70)
print("  SIH PROBLEM STATEMENT 26042 — OFFLINE HINDI -> SANTALI TRANSLATOR CLI")
print("=" * 70)

model_dir = "/mnt/f/SIH/SIH_Translator/models/indictrans2"
src_lang = "hin_Deva"
tgt_lang = "sat_Olck"

if len(sys.argv) > 1:
    input_text = " ".join(sys.argv[1:])
else:
    input_text = input("\nEnter Hindi sentence to translate: ").strip()

if not input_text:
    input_text = "कर्म करो, फल की चिंता मत करो।"

formatted_input = f"{src_lang} {tgt_lang} {input_text}"

print(f"\n[1/2] Input Hindi Text : {input_text}")
print("[2/2] Loading IndicTrans2 local offline model...")

t0 = time.time()
tokenizer = AutoTokenizer.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True).to("cpu")
load_time = time.time() - t0

tgt_lang_id = tokenizer.tgt_encoder.get(tgt_lang)
inputs = tokenizer(formatted_input, return_tensors="pt").to("cpu")

start_infer = time.time()
with torch.no_grad():
    generated_tokens = model.generate(
        **inputs,
        forced_bos_token_id=tgt_lang_id,
        use_cache=False,
        min_length=0,
        max_length=256,
        num_beams=5,
        num_return_sequences=1,
        repetition_penalty=1.2
    )

translation = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
infer_time = time.time() - start_infer

print("\n" + "=" * 70)
print("  TRANSLATION RESULT")
print("=" * 70)
print(f"  Hindi Input     : {input_text}")
print(f"  Santali Output  : {translation}")
print(f"  Model Load Time : {load_time:.2f} s")
print(f"  Inference Time  : {infer_time:.2f} s")
print(f"  Offline Status  : VERIFIED OFFLINE (local_files_only=True)")
print("=" * 70 + "\n")
