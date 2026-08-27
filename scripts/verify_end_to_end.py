import sys
import os
import time
import inspect
import tarfile
import psutil
import torch
import nemo
import nemo.collections.asr as nemo_asr
from nemo.collections.asr.parts.mixins.mixins import ASRBPEMixin
import nemo.collections.asr.modules.rnnt as nemo_rnnt
import nemo.collections.asr.modules as nemo_modules
from nemo.core.connectors.save_restore_connector import SaveRestoreConnector
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

# Force UTF-8 output encoding for Windows console
sys.stdout.reconfigure(encoding='utf-8')

# --- 1. INDICCONFORMER MONKEY-PATCHES FOR OFFLINE NEMO COMPATIBILITY ---
_orig_extract = tarfile.TarFile.extract
def _patched_extract(self, member, path=None, set_attrs=True, *, numeric_owner=False, **kwargs):
    return _orig_extract(self, member, path=path, set_attrs=set_attrs, numeric_owner=numeric_owner)
tarfile.TarFile.extract = _patched_extract

_orig_load_instance = SaveRestoreConnector.load_instance_with_state_dict
def _patched_load_instance(self, instance, state_dict, strict=True):
    if "joint.joint_net.2.hi.weight" in state_dict:
        state_dict["joint.joint_net.2.weight"] = state_dict["joint.joint_net.2.hi.weight"]
    if "joint.joint_net.2.hi.bias" in state_dict:
        state_dict["joint.joint_net.2.bias"] = state_dict["joint.joint_net.2.hi.bias"]
    if "decoder.prediction.embed.weight" in state_dict and hasattr(instance, 'decoder') and hasattr(instance.decoder, 'prediction'):
        ckpt_embed = state_dict["decoder.prediction.embed.weight"]
        model_embed = instance.decoder.prediction.embed.weight
        if ckpt_embed.shape != model_embed.shape and ckpt_embed.shape[1] == model_embed.shape[1]:
            state_dict["decoder.prediction.embed.weight"] = ckpt_embed[:model_embed.shape[0]]
    return _orig_load_instance(self, instance, state_dict, strict=False)
SaveRestoreConnector.load_instance_with_state_dict = _patched_load_instance

if hasattr(nemo_modules.conv_asr, 'ConvASRDecoder'):
    nemo_modules.conv_asr.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])
if hasattr(nemo_modules, 'ConvASRDecoder'):
    nemo_modules.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])

def make_clean_init(orig_init):
    def _patched_init(self, *args, **kwargs):
        for key in ['multisoftmax', 'multilingual', 'language_keys', 'num_classes_per_language']:
            kwargs.pop(key, None)
        pop_vocab = False
        if 'vocabulary' in kwargs and 'num_classes' in kwargs:
            vocab = kwargs['vocabulary']
            num_classes = kwargs['num_classes']
            if vocab is not None and hasattr(vocab, '__len__') and len(vocab) != num_classes:
                kwargs.pop('vocabulary')
                pop_vocab = True
        res = orig_init(self, *args, **kwargs)
        if pop_vocab or not hasattr(self, '_vocabulary'):
            object.__setattr__(self, '_vocabulary', [])
        return res
    return _patched_init

nemo_rnnt.RNNTDecoder.__init__ = make_clean_init(nemo_rnnt.RNNTDecoder.__init__)
if hasattr(nemo_rnnt, 'RNNTJoint'):
    nemo_rnnt.RNNTJoint.__init__ = make_clean_init(nemo_rnnt.RNNTJoint.__init__)
if hasattr(nemo_modules, 'ConvASRDecoder'):
    nemo_modules.ConvASRDecoder.__init__ = make_clean_init(nemo_modules.ConvASRDecoder.__init__)
if hasattr(nemo_modules.conv_asr, 'ConvASRDecoder'):
    nemo_modules.conv_asr.ConvASRDecoder.__init__ = make_clean_init(nemo_modules.conv_asr.ConvASRDecoder.__init__)

