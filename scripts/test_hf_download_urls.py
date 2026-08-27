import urllib.request

tokens_url = "https://huggingface.co/parismitaglobalsolutions/indicconformer-sherpa-onnx/resolve/main/tokens.txt"
model_url = "https://huggingface.co/parismitaglobalsolutions/indicconformer-sherpa-onnx/resolve/main/hi/model.int8.onnx"

print("Checking tokens URL...")
req1 = urllib.request.Request(tokens_url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req1) as resp:
    print("Tokens status:", resp.status, "URL:", resp.geturl())
    content = resp.read(200)
    print("Tokens sample:", content.decode('utf-8', errors='ignore')[:100])

print("\nChecking model URL...")
req2 = urllib.request.Request(model_url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req2) as resp:
    print("Model status:", resp.status, "URL:", resp.geturl())
    print("Model Content-Length:", resp.headers.get('Content-Length'))
