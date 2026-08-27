import sys
import json
from huggingface_hub import HfApi

sys.stdout.reconfigure(encoding='utf-8')

repo_id = "Anonym-050326/nirukti-translate-1.3b"
print(f"Inspecting HuggingFace repo '{repo_id}'...")

api = HfApi()
try:
    info = api.model_info(repo_id=repo_id, files_metadata=True)
    print("=" * 60)
    print(f"MODEL REPO: {info.id}")
    print(f"SHA       : {info.sha}")
    print(f"PIPELINE  : {info.pipeline_tag}")
    print(f"TAGS      : {info.tags}")
    print("=" * 60)
    print("REPO FILES & SIZES:")
    total_bytes = 0
    for file in info.siblings:
        size_str = ""
        if hasattr(file, 'size') and file.size:
            size_mb = file.size / (1024 * 1024)
            size_gb = file.size / (1024 * 1024 * 1024)
            total_bytes += file.size
            if size_gb >= 1.0:
                size_str = f"{size_gb:.2f} GB"
            else:
                size_str = f"{size_mb:.2f} MB"
        print(f"  - {file.rfilename:<35} {size_str}")
    
    total_gb = total_bytes / (1024 * 1024 * 1024)
    print("=" * 60)
    print(f"TOTAL REPO WEIGHTS SIZE: {total_gb:.2f} GB ({total_bytes} bytes)")
    print("=" * 60)

except Exception as e:
    print(f"Error accessing HuggingFace API for '{repo_id}': {e}")
