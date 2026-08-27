import os
import sys
import time
from huggingface_hub import snapshot_download

sys.stdout.reconfigure(encoding='utf-8')

repo_id = "Anonym-050326/nirukti-translate-1.3b"
target_dir = os.path.abspath("models/nirukti-translate-1.3b")

print("=" * 70)
print(f"  DOWNLOADING '{repo_id}' TO '{target_dir}'")
print("=" * 70)

t0 = time.time()
try:
    downloaded_path = snapshot_download(
        repo_id=repo_id,
        local_dir=target_dir,
        local_dir_use_symlinks=False,
        ignore_patterns=["*.bin", ".git*", "testing_scripts/*"]
    )
    elapsed = time.time() - t0
    print(f"\nDownload complete in {elapsed:.2f} seconds!")
    print(f"Target location: {downloaded_path}")

    total_bytes = 0
    print("\n" + "=" * 60)
    print("VERIFICATION OF DOWNLOADED MODEL FILES:")
    print("=" * 60)
    for root, dirs, files in os.walk(target_dir):
        for file in files:
            full_p = os.path.join(root, file)
            size = os.path.getsize(full_p)
            total_bytes += size
            size_mb = size / (1024 * 1024)
            size_gb = size / (1024 * 1024 * 1024)
            if size_gb >= 1.0:
                print(f"  [FOUND] {file:<35} ({size_gb:.2f} GB)")
            else:
                print(f"  [FOUND] {file:<35} ({size_mb:.2f} MB)")

    total_gb = total_bytes / (1024 * 1024 * 1024)
    print("=" * 60)
    print(f"TOTAL NIRUKTI MODEL DISK USAGE: {total_gb:.2f} GB ({total_bytes} bytes)")
    print("=" * 60)

except Exception as e:
    print(f"DOWNLOAD ERROR: {e}")
    sys.exit(1)
