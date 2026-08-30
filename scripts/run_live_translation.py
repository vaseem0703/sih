import os
import sys
import time
import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

sys.stdout.reconfigure(encoding='utf-8')

model_dir = "/mnt/f/SIH/SIH_Translator/models/indictrans2"
src_lang = "hin_Deva"
tgt_lang = "sat_Olck"
input_text = "कर्म करो, फल की चिंता मत करो।"
formatted_input = f"{src_lang} {tgt_lang} {input_text}"

print("=" * 60)
print("LIVE OFFLINE TRANSLATION (STAGE 11 - INDICTRANS2)")
print("=" * 60)
print(f"Input Hindi Text: {input_text}")
print("Loading model...")

tokenizer = AutoTokenizer.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True).to("cpu")

tgt_lang_id = tokenizer.tgt_encoder.get(tgt_lang)
inputs = tokenizer(formatted_input, return_tensors="pt").to("cpu")

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

print("\n" + "=" * 60)
print("TRANSLATION RESULT")
print("=" * 60)
print(f"Hindi Text   : {input_text}")
print(f"Santali Text : {translation}")
print("=" * 60)

with open("/mnt/f/SIH/SIH_Translator/live_translation_result.txt", "w", encoding="utf-8") as f:
    f.write(translation)
