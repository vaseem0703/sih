---
license: cc-by-nc-4.0
language:
  - ahr
  - asm
  - awa
  - ben
  - bfy
  - bgc
  - bgq
  - bhb
  - bho
  - bns
  - bra
  - brj
  - brx
  - dcc
  - doi
  - en
  - gbm
  - gon
  - grt
  - guj
  - hin
  - hne
  - hoc
  - kan
  - kas
  - kfa
  - kfr
  - kfy
  - kha
  - kho
  - kok
  - kru
  - lus
  - mag
  - mai
  - mal
  - mar
  - mni
  - mtr
  - mwr
  - npi
  - ory
  - pan
  - phr
  - raj
  - san
  - sat
  - snd
  - spv
  - srb
  - tam
  - tcy
  - tel
  - urd
  - wbr
  - xnr
tags:
  - translation
  - indic-languages
  - low-resource
  - multilingual
  - seq2seq
  - transformers
pipeline_tag: translation
---

# Indic Translation Model — 55 Indian Languages

A fine-tuned translation model supporting **55 Indian languages** including 33 low-resource languages. Translates bidirectionally between English and any supported Indic language.

## Key Features

- **55 Indian languages** — covers both major and low-resource regional languages
- **Bidirectional** — English to Indic and Indic to English
- **1.3B parameter** encoder-decoder model, ready to use out of the box
- **Fast inference** — supports CTranslate2 int8 quantization for production deployments
- **Extended vocabulary** — 256,243 tokens with 33 newly added language codes

## Supported Languages

| Language | Code | Script | Language | Code | Script |
|----------|------|--------|----------|------|--------|
| Ahirani | ahr_Deva | Devanagari | Kumaoni | kfy_Deva | Devanagari |
| Assamese | asm_Beng | Bengali | Kurukh | kru_Deva | Devanagari |
| Awadhi | awa_Deva | Devanagari | Kutchi | kfr_Deva | Devanagari |
| Bagheli | bfy_Deva | Devanagari | Magahi | mag_Deva | Devanagari |
| Bagri | bgq_Deva | Devanagari | Maithili | mai_Deva | Devanagari |
| Banjari | brj_Deva | Devanagari | Malayalam | mal_Mlym | Malayalam |
| Bengali | ben_Beng | Bengali | Manipuri | mni_Beng | Bengali |
| Bhili | bhb_Deva | Devanagari | Manipuri | mni_Mtei | Meitei Mayek |
| Bhojpuri | bho_Deva | Devanagari | Marathi | mar_Deva | Devanagari |
| Bodo | brx_Deva | Devanagari | Marwari | mwr_Deva | Devanagari |
| Braj Bhasha | bra_Deva | Devanagari | Mewari | mtr_Deva | Devanagari |
| Bundeli | bns_Deva | Devanagari | Mizo | lus_Latn | Latin |
| Chhattisgarhi | hne_Deva | Devanagari | Nepali | npi_Deva | Devanagari |
| Dakhini | dcc_Deva | Devanagari | Odia | ory_Orya | Odia |
| Dogri | doi_Deva | Devanagari | Pahari | phr_Deva | Devanagari |
| Garhwali | gbm_Deva | Devanagari | Punjabi | pan_Guru | Gurmukhi |
| Garo | grt_Latn | Latin | Rajasthani | raj_Deva | Devanagari |
| Gondi | gon_Deva | Devanagari | Sambalpuri | spv_Orya | Odia |
| Gujarati | guj_Gujr | Gujarati | Sanskrit | san_Deva | Devanagari |
| Haryanvi | bgc_Deva | Devanagari | Santali | sat_Olck | Ol Chiki |
| Hindi | hin_Deva | Devanagari | Sindhi | snd_Arab | Arabic |
| Ho | hoc_Deva | Devanagari | Sora | srb_Latn | Latin |
| Kangri | xnr_Deva | Devanagari | Tamil | tam_Taml | Tamil |
| Kannada | kan_Knda | Kannada | Telugu | tel_Telu | Telugu |
| Kashmiri | kas_Arab | Arabic | Tulu | tcy_Knda | Kannada |
| Kashmiri | kas_Deva | Devanagari | Urdu | urd_Arab | Arabic |
| Khasi | kha_Latn | Latin | Wagdi | wbr_Deva | Devanagari |
| Khortha | kho_Deva | Devanagari | | | |
| Kodava | kfa_Knda | Kannada | | | |
| Konkani | kok_Deva | Devanagari | | | |

## How to Use

### Quick Start (Transformers)

