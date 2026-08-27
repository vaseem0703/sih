import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("models/indictrans2/dict.TGT.json", "r", encoding="utf-8") as f:
    tgt_vocab = json.load(f)

print(f"Total TGT vocab size: {len(tgt_vocab)}")

sat_tokens = [k for k in tgt_vocab.keys() if any('\u1C50' <= char <= '\u1C7F' for char in k)]
print(f"Total Ol Chiki Unicode tokens in dict.TGT.json: {len(sat_tokens)}")
print("Sample Ol Chiki tokens:", sat_tokens[:30])

tag_tokens = [k for k in tgt_vocab.keys() if "sat" in k or "Olck" in k]
print("Santali tag tokens in dict.TGT.json:", tag_tokens)
