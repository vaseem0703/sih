import os
import sys
import torch
import time

sys.stdout.reconfigure(encoding='utf-8')
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDICTRANS2_DIR = os.path.join(BASE_DIR, "models", "indictrans2")

print("Loading IndicTrans2 tokenizer and model...")
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

tokenizer = AutoTokenizer.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(INDICTRANS2_DIR, local_files_only=True, trust_remote_code=True).to("cpu").eval()

print("Tokenizer src_vocab size:", tokenizer.src_vocab_size)
print("Tokenizer tgt_vocab size:", tokenizer.tgt_vocab_size)

# Check target language token ID for sat_Olck
tgt_lang_token = "sat_Olck"
tgt_lang_id = tokenizer.tgt_encoder.get(tgt_lang_token, None)
print(f"Target language token '{tgt_lang_token}' ID in tgt_encoder: {tgt_lang_id}")

src_lang_id = tokenizer.src_encoder.get("sat_Olck", None)
print(f"Target language token 'sat_Olck' ID in src_encoder: {src_lang_id}")

test_inputs = [
    "किताब खोलो",
    "सब लोग किताब खोलो",
    "आज हम गणित सीखेंगे"
]

print("\n" + "=" * 60)
print("TESTING FORCED TARGET LANGUAGE GENERATION")
print("=" * 60)

for text in test_inputs:
    formatted_input = f"hin_Deva sat_Olck {text}"
    inputs = tokenizer(formatted_input, return_tensors="pt").to("cpu")
    
    # Try 1: Without forced_bos_token_id
    with torch.no_grad():
        gen1 = model.generate(**inputs, num_beams=4, max_length=256, use_cache=False)
    out1 = tokenizer.batch_decode(gen1, skip_special_tokens=True)[0].strip()
    
    # Try 2: With forced_bos_token_id if target lang token ID exists
    forced_id = tgt_lang_id if tgt_lang_id is not None else src_lang_id
    with torch.no_grad():
        if forced_id is not None:
            gen2 = model.generate(**inputs, num_beams=4, max_length=256, forced_bos_token_id=forced_id, use_cache=False)
            out2 = tokenizer.batch_decode(gen2, skip_special_tokens=True)[0].strip()
        else:
            out2 = "N/A"
            
    print(f"INPUT       : '{text}'")
    print(f"OUT (no force): '{out1}'")
    print(f"OUT (forced)  : '{out2}'")
    print("-" * 50)