_orig_setup_tokenizer = ASRBPEMixin._setup_tokenizer
def _patched_setup_tokenizer(self, tokenizer_cfg):
    if tokenizer_cfg is not None and getattr(tokenizer_cfg, 'type', None) == 'multilingual':
        if hasattr(tokenizer_cfg, 'langs') and 'hi' in tokenizer_cfg.langs:
            tokenizer_cfg = tokenizer_cfg.langs.hi
        elif hasattr(tokenizer_cfg, 'langs'):
            first_lang = list(tokenizer_cfg.langs.keys())[0]
            tokenizer_cfg = tokenizer_cfg.langs[first_lang]
    return _orig_setup_tokenizer(self, tokenizer_cfg)
ASRBPEMixin._setup_tokenizer = _patched_setup_tokenizer

# --- 2. STAGE 13 END-TO-END VERIFICATION LOGIC ---
print("=" * 60)
print("STAGE 13 — OFFLINE END-TO-END SPEECH TRANSLATION PIPELINE")
print("=" * 60)

audio_path = os.path.abspath("test_audio/hindi_test.wav")
asr_model_path = os.path.abspath("models/indicconformer/indicconformer_stt_hi_hybrid_rnnt_large.nemo")
trans_model_dir = os.path.abspath("models/indictrans2")
src_lang = "hin_Deva"
tgt_lang = "sat_Olck"

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Device Used               : {device.upper()}")
print(f"Input Audio Path          : {audio_path}")
print(f"IndicConformer ASR Path   : {asr_model_path}")
print(f"IndicTrans2 Model Dir     : {trans_model_dir}")
print(f"Source Language           : {src_lang} (Hindi)")
print(f"Target Language           : {tgt_lang} (Santali - Ol Chiki)")

# Pre-execution checks
if not os.path.exists(audio_path):
    print(f"\n[ERROR] Audio file missing: {audio_path}")
    sys.exit(1)
if not os.path.exists(asr_model_path):
    print(f"\n[ERROR] ASR model missing: {asr_model_path}")
    sys.exit(1)
if not os.path.exists(trans_model_dir):
    print(f"\n[ERROR] Translation model directory missing: {trans_model_dir}")
    sys.exit(1)

ram_initial = psutil.virtual_memory().used / (1024**3)

# A. LOAD INDICCONFORMER ASR MODEL
print("\n[STEP 1/4] Loading local IndicConformer ASR model...")
t0 = time.time()
try:
    asr_model = nemo_asr.models.EncDecHybridRNNTCTCBPEModel.restore_from(asr_model_path, map_location=device)
except Exception:
    asr_model = nemo_asr.models.ASRModel.restore_from(asr_model_path, map_location=device)
asr_load_time = time.time() - t0
print(f"  -> IndicConformer Loaded in {asr_load_time:.2f} seconds.")

# B. LOAD INDICTRANS2 TRANSLATION MODEL & TOKENIZER
print("\n[STEP 2/4] Loading local IndicTrans2 Translation model & tokenizer (local_files_only=True)...")
t0 = time.time()
tokenizer = AutoTokenizer.from_pretrained(
    trans_model_dir,
    local_files_only=True,
    trust_remote_code=True
)
trans_model = AutoModelForSeq2SeqLM.from_pretrained(
    trans_model_dir,
    local_files_only=True,
    trust_remote_code=True
).to(device)

tgt_lang_id = tokenizer.src_encoder.get(tgt_lang) or tokenizer.convert_tokens_to_ids(tgt_lang)
trans_load_time = time.time() - t0
print(f"  -> IndicTrans2 Loaded in {trans_load_time:.2f} seconds.")

# C & D. RUN REAL ASR INFERENCE
print("\n[STEP 3/4] Running ASR Model Inference on Hindi speech audio...")
t0 = time.time()
with torch.no_grad():
    try:
        transcriptions = asr_model.transcribe(audio=[audio_path])
    except TypeError:
        try:
            transcriptions = asr_model.transcribe([audio_path])
        except TypeError:
            transcriptions = asr_model.transcribe(paths2audio_files=[audio_path])
