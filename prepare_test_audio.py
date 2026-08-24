import sys
import os
import librosa
import soundfile as sf
from gtts import gTTS

# Ensure UTF-8 output encoding for Windows console
sys.stdout.reconfigure(encoding='utf-8')

os.makedirs("test_audio", exist_ok=True)
mp3_path = "test_audio/temp_hindi.mp3"
wav_path = "test_audio/hindi_test.wav"

hindi_text = "आज हम संख्याएँ सीखेंगे।"
print(f"Generating audio for text: '{hindi_text}'")

tts = gTTS(text=hindi_text, lang='hi')
tts.save(mp3_path)

# Load audio and resample to 16000 Hz, mono
y, sr = librosa.load(mp3_path, sr=16000, mono=True)
sf.write(wav_path, y, 16000, subtype='PCM_16')

if os.path.exists(mp3_path):
    os.remove(mp3_path)

# Verify generated audio properties
info = sf.info(wav_path)
print(f"Generated Audio File: {wav_path}")
print(f"  Sample Rate: {info.samplerate} Hz")
print(f"  Channels: {info.channels}")
print(f"  Format: {info.format} ({info.subtype})")
print(f"  Duration: {info.duration:.2f} seconds")

assert info.samplerate == 16000, f"Expected 16000 Hz, got {info.samplerate}"
assert info.channels == 1, f"Expected 1 channel (mono), got {info.channels}"
print("AUDIO PREPARATION SUCCESSFUL!")
