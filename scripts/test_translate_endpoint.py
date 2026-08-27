import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("=" * 60)
print("  TESTING LOCAL AI SERVER /translate ENDPOINT")
print("=" * 60)

url = "http://127.0.0.1:8080/translate"
test_sentences = [
    "किताब खोलो",
    "सब लोग किताब खोलो"
]

for sentence in test_sentences:
    payload = {"text": sentence, "src": "hin_Deva", "tgt": "sat_Olck"}
    try:
        res = requests.post(url, json=payload, timeout=30)
        data = res.json()
        print("==================================================")
        print("[TRANSLATION DEBUG]")
        print(f"INPUT HINDI : '{sentence}'")
        print(f"HTTP STATUS : {res.status_code}")
        print(f"MODEL OUTPUT: '{data.get('translation')}'")
        print(f"LATENCY     : {data.get('latency')}s")
        print(f"SOURCE      : {data.get('source')}")
        print("==================================================")
    except Exception as e:
        print(f"ERROR for '{sentence}': {e}")
