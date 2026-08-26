---
license: mit
library_name: transformers
pipeline_tag: text-to-speech
language:
- as
- bn
- brx
- doi
- gu
- hi
- kn
- ks
- kok
- mai
- ml
- mni
- mr
- ne
- or
- pa
- sa
- sat
- sd
- ta
- te
- ur
tags:
- tts
- speech
- audio
- multilingual
- indian-languages
- qwen3
- unsloth
base_model: hyperneuronAILabs/quipus-0.6-speechv1
---

<p align="center">
  <img src="./logo.png" alt="HyperneuronAI Logo" width="180"/>
</p>

<h1 align="center">HyperneuronAI Text-to-Speech Model</h1>

<p align="center">
  Multilingual Open-Source Text-to-Speech for Indian Languages
</p>

<p align="center">
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
  </a>
</p>

## Model Details

### Model Description

This is an open-source Text-to-Speech model developed by HyperneuronAI. The model is designed to generate natural speech from text and now supports all **22 officially recognized languages of India**: Assamese, Bengali, Bodo, Dogri, Gujarati, Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri, Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu, and Urdu.

> **What's new:** this release expands the original 4-language model (Hindi, Assamese, Punjabi, Kannada) to full coverage of all 22 scheduled Indian languages, using a replay-based fine-tuning strategy so quality on the original 4 languages is preserved while adding 18 new ones. See [Training Details](#training-details) below.

Quipus is **2x** Faster than realtime and lower latency **TTFB ~120ms** (on google colab).<sup></sup>
Quipus is **4.3x** Faster than realtime(on dedicated Nvidia L40S).<sup></sup>

## ⚡Quipus Performance(Nvidia L40S optimised)

| Metric | Value |
|---------|------:|
| First Audio | **~<80 ms**<sup>†</sup> |
| Generation Speed | **4.3× Realtime**<sup>†</sup> |
| Languages | **22** |

## ⚡Quipus Performance(Google colab)
| Metric | Value |
|---------|------:|
| First Audio | **~120 ms**<sup>†</sup> |
| Generation Speed | **2× Realtime**<sup>†</sup> |
| Languages | **22** |

<sup>†</sup> Inherited from the prior 4-language release — architecture and generation loop are unchanged, so these should still hold, but they have not been re-benchmarked specifically against the 22-language checkpoint yet. Treat as provisional until re-verified.

