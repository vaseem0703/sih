import os
import sys
import re
import soundfile as sf
import torch
import numpy as np
from transformers import AutoTokenizer, AutoModelForCausalLM
from snac import SNAC

quipus_dir = "/mnt/f/SIH/SIH_Translator/models/quipus"
output_dir = "/mnt/f/SIH/SIH_Translator/sih_flutter_app/assets/audio"
os.makedirs(output_dir, exist_ok=True)

print("Loading Quipus TTS Model & SNAC Vocoder...")
tokenizer = AutoTokenizer.from_pretrained(quipus_dir, local_files_only=True, use_fast=False)
model = AutoModelForCausalLM.from_pretrained(
    quipus_dir,
    local_files_only=True,
    low_cpu_mem_usage=True,
    torch_dtype=torch.float32
).to("cpu").eval()

snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")
FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]

phrases = {
    "johar.wav": ("Phulmani", "ᱡᱚᱦᱟᱨ"),
    "potob_jhij.wav": ("Sido", "ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ ᱾"),
    "teheng_el.wav": ("Phulmani", "ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱮᱞ ᱵᱚᱱ ᱪᱮᱫᱟ ᱾"),
    "dag_nui.wav": ("Sido", "ᱫᱟᱜ ᱧᱩᱭ ᱢᱮ ᱾"),
    "adi_bhagi.wav": ("Phulmani", "ᱟᱹᱰᱤ ᱵᱷᱟᱹᱜᱤ, ᱥᱟᱵᱟᱥ!"),
    "amag_nutum.wav": ("Phulmani", "ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ?"),
    "nawa_jinis.wav": ("Sido", "ᱱᱟᱣᱟ ᱠᱚ, ᱱᱚᱣᱟ ᱡᱤᱱᱤᱥ ᱠᱚ ᱮᱞ ᱢᱮ᱾"),
    "gidra_potob.wav": ("Sido", "ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱟᱯᱱᱟᱨᱟᱜ ᱯᱚᱛᱚᱵ ᱡᱷᱤᱡᱽ ᱢᱮ ᱾"),
}

for fname, (speaker, text) in phrases.items():
    print(f"Synthesizing {fname} for '{text}'...")
    prompt = f"{speaker}: {text} <audio_start> "
    inputs = tokenizer(prompt, return_tensors="pt").to("cpu")
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_new_tokens=512,
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
    if l0:
        with torch.inference_mode():
            wav = snac_decoder.decode([
                torch.tensor([l0], dtype=torch.long, device="cpu"),
                torch.tensor([l1], dtype=torch.long, device="cpu"),
                torch.tensor([l2], dtype=torch.long, device="cpu")
            ])
        pcm = wav.detach().squeeze().float().cpu().numpy()
        pcm = np.clip(pcm, -1.0, 1.0)
        peak = np.max(np.abs(pcm))
        if peak > 0:
            pcm = (pcm / peak) * 0.95
        dest_file = os.path.join(output_dir, fname)
        sf.write(dest_file, pcm, 24000)
        print(f"-> [SUCCESS] Generated {dest_file} ({len(pcm)/24000:.2f}s)")
    else:
        print(f"-> [WARN] No frames for {fname}")

print("ALL CLASSROOM AUDIO GENERATION COMPLETE!")
