import os
import sys
import time
import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

# Force UTF-8 output encoding
sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("STAGE 11 — OFFLINE INDICTRANS2 HINDI -> SANTALI TEST")
print("=" * 60)

model_dir = os.path.abspath("models/indictrans2")
src_lang = "hin_Deva"
tgt_lang = "sat_Olck"
input_sentence = "नमस्ते, आप कैसे हैं?"
formatted_input = f"{src_lang} {tgt_lang} {input_sentence}"

print(f"Local Model Directory : {model_dir}")
print(f"Source Language       : {src_lang} (Hindi)")
print(f"Target Language       : {tgt_lang} (Santali - Ol Chiki)")
print(f"Input Sentence        : {input_sentence}")
print(f"Formatted Input       : {formatted_input}")

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device Used           : {device}")

# 1 & 2. Load tokenizer and model from local directory with local_files_only=True and trust_remote_code=True
print("\nLoading tokenizer and model from local files...")
start_load = time.time()

tokenizer = AutoTokenizer.from_pretrained(
    model_dir,
    local_files_only=True,
    trust_remote_code=True
)

model = AutoModelForSeq2SeqLM.from_pretrained(
    model_dir,
    local_files_only=True,
    trust_remote_code=True
).to(device)

load_time = time.time() - start_load
print(f"Local Model Loaded Successfully in {load_time:.2f} seconds.")

# Get forced_bos_token_id for target language
tgt_lang_id = tokenizer.tgt_encoder.get(tgt_lang)
print(f"Forced BOS Token ID ({tgt_lang}): {tgt_lang_id}")

# 3. Perform REAL model inference
print("\nRunning Model Inference...")
start_infer = time.time()

# Tokenize input
inputs = tokenizer(formatted_input, return_tensors="pt").to(device)

# Generate translation tokens
with torch.no_grad():
    generated_tokens = model.generate(
        **inputs,
        forced_bos_token_id=tgt_lang_id,
        use_cache=True,
        min_length=0,
        max_length=256,
        num_beams=5,
        num_return_sequences=1,
        repetition_penalty=1.2
    )

# Decode generated tokens
translation = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
infer_time = time.time() - start_infer

print("\n" + "=" * 60)
print("VERIFICATION RESULTS")
print("=" * 60)
print(f"Model Path           : {model_dir}")
print(f"Source Language      : {src_lang}")
print(f"Target Language      : {tgt_lang}")
print(f"Input Sentence       : {input_sentence}")
print(f"Generated Translation: '{translation}'")
print(f"Device               : {device}")
print(f"Model Loading Time   : {load_time:.2f} s")
print(f"Inference Time       : {infer_time:.2f} s")
print(f"Local Loading Status : VERIFIED (local_files_only=True)")
print("=" * 60)

if translation and len(translation.strip()) > 0:
    print("\nFINAL STATUS: PASS")
else:
    print("\nFINAL STATUS: FAIL (Empty translation output)")