## Sneak Peak
In model Inference performance
![image](https://cdn-uploads.huggingface.co/production/uploads/68e38c9bfc9f7cbda99f8a3f/ZKWuzaty4hQYnYviYGGN5.png)


## 🗺️ Roadmap

- 😊 Emotion-aware Speech
- 🌍 Arabic & English support as part of worldwide contribution
- ⚡ Streaming Backend Optimizations
- Training and Inference Code

<p>
<a href="https://github.com/vllm-project/vllm">
<img src="https://img.shields.io/badge/vLLM-Added%20Below-blue?logo=v">
</a>
<a href="https://github.com/sgl-project/sglang">
<img src="https://img.shields.io/badge/SGLang-Coming%20Soon-orange">
</a>
</p>

The model uses a Qwen3 backbone and is intended for research, experimentation, and building voice AI applications. Users are free to fine-tune the model for custom voices and additional languages.

Voice cloning capabilities are not provided with this release to encourage responsible AI usage.

* **Developed by:** HyperneuronAI
* **Funded by:** HyperneuronAI
* **Shared by:** HyperneuronAI
* **Model type:** Text-to-Speech
* **Backbone:** Qwen3
* **Languages:** Assamese, Bengali, Bodo, Dogri, Gujarati, Hindi, Kannada, Kashmiri, Konkani, Maithili, Malayalam, Manipuri, Marathi, Nepali, Odia, Punjabi, Sanskrit, Santali, Sindhi, Tamil, Telugu, Urdu
* **License:** MIT


## Audio Samples

| Language | Sample |
|-----------|--------|
| 🇮🇳 Kannada | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_kannada.wav"></audio> |
| 🇮🇳 Hindi | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_hindi.wav"></audio> |
| 🇮🇳 Punjabi | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_punjabi.wav"></audio> |
| 🇮🇳 Assamese | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_assamese.wav"></audio> |
| 🇮🇳 Tamil | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_tamil.wav"></audio> |
| 🇮🇳 Telugu | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_telugu.wav"></audio> |
| 🇮🇳 Bengali | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_bengali.wav"></audio> |
| 🇮🇳 Bodo | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_bodo.wav"></audio> |
| 🇮🇳 Dogri | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_dogri.wav"></audio> |
| 🇮🇳 Gujarati | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_gujarati.wav"></audio> |
| 🇮🇳 Kashmiri | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_kashmiri.wav"></audio> |
| 🇮🇳 Konkani | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_konkani.wav"></audio> |
| 🇮🇳 Maithili | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_maithili.wav"></audio> |
| 🇮🇳 Malayalam | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_malayalam.wav"></audio> |
| 🇮🇳 Manipuri | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_manipuri.wav"></audio> |
| 🇮🇳 Marathi | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_marathi.wav"></audio> |
| 🇳🇵 Nepali | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_nepali.wav"></audio> |
| 🇮🇳 Odia | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_odia.wav"></audio> |
| 🇮🇳 Sanskrit | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_sanskrit.wav"></audio> |
| 🇮🇳 Santali | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_santali.wav"></audio> |
| 🇮🇳 Sindhi | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_sindhi.wav"></audio> |
| 🇮🇳 Urdu | <audio controls="" src="/hyperneuronAILabs/quipus-0.6-speechv2/resolve/main/artifacts/artifact_urdu.wav"></audio> |

> Samples for the 18 newly added languages are not yet uploaded to this repo — the table above only has the original 4. Upload new `.wav` files to `artifacts/` and add a row per language (or generate them fresh with the code in "How to Get Started" below) before this table reflects full 22-language coverage.

## 🎙️ Available Voices

| Language | Speakers |
|-----------|----------|
| 🇮🇳 Assamese | Dipankar(Male) • Kavita(Female) |
| 🇮🇳 Bengali | Arindam(Male) • Rupa(Female) |
| 🇮🇳 Bodo | Daimalu(Male) • Mainao(Female) |
| 🇮🇳 Dogri | Balwant(Male) • Shakti(Female) |
| 🇮🇳 Gujarati | Nirav(Male) • Hetal(Female) |
| 🇮🇳 Hindi | Raman(Male) • Anvita(Female) |
| 🇮🇳 Kannada | Manjunath(Male) • Sindhura(Female) |
| 🇮🇳 Kashmiri | Farooq(Male) • Habba(Female) |
| 🇮🇳 Konkani | Ramnath(Male) • Shweta(Female) |
| 🇮🇳 Maithili | Vidyapati(Male) • Mythili(Female) |
| 🇮🇳 Malayalam | Unnikrishnan(Male) • Lakshmi(Female) |
| 🇮🇳 Manipuri | Ibomcha(Male) • Chaoba(Female) |
| 🇮🇳 Marathi | Sachin(Male) • Smita(Female) |
| 🇮🇳 Nepali | Prakash(Male) • Sunita(Female) |
| 🇮🇳 Odia | Jagannath(Male) • Sunanda(Female) |
| 🇮🇳 Punjabi | Amanjit(Male) • Supreet(Female) |
| 🇮🇳 Sanskrit | Aryan(Male) • Devavani(Female) |
| 🇮🇳 Santali | Sido(Male) • Phulmani(Female) |
| 🇮🇳 Sindhi | Hari(Male) • Kajal(Female) |
| 🇮🇳 Tamil | Murugan(Male) • Kamala(Female) |
| 🇮🇳 Telugu | Ravi(Male) • Padma(Female) |
| 🇮🇳 Urdu | Salman(Male) • Zoya(Female) |

44 speaker voices total (2 per language × 22 languages).

## Model Sources

* Repository: Realtime optimized streaming inference code is planned for a future release.
* Demo: Coming soon.

## Uses

### Direct Use

This model can be used for Text-to-Speech generation in voice AI applications, including:

| ✅ |
|---|
| Conversational AI |
| AI Calling |
| Voice Assistants |
| Accessibility |
| Customer Support |
| IVR |
| Edge Devices |
| Research |

### Fine-Tuning

Users may fine-tune this model for:

* New speakers
* Domain-specific speech styles
* Additional languages beyond the current 22
* Custom application-specific voices

### Out-of-Scope Use

This model should not be used for unethical, harmful, deceptive, or illegal purposes, including but not limited to:

* Impersonation without consent
* Fraudulent voice generation
* Misinformation or manipulation
* Harassment or abuse
* Any use that violates applicable laws or platform policies

HyperneuronAI is not responsible for misuse of this model by third parties.

## How to Get Started

vLLM code examples.

```python
#Install libraries if not installed
# Download vlllm based on cuda version
#!pip install vllm==0.19.0
#!pip install -q soundfile
# !apt-get update -qq
# !apt-get install -y -qq libsndfile1
# !pip install snac

# ==========================================
# vLLM SERVING - Colab-safe audio saving
# ==========================================
"""
You can use vllm for inferencing as it provides optimised control over cuda profiling and inturn better response time.
"""
import time
import re
import torch
import numpy as np
import soundfile as sf
from IPython.display import Audio, display

from vllm import LLM, SamplingParams
from snac import SNAC
import multiprocessing

# Force spawn instead of fork
os.environ["VLLM_WORKER_MULTIPROC_METHOD"] = "spawn"
os.environ["HF_TOKEN"] = "<Your hugging face token>"
# Ensure the multiprocessing context matches
try:
    multiprocessing.set_start_method("spawn")
except RuntimeError:
    pass



VLLM_MODEL_PATH = "hyperneuronAILabs/quipus-0.6-speechv2"
DEFAULT_SPEAKER = "Anvita"  # any of the 44 voices in "Available Voices" above
FRAME_LAYER_PATTERN = [0, 1, 2, 2, 1, 2, 2]
SAMPLE_RATE = 24000

llm = LLM(
    model=VLLM_MODEL_PATH,
    dtype="bfloat16",
    max_model_len=2048,
    gpu_memory_utilization=0.20,
    enforce_eager=False,
)

tok = llm.get_tokenizer()

AUDIO_END_ID = tok.convert_tokens_to_ids("<audio_end>")

snac_decoder = (
    SNAC.from_pretrained("hubertsiuzdak/snac_24khz")
    .eval()
    .cuda()
)

def build_prompt_prefix(speaker, text):
    return f"{speaker}: {text} <audio_start> "

def quipus_tts(
    text,
    speaker=DEFAULT_SPEAKER,
    out="vllm_out.wav",
    temperature=0.7,
    top_p=0.9,
):
    prompt = build_prompt_prefix(speaker, text)

    sampling_params = SamplingParams(
        temperature=temperature,
        top_p=top_p,
        repetition_penalty=1.1,
        max_tokens=1024,
        stop_token_ids=[AUDIO_END_ID],
    )

    t0 = time.time()
    result = llm.generate([prompt], sampling_params)
    gen_time = time.time() - t0

    out_ids = list(result[0].outputs[0].token_ids)
    toks = tok.convert_ids_to_tokens(out_ids)

    parsed = []
    for token in toks:
        match = re.fullmatch(r"<snac_l(\d+)_c(\d+)>", token)
        if match:
            parsed.append((int(match.group(1)), int(match.group(2))))

    l0, l1, l2 = [], [], []
    i = 0

    while i + 7 <= len(parsed):
        window = parsed[i:i + 7]

        if [layer for layer, _ in window] == FRAME_LAYER_PATTERN:
            codes = [code for _, code in window]

            l0.append(codes[0])
            l1.extend([codes[1], codes[4]])
            l2.extend([codes[2], codes[3], codes[5], codes[6]])

            i += 7
        else:
            i += 1

    if not l0:
        print("No valid SNAC frames from vLLM output.")
        return None

    with torch.inference_mode():
        wav = snac_decoder.decode(
            [
                torch.tensor([l0], dtype=torch.long, device="cuda"),
                torch.tensor([l1], dtype=torch.long, device="cuda"),
                torch.tensor([l2], dtype=torch.long, device="cuda"),
            ]
        )

    audio_sec = wav.shape[-1] / SAMPLE_RATE

    pcm = wav.detach().squeeze().float().cpu().numpy()
    pcm = np.clip(pcm, -1.0, 1.0)

    sf.write(out, pcm, SAMPLE_RATE)

    n = len(out_ids)

    display(Audio(out, rate=SAMPLE_RATE))

    return out

quipus_tts(
    "यह मॉडल स्पीच-टू-टेक्स्ट मॉडल है , जिसे निखिल ने विकसित किया है। এই মডেলটো হৈছে স্পিচ টু টেক্সট মডেল, নিখিলে বিকশিত কৰিছে",
    speaker=DEFAULT_SPEAKER,
)
```

## Training Details

### Training Data

The model was trained on the **<a href="https://www.hyperneuronai.com">HyperneuronAI's propriatery data</a>** and **Opensource data**.We will mention in all here soon.

### Training Procedure

* **Base checkpoint:** this repo's prior release (4-language: Hindi, Assamese, Punjabi, Kannada).
* **Method:** full parameter fine-tuning — all 608,362,496 parameters trained.
* **Audio representation:** SNAC neural codec at 24kHz, hierarchical 3-layer codebook, flattened into a 7-token-per-frame sequence (Orpheus-style interleave) so all three resolution layers stay time-aligned.
* **Prompt format:** `"{speaker}: {text} <audio_start> {audio_tokens} <audio_end>"` — loss is computed only on the audio-token portion; the text prompt is masked out.
* **Tokenizer:** unchanged from the base checkpoint — the SNAC control tokens were already present in its vocabulary, so no vocabulary resize was needed this round.

### Training Hyperparameters

Training hyperparameters will be added in a future update.

## Evaluation

### Testing Data

Informal qualitative listening checks were run across all 22 languages using fixed test phrases and each language's paired speakers. A formal held-out evaluation set has not yet been built for this release.

### Metrics

Formal evaluation metrics such as MOS, speaker similarity, intelligibility, word error rate, and latency benchmarks are not yet published for the 22-language checkpoint.

### Results

Evaluation results will be added after broader testing and benchmarking.

## Technical Specifications

### Model Architecture and Objective

This is a Text-to-Speech model with a Qwen3 backbone. The model is optimized to generate speech from input text in supported Indian languages.

Further architecture details will be added in future documentation.

### Compute Infrastructure

Compute details will be added in a future update.

### Software

Software and inference dependencies will be added with the official inference code.


## Limitations

* Output quality may vary depending on language, text normalization, punctuation, and input style.
* The model may struggle with code-mixed text, rare words, abbreviations, numerals, and domain-specific terminology.
* Voice cloning is not included in this release.
* Realtime streaming inference code is planned but not included yet.

## Ethical Considerations

This model is released to support open-source development of Indian language voice AI. Users should ensure responsible deployment, obtain consent where required, and avoid deceptive or harmful applications.

## Citation

Citation details will be added in a future release.

## Authors

| Name |
|------|
| **Nikhil Yadav** 
| **Ramanjit Singh** 
| **Pradeep Yadav** 
| **HyperneuronAI Research** 


## 🤝 Contact
For questions, collaborations, or contributions, please contact HyperneuronAI

  📧 support@hyperneuron.in
  
  🌐 https://www.hyperneuronai.com
  
  🤗 https://huggingface.co/hyperneuronAILabs