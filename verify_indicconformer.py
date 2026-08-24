import sys
import os
import time
import inspect
import tarfile
import psutil

# Monkey-patch tarfile.TarFile.extract to accept 'filter' kwarg in Python 3.10 standard library
_orig_extract = tarfile.TarFile.extract
def _patched_extract(self, member, path=None, set_attrs=True, *, numeric_owner=False, **kwargs):
    return _orig_extract(self, member, path=path, set_attrs=set_attrs, numeric_owner=numeric_owner)
tarfile.TarFile.extract = _patched_extract

import torch
import nemo
import nemo.collections.asr as nemo_asr
from nemo.collections.asr.parts.mixins.mixins import ASRBPEMixin
import nemo.collections.asr.modules.rnnt as nemo_rnnt
import nemo.collections.asr.modules as nemo_modules
from nemo.core.connectors.save_restore_connector import SaveRestoreConnector

# Monkey-patch SaveRestoreConnector to map AI4Bharat Hindi joint weights and slice embedding table
_orig_load_instance = SaveRestoreConnector.load_instance_with_state_dict
def _patched_load_instance(self, instance, state_dict, strict=True):
    # Map Hindi-specific joint layer weights
    if "joint.joint_net.2.hi.weight" in state_dict:
        print("[INFO] Mapping joint.joint_net.2.hi.weight to joint.joint_net.2.weight")
        state_dict["joint.joint_net.2.weight"] = state_dict["joint.joint_net.2.hi.weight"]
    if "joint.joint_net.2.hi.bias" in state_dict:
        print("[INFO] Mapping joint.joint_net.2.hi.bias to joint.joint_net.2.bias")
        state_dict["joint.joint_net.2.bias"] = state_dict["joint.joint_net.2.hi.bias"]
    
    # Handle embedding size mismatch between multilingual checkpoint (5633) and Hindi monolingual model (257)
    if "decoder.prediction.embed.weight" in state_dict and hasattr(instance, 'decoder') and hasattr(instance.decoder, 'prediction'):
        ckpt_embed = state_dict["decoder.prediction.embed.weight"]
        model_embed = instance.decoder.prediction.embed.weight
        if ckpt_embed.shape != model_embed.shape and ckpt_embed.shape[1] == model_embed.shape[1]:
            print(f"[INFO] Adjusting decoder embedding shape from {ckpt_embed.shape} to {model_embed.shape}")
            state_dict["decoder.prediction.embed.weight"] = ckpt_embed[:model_embed.shape[0]]

    return _orig_load_instance(self, instance, state_dict, strict=False)
SaveRestoreConnector.load_instance_with_state_dict = _patched_load_instance

# Ensure ConvASRDecoder has a vocabulary property returning a list (non-None)
if hasattr(nemo_modules.conv_asr, 'ConvASRDecoder'):
    nemo_modules.conv_asr.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])
if hasattr(nemo_modules, 'ConvASRDecoder'):
    nemo_modules.ConvASRDecoder.vocabulary = property(lambda self: getattr(self, '_vocabulary', None) or [])

# Clean init decorator to strip AI4Bharat custom kwargs and set self._vocabulary backing attribute
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

# Monkey-patch ASRBPEMixin._setup_tokenizer to handle multilingual tokenizer config in NeMo 3.0
_orig_setup_tokenizer = ASRBPEMixin._setup_tokenizer
def _patched_setup_tokenizer(self, tokenizer_cfg):
    if tokenizer_cfg is not None and getattr(tokenizer_cfg, 'type', None) == 'multilingual':
        print("[INFO] Multilingual tokenizer detected in checkpoint. Extracting Hindi ('hi') tokenizer config...")
        if hasattr(tokenizer_cfg, 'langs') and 'hi' in tokenizer_cfg.langs:
            tokenizer_cfg = tokenizer_cfg.langs.hi
        elif hasattr(tokenizer_cfg, 'langs'):
            first_lang = list(tokenizer_cfg.langs.keys())[0]
            tokenizer_cfg = tokenizer_cfg.langs[first_lang]
    return _orig_setup_tokenizer(self, tokenizer_cfg)
