import os
import sys
import torch
import time

sys.stdout.reconfigure(encoding='utf-8')
repo_id = "Anonym-050326/nirukti-translate-1.3b"
print(f"Loading '{repo_id}' using AutoTokenizer & AutoModelForSeq2SeqLM...")

from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

start_t = time.time()
tokenizer = AutoTokenizer.from_pretrained(repo_id)
model = AutoModelForSeq2SeqLM.from_pretrained(repo_id).to("cpu").eval()
load_time = time.time() - start_t

print(f"Nirukti model loaded in {load_time:.2f} seconds!")

if hasattr(tokenizer, 'lang_code_to_id'):
    print("lang_code_to_id:", list(tokenizer.lang_code_to_id.keys())[:30])
elif hasattr(tokenizer, 'additional_special_tokens'):
    print("additional_special_tokens:", tokenizer.additional_special_tokens[:30])

sat_tokens = [t for t in (tokenizer.additional_special_tokens or []) if "sat" in t or "olck" in t.lower()]
hin_tokens = [t for t in (tokenizer.additional_special_tokens or []) if "hin" in t or "deva" in t.lower()]

print("Found Hindi tokens:", hin_tokens)
print("Found Santali tokens:", sat_tokens)

test_sentences = [
    "आज हम गणित सीखेंगे",
    "किताब खोलो",
    "सब लोग किताब खोलो"
]

src_code = hin_tokens[0] if hin_tokens else "hin_Deva"
tgt_code = sat_tokens[0] if sat_tokens else "sat_Olck"

print(f"\nTesting Translation: {src_code} -> {tgt_code}")
tokenizer.src_lang = src_code

for sentence in test_sentences:
    t0 = time.time()
    encoded = tokenizer(sentence, return_tensors="pt")
    forced_id = tokenizer.convert_tokens_to_ids(tgt_code) if tgt_code in tokenizer.additional_special_tokens else None
    
    with torch.no_grad():
        if forced_id is not None:
            generated_tokens = model.generate(**encoded, forced_bos_token_id=forced_id, max_length=128, use_cache=False)
        else:
            generated_tokens = model.generate(**encoded, max_length=128, use_cache=False)
            
    result = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0]
    latency = time.time() - t0

    has_ol_chiki = any('\u1C50' <= char <= '\u1C7F' for char in result)
    script_label = "REAL SANTALI OL CHIKI" if has_ol_chiki else "DEVANAGARI / OTHER SCRIPT"

    print("==================================================")
    print(f"INPUT HINDI : '{sentence}'")
    print(f"OUTPUT      : '{result}'")
    print(f"SCRIPT TYPE : {script_label}")
    print(f"LATENCY     : {latency:.2f}s")
    print("==================================================")
