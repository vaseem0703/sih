import os
import sys
from huggingface_hub import snapshot_download

# Force UTF-8 output encoding for Windows console
sys.stdout.reconfigure(encoding='utf-8')

repo_id = "ai4bharat/indictrans2-indic-indic-dist-320M"
target_dir = os.path.abspath("models/indictrans2")

print(f"Downloading model '{repo_id}' to '{target_dir}'...")
print("Ignoring duplicate format 'pytorch_model.bin'...")

# Download repository files into target_dir while explicitly excluding pytorch_model.bin
downloaded_path = snapshot_download(
    repo_id=repo_id,
    local_dir=target_dir,
    local_dir_use_symlinks=False,
    ignore_patterns=["pytorch_model.bin", "*.bin", ".git*"]
)

print(f"Download complete: {downloaded_path}")

# Verification step
required_files = [
    "model.safetensors",
    "config.json",
    "configuration_indictrans.py",
    "modeling_indictrans.py",
    "tokenization_indictrans.py",
    "tokenizer_config.json",
    "special_tokens_map.json",
    "generation_config.json",
    "dict.SRC.json",
    "dict.TGT.json",
    "model.SRC",
    "model.TGT"
]

print("\n" + "="*60)
print("VERIFICATION OF DOWNLOADED FILES")
print("="*60)

missing_files = []
total_bytes = 0

for file in os.listdir(target_dir):
    full_p = os.path.join(target_dir, file)
    if os.path.isfile(full_p):
        size_mb = os.path.getsize(full_p) / (1024 * 1024)
        total_bytes += os.path.getsize(full_p)
        print(f"  [FOUND] {file:<30} ({size_mb:.2f} MB)")

bin_path = os.path.join(target_dir, "pytorch_model.bin")
bin_exists = os.path.exists(bin_path)

for req in required_files:
    if not os.path.exists(os.path.join(target_dir, req)):
        missing_files.append(req)

print("="*60)
print(f"Target Directory Exists : {os.path.exists(target_dir)}")
print(f"model.safetensors Exists: {os.path.exists(os.path.join(target_dir, 'model.safetensors'))}")
print(f"pytorch_model.bin Exists: {bin_exists} (Expected: False)")
print(f"Missing Required Files  : {missing_files if missing_files else 'None'}")
print(f"Total Downloaded Size   : {total_bytes / (1024 * 1024):.2f} MB ({total_bytes / (1024**3):.2f} GB)")
print("="*60)

if not bin_exists and not missing_files and os.path.exists(os.path.join(target_dir, "model.safetensors")):
    print("\nDOWNLOAD SUCCESSFUL — All required IndicTrans2 files downloaded without pytorch_model.bin")
else:
    print("\nDOWNLOAD VERIFICATION FAILED")