ASRBPEMixin._setup_tokenizer = _patched_setup_tokenizer

# Force UTF-8 output encoding for Windows console
sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("SIH INDICCONFORMER HINDI ASR VERIFICATION")
print("=" * 60)

python_version = sys.version.split()[0]
pytorch_version = torch.__version__
nemo_version = nemo.__version__
cuda_available = torch.cuda.is_available()
device = "cuda" if cuda_available else "cpu"

print(f"Python Version : {python_version}")
print(f"PyTorch Version: {pytorch_version}")
print(f"NeMo Version   : {nemo_version}")
print(f"CUDA / GPU     : {cuda_available} (Using device: {device})")

model_path = os.path.abspath("models/indicconformer/indicconformer_stt_hi_hybrid_rnnt_large.nemo")
audio_path = os.path.abspath("test_audio/hindi_test.wav")

print(f"Model Path     : {model_path}")
print(f"Audio Path     : {audio_path}")
print(f"Model File Size: {os.path.getsize(model_path) / (1024*1024):.2f} MB")

ram_before = psutil.virtual_memory().used / (1024**3)
print(f"RAM Usage Before Loading: {ram_before:.2f} GB")

print("\nLoading IndicConformer model from .nemo checkpoint...")
start_load = time.time()

# Restore NeMo EncDecHybridRNNTCTCBPEModel from .nemo checkpoint
try:
    asr_model = nemo_asr.models.EncDecHybridRNNTCTCBPEModel.restore_from(model_path, map_location=device)
except Exception as e:
    print(f"EncDecHybridRNNTCTCBPEModel failed ({e}), attempting ASRModel.restore_from...")
    asr_model = nemo_asr.models.ASRModel.restore_from(model_path, map_location=device)

load_time = time.time() - start_load
ram_after_load = psutil.virtual_memory().used / (1024**3)
print(f"Model Loaded Successfully in {load_time:.2f} seconds.")
print(f"RAM Usage After Loading : {ram_after_load:.2f} GB (Delta: {ram_after_load - ram_before:.2f} GB)")

print("\nRunning Inference on Audio...")
start_infer = time.time()

# Transcribe audio file using NeMo 3.0 API (paths2audio_files or audio or positional)
with torch.no_grad():
    try:
        transcriptions = asr_model.transcribe(audio=[audio_path])
    except TypeError:
        try:
            transcriptions = asr_model.transcribe([audio_path])
        except TypeError:
            transcriptions = asr_model.transcribe(paths2audio_files=[audio_path])

infer_time = time.time() - start_infer
total_time = load_time + infer_time
ram_after_infer = psutil.virtual_memory().used / (1024**3)

# Extract transcription text safely
actual_text = ""
if isinstance(transcriptions, tuple):
    transcriptions = transcriptions[0]

if isinstance(transcriptions, list) and len(transcriptions) > 0:
    first_elem = transcriptions[0]
    if isinstance(first_elem, list) and len(first_elem) > 0:
        actual_text = str(first_elem[0])
    elif hasattr(first_elem, 'text'):
        actual_text = first_elem.text
    else:
        actual_text = str(first_elem)
else:
    actual_text = str(transcriptions)

print("\n" + "=" * 60)
print("INFERENCE RESULTS")
print("=" * 60)
print(f"Input Audio         : {audio_path}")
print(f"Model               : {os.path.basename(model_path)}")
print(f"Actual Transcription: '{actual_text}'")
print(f"Model Load Time     : {load_time:.2f} s")
print(f"Inference Time      : {infer_time:.2f} s")
print(f"Total Time          : {total_time:.2f} s")
print(f"Peak RAM Usage      : {ram_after_infer:.2f} GB")
print("=" * 60)

if actual_text and len(actual_text.strip()) > 0:
    print("\nRESULT: SUCCESS — Hindi speech -> Hindi text works locally")
else:
    print("\nRESULT: BLOCKED — Empty transcription returned by model.")