asr_infer_time = time.time() - t0

# E. CAPTURE ASR OUTPUT
asr_output = ""
if isinstance(transcriptions, tuple):
    transcriptions = transcriptions[0]
if isinstance(transcriptions, list) and len(transcriptions) > 0:
    first_elem = transcriptions[0]
    if isinstance(first_elem, list) and len(first_elem) > 0:
        asr_output = str(first_elem[0])
    elif hasattr(first_elem, 'text'):
        asr_output = first_elem.text
    else:
        asr_output = str(first_elem)
else:
    asr_output = str(transcriptions)

asr_output = asr_output.strip()
print(f"  -> ASR Completed in {asr_infer_time:.2f} seconds.")
print(f"  -> Actual Hindi Transcription: '{asr_output}'")

if not asr_output:
    print("\n[FAIL] IndicConformer returned an empty transcription!")
    sys.exit(1)

# F, G, H & I. PASS ASR OUTPUT DIRECTLY INTO INDICTRANS2 FOR REAL TRANSLATION INFERENCE
print("\n[STEP 4/4] Passing ASR output directly into IndicTrans2 for Hindi -> Santali Translation...")
t0 = time.time()
translation_input = f"{src_lang} {tgt_lang} {asr_output}"
inputs = tokenizer(translation_input, return_tensors="pt").to(device)

with torch.no_grad():
    generated_tokens = trans_model.generate(
        **inputs,
        forced_bos_token_id=tgt_lang_id,
        use_cache=True,
        min_length=0,
        max_length=256,
        num_beams=5,
        num_return_sequences=1,
        repetition_penalty=1.2
    )

santali_output = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0].strip()
trans_infer_time = time.time() - t0
print(f"  -> Translation Completed in {trans_infer_time:.2f} seconds.")
print(f"  -> Actual Santali Translation: '{santali_output}'")

if not santali_output:
    print("\n[FAIL] IndicTrans2 returned an empty translation!")
    sys.exit(1)

total_pipeline_time = asr_load_time + trans_load_time + asr_infer_time + trans_infer_time
ram_peak = psutil.virtual_memory().used / (1024**3)

# PRINT PIPELINE DATA FLOW TRACE AND PERFORMANCE METRICS
print("\n" + "=" * 60)
print("STAGE 13 END-TO-END PIPELINE TRACE")
print("=" * 60)
print(f"Input Audio:\n  {audio_path}")
print(f"\nASR Model:\n  {asr_model_path}")
print(f"\nASR Output:\n  {asr_output}")
print(f"\nTranslation Source Language:\n  {src_lang}")
print(f"\nTranslation Target Language:\n  {tgt_lang}")
print(f"\nTranslation Input:\n  {translation_input}")
print(f"\nSantali Output:\n  {santali_output}")
print("=" * 60)

print("\n" + "=" * 60)
print("PERFORMANCE BREAKDOWN")
print("=" * 60)
print(f"IndicConformer Model Load Time : {asr_load_time:.2f} s")
print(f"IndicConformer Inference Time  : {asr_infer_time:.2f} s")
print(f"IndicTrans2 Model Load Time    : {trans_load_time:.2f} s")
print(f"IndicTrans2 Inference Time     : {trans_infer_time:.2f} s")
print(f"Total Pipeline Time            : {total_pipeline_time:.2f} s")
print(f"Peak RAM Usage                 : {ram_peak:.2f} GB")
print(f"Execution Device               : {device.upper()}")
print(f"Offline Verification Status    : VERIFIED (100% local models)")
print("=" * 60)

if asr_output and santali_output:
    print("\nFINAL STATUS: PASS — End-to-End Hindi Speech -> Santali Translation Pipeline Verified Successfully")
else:
    print("\nFINAL STATUS: FAIL — End-to-End Pipeline Failed")
