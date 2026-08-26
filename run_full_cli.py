import os
import sys
import time
import torch
import soundfile as sf
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, AutoModelForCausalLM
from snac import SNAC

sys.stdout.reconfigure(encoding='utf-8')

print("=" * 70)
print("  SIH PROBLEM STATEMENT 26042 — FULL TEXT & VOICE SANTALI TRANSLATOR")
print("=" * 70)

if len(sys.argv) > 1:
    input_text = " ".join(sys.argv[1:])
else:
    input_text = "कर्म करो, फल की चिंता मत करो।"

print(f"\n[1/4] Input Hindi Text: {input_text}")

# 1. IndicTrans2 Translation
model_dir = "/mnt/f/SIH/SIH_Translator/models/indictrans2"
formatted_input = f"hin_Deva sat_Olck {input_text}"

print("[2/4] Translating Hindi -> Santali (IndicTrans2)...")
tokenizer_trans = AutoTokenizer.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True)
model_trans = AutoModelForSeq2SeqLM.from_pretrained(model_dir, local_files_only=True, trust_remote_code=True).to("cpu")

tgt_lang_id = tokenizer_trans.tgt_encoder.get("sat_Olck")
inputs_trans = tokenizer_trans(formatted_input, return_tensors="pt").to("cpu")

with torch.no_grad():
    gen_tokens = model_trans.generate(
        **inputs_trans,
        forced_bos_token_id=tgt_lang_id,
        use_cache=False,
        min_length=0,
        max_length=256,
        num_beams=5
    )

santali_text = tokenizer_trans.batch_decode(gen_tokens, skip_special_tokens=True)[0]
print(f"  -> Santali Translation: {santali_text}")

# 2. Quipus TTS Synthesis
quipus_dir = "/mnt/f/SIH/SIH_Translator/models/quipus"
output_dir = "/mnt/f/SIH/SIH_Translator/test_audio/tts_outputs"
os.makedirs(output_dir, exist_ok=True)

print("[3/4] Loading Quipus TTS Model & SNAC Vocoder...")
tokenizer_tts = AutoTokenizer.from_pretrained(quipus_dir, local_files_only=True)
model_tts = AutoModelForCausalLM.from_pretrained(
    quipus_dir,
    local_files_only=True,
    low_cpu_mem_usage=True,
    dtype=torch.float16
).to("cpu").eval()

snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")

prompt = f"Phulmani: {santali_text} <audio_start> "
inputs_tts = tokenizer_tts(prompt, return_tensors="pt").to("cpu")

print("[4/4] Synthesizing Santali Voice Audio...")
with torch.no_grad():
    outputs_tts = model_tts.generate(
        **inputs_tts,
        max_new_tokens=512,
        do_sample=False,
        pad_token_id=tokenizer_tts.pad_token_id or tokenizer_tts.eos_token_id
    )

gen_tts_tokens = outputs_tts[0][inputs_tts.input_ids.shape[1]:]

# Parse SNAC tokens
snac_tokens = []
for tok_id in gen_tts_tokens.tolist():
    tok_str = tokenizer_tts.decode([tok_id]).strip()
    if tok_str == "<audio_end>":
        break
    if tok_str.startswith("<snac_l") and "_c" in tok_str:
        try:
            parts = tok_str.replace("<snac_", "").replace(">", "").split("_c")
            code = int(parts[1])
            snac_tokens.append(code)
        except Exception:
            pass

num_frames = len(snac_tokens) // 7
if num_frames > 0:
    l0, l1, l2 = [], [], []
    for f in range(num_frames):
        idx = f * 7
        l0.append(snac_tokens[idx])
        l1.extend([snac_tokens[idx+1], snac_tokens[idx+4]])
        l2.extend([snac_tokens[idx+2], snac_tokens[idx+3], snac_tokens[idx+5], snac_tokens[idx+6]])

    z_l0 = torch.tensor(l0, dtype=torch.long).unsqueeze(0).to("cpu")
    z_l1 = torch.tensor(l1, dtype=torch.long).unsqueeze(0).to("cpu")
    z_l2 = torch.tensor(l2, dtype=torch.long).unsqueeze(0).to("cpu")

    with torch.no_grad():
        audio_hat = snac_decoder.decode([z_l0, z_l1, z_l2])

    audio_np = audio_hat.squeeze().cpu().numpy()
    out_file = os.path.join(output_dir, "santali_output.wav")
    sf.write(out_file, audio_np, 24000)

    print("\n" + "=" * 70)
    print("  RESULT & AUDIO FILE LOCATION")
    print("=" * 70)
    print(f"  Hindi Input     : {input_text}")
    print(f"  Santali Output  : {santali_text}")
    print(f"  Audio File Path : F:\\SIH\\SIH_Translator\\test_audio\\tts_outputs\\santali_output.wav")
    print("=" * 70 + "\n")