```python
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer

# Load model
model = AutoModelForSeq2SeqLM.from_pretrained("Anonym-050326/nirukti-translate-1.3b")
tokenizer = AutoTokenizer.from_pretrained("Anonym-050326/nirukti-translate-1.3b")

# Translate English to Hindi
tokenizer.src_lang = "eng_Latn"
inputs = tokenizer("Hello, how are you?", return_tensors="pt")
translated = model.generate(
    **inputs,
    forced_bos_token_id=tokenizer.convert_tokens_to_ids("hin_Deva"),
    max_new_tokens=128,
)
print(tokenizer.decode(translated[0], skip_special_tokens=True))
```

### CTranslate2 (Fastest — Recommended for Production)

```python
import ctranslate2
from transformers import AutoTokenizer

translator = ctranslate2.Translator("ct2-int8", device="cuda", compute_type="int8_float16")
tokenizer = AutoTokenizer.from_pretrained("Anonym-050326/nirukti-translate-1.3b")
tokenizer.src_lang = "eng_Latn"

text = "Hello, how are you?"
encoded = tokenizer(text, return_tensors=None, max_length=256, truncation=True)
tokens = tokenizer.convert_ids_to_tokens(encoded["input_ids"])

result = translator.translate_batch([tokens], target_prefix=[["hin_Deva"]], beam_size=5)
output_tokens = result[0].hypotheses[0][1:]  # skip language token
output_ids = tokenizer.convert_tokens_to_ids(output_tokens)
print(tokenizer.decode(output_ids, skip_special_tokens=True))
```

### Translating Between Any Language Pair

Set `tokenizer.src_lang` to the source language code and use the target code as `forced_bos_token_id` (Transformers) or `target_prefix` (CTranslate2).

```python
# Tamil to English
tokenizer.src_lang = "tam_Taml"
# forced_bos_token_id=tokenizer.convert_tokens_to_ids("eng_Latn")

# English to Marwari
tokenizer.src_lang = "eng_Latn"
# forced_bos_token_id=tokenizer.convert_tokens_to_ids("mwr_Deva")
```

## Testing Scripts

This repository includes evaluation and testing scripts in the `testing_scripts/` directory:

| Script | Description |
|--------|-------------|
| `testing_scripts/run_evaluation.py` | Multi-GPU evaluation runner (BLEU + chrF++) |
| `testing_scripts/download_datasets.py` | Download standard Indic translation benchmarks |
| `testing_scripts/excel_to_csv.py` | Convert Excel test datasets to evaluation format |

### Running Evaluation

```bash
# 1. Convert to CTranslate2 int8 for fast inference
ct2-opennmt-py-converter --model_path Anonym-050326/nirukti-translate-1.3b --output_dir ct2-int8 --quantization int8

# 2. Download benchmark datasets
python testing_scripts/download_datasets.py --output-dir eval_data

# 3. Run multi-GPU evaluation
python testing_scripts/run_evaluation.py \
    --model ct2-int8 \
    --tokenizer Anonym-050326/nirukti-translate-1.3b \
    --manifest eval_data/manifest.json \
    --output-dir results \
    --num-gpus 4 --batch-size 64 --beam-size 5
```

## Training Details

### Architecture

- **Base**: 1.3B parameter encoder-decoder translation model
- **Fine-tuning**: LoRA (rank 32, alpha 64) on attention + FFN layers, merged into base weights
- **Trainable parameters**: ~0.75% of total during training
- **2-stage training**: embedding divergence followed by LoRA fine-tuning

### Hyperparameters

| Parameter | Value |
|-----------|-------|
| Learning rate | 3e-5 (cosine schedule) |
| Warmup steps | 1,000 |
| Effective batch size | 256 |
| Epochs | 5 |
| Max sequence length | 128 tokens |
| Precision | BF16 |
| Label smoothing | 0.1 |
| Language balancing | Temperature sampling (T=5.0) |

### Training Data

Trained on a curated combination of parallel corpora covering all 55 languages, with hash-based deduplication and quality filtering. Low-resource language pairs are upsampled using temperature-based balancing to ensure adequate representation.

### Compute

- **Training**: 2x NVIDIA A100-SXM4-80GB, PyTorch DDP
- **Inference**: CTranslate2 int8 quantization

## Limitations

- Low-resource languages (33 newly added) have less training data and lower translation quality than high-resource languages
- Performance varies by script — languages with multiple script variants may show different quality levels
- Training data is primarily from news, government, and religious domains; informal or conversational text may translate differently
- Very short sentences (1-5 words) are harder for the model due to limited context
