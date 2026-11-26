"""loadgen: background customers, so the graphs are never empty.

Runs outside the mesh (namespace loadgen, no sidecar) and comes in through
the Istio ingress gateway, like a browser would."""
import json
import os
import random
import time
import urllib.error
import urllib.request

TARGET = os.environ.get('TARGET', 'http://istio-ingressgateway.istio-system.svc.cluster.local')
RATE = float(os.environ.get('REQUESTS_PER_SECOND', '3'))
PIZZAS = ['margherita', 'margherita', 'diavola', 'quattro-formaggi', 'hawaiian']


def request(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(TARGET + path, data=data, method=method,
                                 headers={'content-type': 'application/json'})
    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            response.read()
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    except Exception as error:  # the gateway is not there yet, or gone
        status = type(error).__name__
    print(f'{method:4} {path:12} -> {status} in {int((time.time() - start) * 1000)} ms', flush=True)


while True:
    if random.random() < 0.5:
        request('GET', '/api/menu')
    else:
        request('POST', '/api/orders', {'pizza': random.choice(PIZZAS), 'qty': random.randint(1, 3)})
    time.sleep(random.expovariate(RATE))
