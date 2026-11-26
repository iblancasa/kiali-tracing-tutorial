"""Shared by every service of Mesh Pizza: the HTTP client and, above all,
the trace context propagation that steps 3 and 4 of the tutorial are about.
"""
import logging
import os
import random
import time

import flask
import requests

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(name)s %(message)s')
logging.getLogger('waitress').setLevel(logging.WARNING)

# Step 3 of the tutorial turns this on: kubectl set env ... PROPAGATE_TRACE_HEADERS=true
PROPAGATE_TRACE_HEADERS = os.environ.get('PROPAGATE_TRACE_HEADERS', 'false').lower() == 'true'

# Headers that carry the trace context. Envoy (the Istio proxy) reads and
# writes them, but it cannot copy them from the request this code received
# to the requests this code sends. Only the application can do that.
TRACE_HEADERS = [
    # W3C Trace Context: what Istio uses with the OpenTelemetry provider
    'traceparent',
    'tracestate',
    # B3 multi: what Istio uses with the Zipkin provider
    'x-b3-traceid',
    'x-b3-spanid',
    'x-b3-parentspanid',
    'x-b3-sampled',
    'x-b3-flags',
    # Envoy request id
    'x-request-id',
]


def trace_headers():
    """The trace context of the request being handled, ready to be sent on."""
    if not PROPAGATE_TRACE_HEADERS:
        return {}
    incoming = flask.request.headers  # case-insensitive
    return {name: incoming[name] for name in TRACE_HEADERS if name in incoming}


def call(method, service, path, **kwargs):
    """Call another service of the shop, for example call('GET', 'pricing', '/prices')."""
    url = f'http://{service}:8080{path}'
    return requests.request(method, url, headers=trace_headers(), timeout=10, **kwargs)


def work(min_ms, max_ms):
    """Pretend to do something that takes between min_ms and max_ms."""
    time.sleep(random.uniform(min_ms, max_ms) / 1000)


def create_app(name):
    app = flask.Flask(name)

    @app.route('/healthz')
    def healthz():
        return 'ok'

    return app


def upstream_error(service, response):
    """A 502 that says which dependency failed."""
    return flask.jsonify(error=f'{service} answered {response.status_code}', detail=response.text[:200]), 502
