import os
import sys
import time
import soundfile as sf
import torch
import numpy as np
from transformers import AutoTokenizer, AutoModelForCausalLM
from snac import SNAC

sys.stdout.reconfigure(encoding='utf-8')

quipus_model_dir = "/mnt/f/SIH/SIH_Translator/models/quipus"
output_dir = "/mnt/f/SIH/SIH_Translator/test_audio/tts_outputs"
os.makedirs(output_dir, exist_ok=True)

santali_text = sys.argv[1] if len(sys.argv) > 1 else "ᱠᱟᱹᱢᱤ ᱢᱮ ᱟᱨ ᱯᱷᱚᱞᱮ ᱤᱫᱤ ᱠᱟᱛᱮ ᱵᱟᱝ ᱩᱭᱦᱟᱹᱨ ᱢᱮ ᱾"
speaker = "Sido"

print(f"Loading Quipus TTS ({speaker} voice)...")
tokenizer = AutoTokenizer.from_pretrained(quipus_model_dir, local_files_only=True)
model = AutoModelForCausalLM.from_pretrained(
    quipus_model_dir,
    local_files_only=True,
    low_cpu_mem_usage=True,
    dtype=torch.float16
).to("cpu").eval()

snac_decoder = SNAC.from_pretrained("hubertsiuzdak/snac_24khz").eval().to("cpu")

prompt = f"{speaker}: {santali_text} <audio_start> "
inputs = tokenizer(prompt, return_tensors="pt").to("cpu")

print("Synthesizing Santali speech audio with sampling...")
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


gen_tokens = outputs[0][inputs.input_ids.shape[1]:]

# Parse SNAC tokens
FRAME_PATTERN = [0, 1, 2, 2, 1, 2, 2]
snac_tokens = []
for tok_id in gen_tokens.tolist():
    tok_str = tokenizer.decode([tok_id]).strip()
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

    # Peak normalization: scale audio to 95% full dynamic range for loud, crisp sound
    max_val = np.max(np.abs(audio_np))
    if max_val > 0:
        audio_np = (audio_np / max_val) * 0.95

    audio_int16 = (audio_np * 32767).astype(np.int16)
    output_wav = os.path.join(output_dir, "live_karma_sido_loud.wav")
    sf.write(output_wav, audio_int16, 24000, subtype='PCM_16')
    print(f"\n[SUCCESS] Normalized loud voice audio saved at: {output_wav}")
    print(f"  Peak Amplitude : {np.max(np.abs(audio_np)):.4f} (Loud & Crisp)")
    print(f"  Duration       : {len(audio_np)/24000:.2f} seconds")

else:
    print("FAILED to parse SNAC audio tokens")
