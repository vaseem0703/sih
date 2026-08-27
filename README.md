# SIH 26042 — Vani Setu: Vernacular Classroom AI & Translation Assistant

AI-powered, offline-first Mother-Tongue pedagogy and real-time translation assistant for primary schools (Hindi ↔ Santali Ol Chiki, Ho, and Mundari).

---

## 🚀 Key Features

* **📱 100% On-Device Standalone Offline Hindi ASR:**  
  Uses native C++ `sherpa_onnx 1.13.6` runtime on Android ARM64 with AI4Bharat's **IndicConformer Hindi ONNX (INT8)** model (`model.int8.onnx` ~150 MB). Performs speech recognition directly on the phone with **0% network, 0% PC, and 0% USB/ADB dependency**.
* **🌾 IndicTrans2 Neural Machine Translation:**  
  Offline-ready Hindi ➔ Santali (Ol Chiki), Ho (Wara Citi), and Mundari translation.
* **🔊 Quipus 0.6 + SNAC Santali Voice Synthesis:**  
  High-fidelity 24kHz Santali speech generation for classroom assistant prompts.
* **⚡ One-Time On-Demand Model Download:**  
  Model files (~150 MB) are fetched once into app-private storage. Once downloaded, ASR operates 100% offline.

---

## 📁 Project Architecture

```
SIH_Translator/
├── sih_flutter_app/            # Flutter Mobile & Desktop Application
│   ├── lib/
│   │   ├── app/                # Theme, routing, and master layout
│   │   ├── screens/            # Home, Live Classroom, Lessons, Worksheets, Settings
│   │   ├── services/           # OnDeviceAsrService (Sherpa-ONNX), SpeechService, LocalAiBridge
│   │   ├── models/             # Translation models & data classes
│   │   └── widgets/            # Bottom navigation, custom headers, audio visualizer
│   └── assets/audio/           # Bundled normalized classroom audio waveforms
├── models/                     # Model architecture files & configurations
│   ├── indictrans2/            # IndicTrans2 Hindi ➔ Santali NMT config & code
│   └── quipus/                 # Quipus 0.6 Speech v2 TTS tokenizer & config
├── download_indictrans2.py     # Download script for IndicTrans2 weights
├── download_quipus.py          # Download script for Quipus TTS weights
├── local_ai_server.py          # Local Python AI Bridge Server (IndicTrans2 NMT + Quipus TTS)
├── requirements.txt            # Python dependencies (PyTorch, Transformers, SentencePiece)
└── scripts/                    # Offline testing, verification, and CLI scripts
    ├── inspect_all_live_recordings.py  # Audio signal & transcription inspector
    └── test_hf_download_urls.py        # HuggingFace download URL validator
```

---

## 🎙️ On-Device Offline ASR Architecture

```
[Physical Phone Microphone] ➔ [16 kHz Mono Audio] ➔ [Sherpa-ONNX Native C++ Engine] ➔ [IndicConformer ONNX (int8)] ➔ [Hindi Text] ➔ [Flutter UI]
```

### Model Details:
* **Framework:** `sherpa_onnx 1.13.6` (`OfflineNemoEncDecCtcModelConfig`)
* **Quantization:** INT8 ONNX (~150 MB)
* **Tokenizer:** `tokens.txt` (vocabulary token map)
* **Storage Location:** App-private storage (`getApplicationDocumentsDirectory()/models/sherpa_onnx/hi/`)

---

## 🛠️ Quickstart for Developers

### 1. Clone the Repository
```bash
git clone https://github.com/vaseem0703/sih.git
cd sih
```

---

### 2. Run the Flutter Application

Navigate to the Flutter directory and run the application:

```bash
cd sih_flutter_app
flutter pub get
flutter run
```

---

### 3. Python Local AI Server Setup (For NMT & TTS)

Create and activate a Python virtual environment:

```bash
# On Windows (PowerShell)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install requirements
pip install -r requirements.txt

# Download NMT & TTS weights
python download_indictrans2.py
python download_quipus.py

# Start Local AI Server (Port 8080)
python local_ai_server.py
```

*Server starts on `http://127.0.0.1:8080` exposing `/status`, `/translate`, and `/tts` endpoints.*

---

## 📄 License & Credits

* **AI4Bharat IndicConformer & IndicTrans2:** [AI4Bharat](https://ai4bharat.iitm.ac.in/)
* **Sherpa-ONNX Framework:** [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)
* **IndicConformer ONNX INT8 Conversion:** `parismitaglobalsolutions/indicconformer-sherpa-onnx`
