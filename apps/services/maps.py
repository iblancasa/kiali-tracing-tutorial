"""maps: computes the route from the shop to an address.

Most answers come from a cache. SLOW_RATE of them do not, and take well
over a second. This is the latency you look for in step 2."""
import os
import random

import flask

from .common import create_app, work

app = create_app('maps')

SLOW_RATE = float(os.environ.get('SLOW_RATE', '0.2'))


@app.route('/route')
def route():
    if random.random() < SLOW_RATE:
        work(1200, 1800)  # geocoder cache miss
    else:
        work(5, 15)
    return flask.jsonify(to=flask.request.args.get('to'), minutes=random.randint(10, 25))
