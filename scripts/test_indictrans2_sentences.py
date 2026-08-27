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

test_sentences = [
    "आज हम गणित सीखेंगे",
    "बच्चों, अपनी किताब खोलो",
    "सब लोग ध्यान से सुनो",
    "पानी पियो और काम करो",
    "यह बहुत अच्छा है, शाबाश!",
    "तुम्हारी किताब कहाँ है?",
    "हम स्कूल जा रहे हैं"
]

print("\n" + "=" * 70)
print("  EVALUATING INDICTRANS2 SANTALI OL CHIKI TRANSLATIONS")
print("=" * 70)

for hindi_text in test_sentences:
    formatted_input = f"hin_Deva sat_Olck {hindi_text}"
    inputs = tokenizer(formatted_input, return_tensors="pt").to("cpu")
    t0 = time.time()
    with torch.no_grad():
        gen_tokens = model.generate(**inputs, num_beams=5, max_length=256, use_cache=False)
    out_santali = tokenizer.batch_decode(gen_tokens, skip_special_tokens=True)[0].strip()
    latency = time.time() - t0

    has_ol_chiki = any('\u1C50' <= char <= '\u1C7F' for char in out_santali)
    script_label = "REAL SANTALI OL CHIKI" if has_ol_chiki else "DEVANAGARI / OTHER SCRIPT"

    print("==================================================")
    print(f"HINDI INPUT  : '{hindi_text}'")
    print(f"SANTALI OUT  : '{out_santali}'")
    print(f"SCRIPT TYPE  : {script_label}")
    print(f"LATENCY      : {latency:.2f}s")
    print("==================================================")
