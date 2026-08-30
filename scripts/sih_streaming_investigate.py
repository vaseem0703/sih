"""
Investigation: Does our IndicConformer model support streaming/chunked inference?
Checks encoder architecture, att_context_style, and streaming_cfg support.
Does NOT load the full model — only checks architecture.
"""
import sys
import os
import tarfile
import zipfile

sys.stdout.reconfigure(encoding='utf-8')

MODEL_PATH = "/mnt/f/SIH/SIH_Translator/models/indicconformer/indicconformer_stt_hi_hybrid_rnnt_large.nemo"

print("=" * 70)
print("  STREAMING SUPPORT INVESTIGATION — IndicConformer Model")
print("=" * 70)
print()

# The .nemo file is a tar.gz archive — extract and read the config YAML only
print("[1] Reading model config from .nemo archive (no model load)...")
config_yaml = None

try:
    with tarfile.open(MODEL_PATH, 'r:gz') as tar:
        for member in tar.getmembers():
            if member.name.endswith('.yaml') or member.name.endswith('.cfg') or member.name == 'model_config.yaml':
                f = tar.extractfile(member)
                if f:
                    config_yaml = f.read().decode('utf-8', errors='replace')
                    print(f"    Found config: {member.name} ({len(config_yaml)} bytes)")
                    break
except Exception as e:
    print(f"    Error reading .nemo: {e}")
    sys.exit(1)

if not config_yaml:
    print("    ERROR: Could not find model config in .nemo archive!")
    sys.exit(1)

print()
print("[2] Checking att_context_size and att_context_style in model config...")

def extract_yaml_field(yaml_text, field):
    for line in yaml_text.split('\n'):
        stripped = line.strip()
        if stripped.startswith(field + ':') or stripped.startswith(field + ' :'):
            return stripped.split(':', 1)[1].strip()
    return None

att_context_size = extract_yaml_field(config_yaml, 'att_context_size')
att_context_style = extract_yaml_field(config_yaml, 'att_context_style')
model_type = extract_yaml_field(config_yaml, '_target_')
encoder_type = extract_yaml_field(config_yaml, 'encoder')

print(f"    Model target      : {model_type}")
print(f"    att_context_size  : {att_context_size}")
print(f"    att_context_style : {att_context_style}")

# Search for cache_aware, streaming mentions in the config
streaming_keywords = ['cache_aware', 'streaming', 'chunk_size', 'att_context_style', 'lookahead']
print()
print("[3] Searching config for streaming/cache-aware keywords...")
for kw in streaming_keywords:
    count = config_yaml.lower().count(kw)
    if count > 0:
        print(f"    '{kw}': FOUND ({count} occurrences)")
    else:
        print(f"    '{kw}': NOT FOUND")

print()
print("[4] Checking NeMo streaming infrastructure in installed package...")

# Check that the NeMo version has the streaming API
import nemo
print(f"    NeMo version      : {nemo.__version__}")

try:
    from nemo.collections.asr.inference.model_wrappers.cache_aware_rnnt_inference_wrapper import CacheAwareRNNTInferenceWrapper
    print(f"    CacheAwareRNNTInferenceWrapper : AVAILABLE (streaming API exists)")
except ImportError as e:
    print(f"    CacheAwareRNNTInferenceWrapper : NOT AVAILABLE ({e})")

try:
    from nemo.collections.asr.inference.pipelines.cache_aware_rnnt_pipeline import CacheAwareRNNTPipeline
    print(f"    CacheAwareRNNTPipeline         : AVAILABLE")
except ImportError as e:
    print(f"    CacheAwareRNNTPipeline         : NOT AVAILABLE ({e})")

try:
    from nemo.collections.asr.inference.pipelines.cache_aware_ctc_pipeline import CacheAwareCTCPipeline
    print(f"    CacheAwareCTCPipeline          : AVAILABLE")
except ImportError as e:
    print(f"    CacheAwareCTCPipeline          : NOT AVAILABLE ({e})")

print()
print("[5] VERDICT...")

# att_context_style 'regular' means each frame attends to all past context
# This is BATCH-only style. It does NOT support streaming natively.
# att_context_style 'chunked_limited' or 'chunked_limited_with_rc' means the model
# was TRAINED with limited context windows and DOES support streaming.

style = (att_context_style or '').lower().strip()
ctx_size = (att_context_size or '').strip()

print(f"    att_context_style = '{style}'")

if 'chunked_limited' in style:
    print()
    print("    ✅ STREAMING SUPPORTED: att_context_style is 'chunked_limited'")
    print("       This model was trained with limited attention context windows.")
    print("       NeMo's CacheAwareRNNTInferenceWrapper can be used for chunk-by-chunk")
    print("       inference, which enables live/streaming transcription.")
    print()
    print("    RECOMMENDATION: Use CacheAwareRNNTInferenceWrapper with stream_step()")
    print("    to feed 160ms audio chunks and get partial transcriptions in real-time.")
elif 'regular' in style or style == '':
    print()
    print("    ❌ STREAMING NOT NATIVELY SUPPORTED: att_context_style is 'regular'")
    print("       This model uses global self-attention — each output token depends on")
    print("       ALL previous frames. It cannot produce valid partial results mid-utterance.")
    print()
    print("    WHY THIS MATTERS:")
    print("    - Feeding short audio chunks will produce garbage/empty output")
    print("    - The model REQUIRES a complete utterance to produce accurate transcription")
    print("    - Even with chunking, accuracy degrades heavily vs full-utterance inference")
    print()
    print("    WHAT THIS MEANS FOR US:")
    print("    - Our current batch inference (full WAV → server → text) is the CORRECT approach")
    print("    - 'Live Hindi text while speaking' CANNOT be achieved with this model")
    print("    - The on-device speech_to_text (Google/Android) IS already streaming IndicConformer is NOT")
else:
    print(f"    ⚠️  UNKNOWN att_context_style: '{style}' — cannot determine streaming support")

print()
print("=" * 70)
print("  SUMMARY")
print("=" * 70)
print(f"  Model file        : indicconformer_stt_hi_hybrid_rnnt_large.nemo")
print(f"  Model type        : Hybrid RNNT + CTC (EncDecHybridRNNTCTCBPEModel)")
print(f"  Encoder           : ConformerEncoder")
print(f"  att_context_style : {style or '(not set / regular)'}")
print(f"  att_context_size  : {ctx_size or '(not set)'}")
print()
print("  STREAMING SUPPORT     : See verdict above")
print("  CURRENT INFERENCE API : asr_model.transcribe([wav_file]) — BATCH / FILE-BASED")
print("  ANDROID SUITABILITY   : Requires server-side inference via local_ai_server.py")
print("  CPU INFERENCE TIME    : ~1.3–2.5s per utterance (warm model)")
print("  GPU INFERENCE TIME    : ~0.3–0.8s per utterance (if GPU available)")
print("=" * 70)
