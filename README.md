# SIH 26042 — Mother-Tongue Vernacular Classroom AI & Translation Assistant

AI-powered, offline-first Mother-Tongue pedagogy and real-time translation assistant for primary schools (Hindi ↔ Santali Ol Chiki, Ho, and Mundari).

---

## 📁 Project Architecture

```
SIH_Translator/
├── sih_flutter_app/            # Flutter Mobile & Desktop Application
│   ├── lib/
│   │   ├── app/                # Theme, routing, and master layout
│   │   ├── screens/            # Home, Live Classroom, Lessons, Worksheets, Settings
│   │   ├── services/           # Speech STT, IndicTrans2 NMT, Quipus TTS, Local AI Bridge
│   │   ├── models/             # Data and translation models
│   │   └── widgets/            # Bottom navigation, custom headers, audio players
│   └── assets/audio/           # Bundled 24kHz normalized Santali speech waveforms
├── models/                     # Model architecture files & configurations
│   ├── indictrans2/            # IndicTrans2 Hindi ➔ Santali NMT config & code
│   ├── quipus/                 # Quipus 0.6 Speech v2 TTS tokenizer & config
│   └── indicconformer/         # IndicConformer Hindi ASR configs
├── download_indictrans2.py     # Download script for IndicTrans2 weights
├── download_quipus.py          # Download script for Quipus TTS weights
├── local_ai_server.py          # Local Python AI Bridge Server (ASR + NMT + TTS)
├── test_indictrans2.py         # Offline IndicTrans2 verification
├── verify_stage15_tts.py       # Quipus TTS 24kHz verification
├── verify_multilanguage.py     # Multilingual IndicTrans2 verification (10 languages)
├── run_cli.py                  # Interactive CLI for offline classroom translation
└── .gitignore                  # Clean repository ignore configuration
```

---

## 🚀 Quickstart for Developers

### 1. Clone the Repository
```bash
git clone https://github.com/vaseem0703/sih.git
cd sih
```

---

### 2. Python AI Environment Setup

Create and activate a Python 3.10+ virtual environment:

```bash
# On Linux / WSL / macOS
python3 -m venv venv
source venv/bin/activate

# On Windows (PowerShell)
python -m venv venv
.\venv\Scripts\Activate.ps1
```

Install core dependencies:
```bash
pip install torch soundfile transformers huggingface_hub accelerate snac
```

---

### 3. Model Weights Download (Optional for Live Inference)

Run the automated download scripts to fetch model weights:

```bash
# Download IndicTrans2 Hindi-Santali NMT Model
python download_indictrans2.py

# Download Quipus 0.6 Santali TTS Model
python download_quipus.py
```

*Note: Model weights are stored in the local `./models/` directory and are automatically loaded by the local AI server.*

---

### 4. Start the Local AI Bridge Server

To run the local translation and voice synthesis server:

```bash
python local_ai_server.py
```
*Server starts on `http://127.0.0.1:8080` exposing `/status`, `/translate`, and `/tts` endpoints.*

---

### 5. Run the Flutter Application

Navigate to the Flutter directory:

```bash
cd sih_flutter_app
flutter pub get
```

#### Run on Connected Android Device / Emulator:
```bash
# If using physical device over USB, forward the AI server port:
adb reverse tcp:8080 tcp:8080

# Run the app
flutter run
```

#### Run on Windows / Chrome:
```bash
flutter run -d windows
# or
flutter run -d chrome
```

---

## 🛠️ Offline Verification Scripts

Run the self-contained verification scripts to test the AI models:

```bash
# Test IndicTrans2 Hindi ➔ Santali Ol Chiki Translation
python test_indictrans2.py

# Test Multilingual Translation across 10 Indian Languages
python verify_multilanguage.py

# Test Quipus Santali Voice Synthesis
python verify_stage15_tts.py
```

---

## 🔒 Security & Privacy Notice
This repository contains **zero hardcoded tokens, API keys, or secrets**. All models run 100% locally and offline without external cloud API dependencies.
