import os
import sys
from huggingface_hub import snapshot_download

# Force UTF-8 output encoding
sys.stdout.reconfigure(encoding='utf-8')

repo_id = "hyperneuronAILabs/quipus-0.6-speechv2"
target_dir = os.path.abspath("models/quipus")
hf_token = os.environ.get("HF_TOKEN") or os.environ.get("HUGGING_FACE_HUB_TOKEN")

print(f"Downloading Quipus model '{repo_id}' into '{target_dir}'...")

try:
    downloaded_path = snapshot_download(
        repo_id=repo_id,
        local_dir=target_dir,
        token=hf_token if hf_token else True,
        ignore_patterns=[".git*"]
    )
    print(f"Download complete: {downloaded_path}")

    # List downloaded files and calculate total size
    total_bytes = 0
    print("\n" + "=" * 60)
    print("DOWNLOADED FILES VERIFICATION")
    print("=" * 60)
    for root, dirs, files in os.walk(target_dir):
        for f in files:
            fp = os.path.join(root, f)
            rel_p = os.path.relpath(fp, target_dir)
            size_mb = os.path.getsize(fp) / (1024 * 1024)
            total_bytes += os.path.getsize(fp)
            print(f"  [FILE] {rel_p:<40} ({size_mb:.2f} MB)")
    print("=" * 60)
    print(f"Total Downloaded Size: {total_bytes / (1024*1024):.2f} MB ({total_bytes / (1024**3):.2f} GB)")
    print("=" * 60)

except Exception as e:
    print(f"\n[AUTHENTICATION / DOWNLOAD BLOCKER] {e}")
    sys.exit(1)
