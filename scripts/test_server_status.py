import requests
import json

try:
    res = requests.get('http://127.0.0.1:8080/status', timeout=5)
    print("STATUS CODE:", res.status_code)
    print("RESPONSE BODY:", res.json())
except Exception as e:
    print("STATUS CHECK ERROR:", e)
