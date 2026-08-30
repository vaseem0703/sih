import os
import sys
import time
import torch
import tarfile

sys.stdout.reconfigure(encoding='utf-8')

_orig_extract = tarfile.TarFile.extract
def _patched_extract(self, member, path=None, set_attrs=True, *, numeric_owner=False, **kwargs):
    return _orig_extract(self, member, path=path, set_attrs=set_attrs, numeric_owner=numeric_owner)
tarfile.TarFile.extract = _patched_extract

import nemo.collections.asr as nemo_asr
from nemo.collections.asr.parts.mixins.mixins import ASRBPEMixin
from nemo.core.connectors.save_restore_connector import SaveRestoreConnector

_orig_setup_tokenizer = ASRBPEMixin._setup_tokenizer
def _patched_setup_tokenizer(self, tokenizer_cfg):
    if "langs" in tokenizer_cfg and "hi" in tokenizer_cfg["langs"]:
        tokenizer_cfg = tokenizer_cfg["langs"]["hi"]
    return _orig_setup_tokenizer(self, tokenizer_cfg)
ASRBPEMixin._setup_tokenizer = _patched_setup_tokenizer

_orig_load_instance = SaveRestoreConnector.load_instance_with_state_dict
def _patched_load_instance(self, instance, state_dict, strict=True):
    if "joint.joint_net.2.hi.weight" in state_dict:
        state_dict["joint.joint_net.2.weight"] = state_dict["joint.joint_net.2.hi.weight"]
    if "joint.joint_net.2.hi.bias" in state_dict:
        state_dict["joint.joint_net.2.bias"] = state_dict["joint.joint_net.2.hi.bias"]
    if "decoder.prediction.embed.weight" in state_dict and hasattr(instance, 'decoder') and hasattr(instance.decoder, 'prediction'):
        ckpt_embed = state_dict["decoder.prediction.embed.weight"]
        model_embed = instance.decoder.prediction.embed.weight
        if ckpt_embed.shape[0] > model_embed.shape[0]:
            state_dict["decoder.prediction.embed.weight"] = ckpt_embed[:model_embed.shape[0], :]
    return _orig_load_instance(self, instance, state_dict, strict=False)
SaveRestoreConnector.load_instance_with_state_dict = _patched_load_instance

MODEL_PATH = "models/indicconformer/indicconformer_stt_hi_hybrid_rnnt_large.nemo"
AUDIO_PATH = "test_audio/hindi_test.wav"

torch.set_num_threads(8)
print("Loading Hybrid Model...")
model = nemo_asr.models.EncDecHybridRNNTCTCBPEModel.restore_from(MODEL_PATH, map_location="cpu")

# Test RNNT
t0 = time.time()
res_rnnt = model.transcribe(audio=[AUDIO_PATH])
t_rnnt = time.time() - t0
print(f"RNNT Result ({t_rnnt:.2f}s):", res_rnnt)

# Test CTC mode
try:
    model.change_decoding_strategy(decoder_type="ctc")
    t0 = time.time()
    res_ctc = model.transcribe(audio=[AUDIO_PATH])
    t_ctc = time.time() - t0
    print(f"CTC Result ({t_ctc:.2f}s):", res_ctc)
except Exception as e:
    print("CTC error:", e)
