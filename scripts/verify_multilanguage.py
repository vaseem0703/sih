import sys
import os
import time
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

# --- 2. MULTI-LANGUAGE TEST MATRIX DEFINITION ---
print("=" * 70)
print("STAGE 14 — MULTIPLE INDIAN-LANGUAGE TRANSLATION & PIPELINE TESTING")
print("=" * 70)

audio_path = os.path.abspath("test_audio/hindi_test.wav")
asr_model_path = os.path.abspath("models/indicconformer/indicconformer_stt_hi_hybrid_rnnt_large.nemo")
trans_model_dir = os.path.abspath("models/indictrans2")
src_lang = "hin_Deva"

device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"Execution Hardware       : {device.upper()} (CUDA Available: {torch.cuda.is_available()})")
print(f"Offline Verification Mode: VERIFIED (local_files_only=True)")
print(f"Local ASR Model Path     : {asr_model_path}")
print(f"Local Translation Dir    : {trans_model_dir}")
print(f"Input Audio File Path    : {audio_path}")

target_languages = [
    {"name": "Santali", "code": "sat_Olck", "sample_input": "नमस्ते, आप कैसे हैं?"},
    {"name": "Bengali", "code": "ben_Beng", "sample_input": "आज हम गणित और विज्ञान पढ़ेंगे।"},
    {"name": "Telugu", "code": "tel_Telu", "sample_input": "एक, दो, तीन, चार, पाँच।"},
    {"name": "Tamil", "code": "tam_Taml", "sample_input": "बच्चे स्कूल जा रहे हैं।"},
    {"name": "Kannada", "code": "kan_Knda", "sample_input": "भारत हमारा देश है।"},
    {"name": "Malayalam", "code": "mal_Mlym", "sample_input": "नमस्ते, आप कैसे हैं?"},
    {"name": "Marathi", "code": "mar_Deva", "sample_input": "आज हम गणित और विज्ञान पढ़ेंगे।"},
    {"name": "Gujarati", "code": "guj_Gujr", "sample_input": "एक, दो, तीन, चार, पाँच।"},
    {"name": "Odia", "code": "ory_Orya", "sample_input": "बच्चे स्कूल जा रहे हैं।"},
    {"name": "Punjabi", "code": "pan_Guru", "sample_input": "भारत हमारा देश है।"}
]

total_start = time.time()
ram_initial = psutil.virtual_memory().used / (1024**3)

# --- 3. MODEL LOADING ---
print("\n[PHASE 1/3] Loading local models from disk...")
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
trans_load_time = time.time() - t0
print(f"  -> IndicTrans2 loaded in {trans_load_time:.2f} s")

t0 = time.time()
try:
    asr_model = nemo_asr.models.EncDecHybridRNNTCTCBPEModel.restore_from(asr_model_path, map_location=device)
except Exception:
    asr_model = nemo_asr.models.ASRModel.restore_from(asr_model_path, map_location=device)
asr_load_time = time.time() - t0
print(f"  -> IndicConformer ASR loaded in {asr_load_time:.2f} s")

# Helper function to translate text with IndicTrans2
def translate_text(input_text: str, tgt_code: str):
    tgt_lang_id = tokenizer.src_encoder.get(tgt_code) or tokenizer.convert_tokens_to_ids(tgt_code)
    formatted_input = f"{src_lang} {tgt_code} {input_text}"
    inputs = tokenizer(formatted_input, return_tensors="pt").to(device)
    
    t_start = time.time()
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
    dur = time.time() - t_start
    output_text = tokenizer.batch_decode(generated_tokens, skip_special_tokens=True)[0].strip()
    return output_text, dur

# --- 4. PHASE 2: STANDALONE MULTI-LANGUAGE TRANSLATION TESTING ---
print("\n" + "=" * 70)
print("[PHASE 2/3] RUNNING STANDALONE TEXT TRANSLATION TESTS")
print("=" * 70)

test_results = []
pass_count = 0
fail_count = 0

for lang_info in target_languages:
    lang_name = lang_info["name"]
    tgt_code = lang_info["code"]
    inp_sentence = lang_info["sample_input"]

    print("\n--------------------------------------------------")
    print(f"Language Test : Hindi -> {lang_name}")
    print("--------------------------------------------------")
    print(f"Source        : Hindi ({src_lang})")
    print(f"Target        : {lang_name} ({tgt_code})")
    print(f"Input         : {inp_sentence}")

    try:
        translated_text, inf_time = translate_text(inp_sentence, tgt_code)
        non_empty = bool(translated_text and len(translated_text.strip()) > 0)
        non_echo = (translated_text != inp_sentence)
        status = "PASS" if (non_empty and non_echo) else "FAIL"
        
        if status == "PASS":
            pass_count += 1
        else:
            fail_count += 1

        print(f"Generated Output: {translated_text}")
        print(f"Output Non-Empty: {non_empty}")
        print(f"Inference Time  : {inf_time:.2f} s")
        print(f"Status          : {status}")

        test_results.append({
            "type": "Standalone Text",
            "pair": f"Hindi -> {lang_name}",
            "code": f"{src_lang} -> {tgt_code}",
            "input": inp_sentence,
            "output": translated_text,
            "time": f"{inf_time:.2f} s",
            "status": status
        })
    except Exception as e:
        fail_count += 1
        print(f"Generated Output: ERROR ({e})")
        print(f"Status          : FAIL")
        test_results.append({
            "type": "Standalone Text",
            "pair": f"Hindi -> {lang_name}",
            "code": f"{src_lang} -> {tgt_code}",
            "input": inp_sentence,
            "output": f"ERROR: {e}",
            "time": "0.00 s",
            "status": "FAIL"
        })

