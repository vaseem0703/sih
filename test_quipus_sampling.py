import os
import sys
import time
import re
import soundfile as sf
import torch
import numpy as np
from transformers import AutoTokenizer, AutoModelForCausalLM
from snac import SNAC

sys.stdout.reconfigure(encoding='utf-8')

quipus_dir = "/mnt/f/SIH/SIH_Translator/models/quipus"
output_dir = "/mnt/f/SIH/SIH_Translator/test_audio/tts_outputs"
os.makedirs(output_dir, exist_ok=True)

santali_text = "ᱠᱟᱹᱢᱤ ᱢᱮ ᱟᱨ ᱯᱷᱚᱞᱮ ᱤᱫᱤ ᱠᱟᱛᱮ ᱵᱟᱝ ᱩᱭᱦᱟᱹᱨ ᱢᱮ ᱾"
speaker = "Phulmani"

print("Loading Quipus TTS Model & SNAC Vocoder...")
tokenizer = AutoTokenizer.from_pretrained(quipus_dir, local_files_only=True)
model = AutoModelForCausalLM.from_pretrained(
    quipus_dir,
    local_files_only=True,
    low_cpu_mem_usage=True,
    dtype=torch.float32
).to("cpu").eval()

snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")

prompt = f"{speaker}: {santali_text} <audio_start> "
inputs = tokenizer(prompt, return_tensors="pt").to("cpu")

print("Synthesizing Santali speech with official sampling parameters (temp=0.7, top_p=0.9)...")
torch.manual_seed(42)

with torch.no_grad():
    outputs = model.generate(
        **inputs,
        max_new_tokens=1024,
        do_sample=True,
        temperature=0.7,
        top_p=0.9,
        repetition_penalty=1.1,
        pad_token_id=tokenizer.pad_token_id or tokenizer.eos_token_id
    )

out_ids = outputs[0][inputs.input_ids.shape[1]:].tolist()
toks = tokenizer.convert_ids_to_tokens(out_ids)

parsed = []
for token in toks:
    match = re.fullmatch(r"<snac_l(\d+)_c(\d+)>", token)
    if match:
        parsed.append((int(match.group(1)), int(match.group(2))))

FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]
l0, l1, l2 = [], [], []
i = 0

while i + 7 <= len(parsed):
    window = parsed[i:i + 7]
    if [layer for layer, _ in window] == FRAME_LAYER_PATTERN:
        codes = [code for _, code in window]
        l0.append(codes[0])
        l1.extend([codes[1], codes[4]])
        l2.extend([codes[2], codes[3], codes[5], codes[6]])
        i += 7
    else:
        i += 1

if not l0:
    print("No valid SNAC frames generated.")
    sys.exit(1)

with torch.inference_mode():
    wav = snac_decoder.decode([
        torch.tensor([l0], dtype=torch.long, device="cpu"),
        torch.tensor([l1], dtype=torch.long, device="cpu"),
        torch.tensor([l2], dtype=torch.long, device="cpu")
    ])

pcm = wav.detach().squeeze().float().cpu().numpy()
pcm = np.clip(pcm, -1.0, 1.0)

# Peak normalization
peak = np.max(np.abs(pcm))
if peak > 0:
    pcm = (pcm / peak) * 0.90

out_wav = os.path.join(output_dir, "santali_real_voice.wav")
sf.write(out_wav, pcm, 24000)

print(f"\n[SUCCESS] Generated Real Santali Speech Audio at: {out_wav}")
print(f"  Parsed Frames   : {len(l0)}")
print(f"  Audio Duration  : {len(pcm)/24000:.2f} s")
print(f"  Peak Amplitude  : {np.max(np.abs(pcm)):.4f}")
