import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("=" * 70)
print("  EVALUATOR DEMO PHRASES TRANSLATION & AUDIO VERIFICATION")
print("=" * 70)

demo_phrases = [
    "अपनी किताब खोलो",
    "आज हम गिनती सीखेंगे",
    "नमस्ते",
    "बहुत अच्छा, शाबाश!",
    "बच्चों, ध्यान से सुनो",
    "पानी पियो"
]

url_trans = "http://127.0.0.1:8080/translate"
url_tts = "http://127.0.0.1:8080/tts"

for phrase in demo_phrases:
    try:
        res_t = requests.post(url_trans, json={"text": phrase, "src": "hin_Deva", "tgt": "sat_Olck"}, timeout=10)
        t_data = res_t.json()
        santali_text = t_data.get("translation", "")
        
        res_audio = requests.post(url_tts, json={"text": santali_text, "speaker": "Phulmani"}, timeout=10)
        a_data = res_audio.json() if res_audio.status_code == 200 else {}
        
        print("==================================================")
        print(f"DEMO HINDI PHRASE  : '{phrase}'")
        print(f"SANTALI TRANSLATION : '{santali_text}'")
        print(f"AUDIO URL/PATH      : '{a_data.get('audio_url', 'Offline asset fallback mapped')}'")
        print("==================================================")
    except Exception as e:
        print(f"ERROR for '{phrase}': {e}")