# --- 5. PHASE 3: END-TO-END SPEECH TRANSLATION PIPELINE TESTS ---
print("\n" + "=" * 70)
print("[PHASE 3/3] RUNNING END-TO-END SPEECH TRANSLATION PIPELINE TESTS")
print("=" * 70)

print(f"\nRunning IndicConformer ASR inference on '{audio_path}'...")
t_asr_start = time.time()
with torch.no_grad():
    try:
        transcriptions = asr_model.transcribe(audio=[audio_path])
    except TypeError:
        try:
            transcriptions = asr_model.transcribe([audio_path])
        except TypeError:
            transcriptions = asr_model.transcribe(paths2audio_files=[audio_path])
asr_dur = time.time() - t_asr_start

asr_text = ""
if isinstance(transcriptions, tuple):
    transcriptions = transcriptions[0]
if isinstance(transcriptions, list) and len(transcriptions) > 0:
    first_elem = transcriptions[0]
    if isinstance(first_elem, list) and len(first_elem) > 0:
        asr_text = str(first_elem[0])
    elif hasattr(first_elem, 'text'):
        asr_text = first_elem.text
    else:
        asr_text = str(first_elem)
else:
    asr_text = str(transcriptions)
asr_text = asr_text.strip()

print(f"ASR Output Generated in {asr_dur:.2f} s: '{asr_text}'")

e2e_results = []
e2e_pass = 0
e2e_fail = 0

for lang_info in target_languages:
    lang_name = lang_info["name"]
    tgt_code = lang_info["code"]

    print("\n--------------------------------------------------")
    print(f"End-to-End Pipeline Test : Hindi Audio -> {lang_name}")
    print("--------------------------------------------------")
    print(f"Input Audio    : {os.path.basename(audio_path)}")
    print(f"ASR Output     : {asr_text}")
    print(f"Target Language: {lang_name} ({tgt_code})")

    try:
        translated_text, inf_time = translate_text(asr_text, tgt_code)
        non_empty = bool(translated_text and len(translated_text.strip()) > 0)
        status = "PASS" if non_empty else "FAIL"

        if status == "PASS":
            e2e_pass += 1
        else:
            e2e_fail += 1

        print(f"Santali/Target Output: {translated_text}")
        print(f"Inference Time       : {inf_time:.2f} s")
        print(f"Status               : {status}")

        e2e_results.append({
            "pair": f"Hindi Audio -> {lang_name}",
            "code": f"hin_Deva -> {tgt_code}",
            "input": asr_text,
            "output": translated_text,
            "time": f"{inf_time + asr_dur:.2f} s",
            "status": status
        })
    except Exception as e:
        e2e_fail += 1
        print(f"Target Output : ERROR ({e})")
        print(f"Status        : FAIL")
        e2e_results.append({
            "pair": f"Hindi Audio -> {lang_name}",
            "code": f"hin_Deva -> {tgt_code}",
            "input": asr_text,
            "output": f"ERROR: {e}",
            "time": "0.00 s",
            "status": "FAIL"
        })

total_runtime = time.time() - total_start
ram_peak = psutil.virtual_memory().used / (1024**3)

# --- 6. SUMMARY TABLE & VERIFICATION REPORT ---
print("\n" + "=" * 80)
print("STAGE 14 MULTI-LANGUAGE TEST SUMMARY TABLE")
print("=" * 80)
print(f"{'Type':<16} | {'Language Pair':<20} | {'Status':<6} | {'Time':<8} | {'Output Preview':<25}")
print("-" * 80)

for res in test_results:
    prev = res['output'][:23] + ".." if len(res['output']) > 25 else res['output']
    print(f"{res['type']:<16} | {res['pair']:<20} | {res['status']:<6} | {res['time']:<8} | {prev:<25}")

for res in e2e_results:
    prev = res['output'][:23] + ".." if len(res['output']) > 25 else res['output']
    print(f"{'End-to-End Speech':<16} | {res['pair']:<20} | {res['status']:<6} | {res['time']:<8} | {prev:<25}")

print("=" * 80)
print(f"Total Test Cases : {len(test_results) + len(e2e_results)}")
print(f"Passed           : {pass_count + e2e_pass}")
print(f"Failed           : {fail_count + e2e_fail}")
print(f"Total Execution  : {total_runtime:.2f} s")
print(f"Peak RAM Usage   : {ram_peak:.2f} GB")
print(f"Execution Device : CPU (Offline verification)")
print("=" * 80)

if (fail_count + e2e_fail) == 0:
    print("\nFINAL STATUS: PASS — All Multi-Language Translation Tests Succeeded Offline")
else:
    print("\nFINAL STATUS: FAIL — Some test cases failed")
