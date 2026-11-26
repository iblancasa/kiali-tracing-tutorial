"""payments: checks the order with fraud, then charges the card at the bank.

The bank is simulated, and it is not a good bank: BANK_FAILURE_RATE of the
charges fail with a 503. This is the error you look for in step 2."""
import logging
import os
import random

import flask

from .common import call, create_app, upstream_error, work

app = create_app('payments')
log = logging.getLogger('payments')

BANK_FAILURE_RATE = float(os.environ.get('BANK_FAILURE_RATE', '0.15'))


@app.route('/charge', methods=['POST'])
def charge():
    payment = flask.request.get_json()
    work(3, 10)
    check = call('POST', 'fraud', '/check', json=payment)
    if check.status_code != 200:
        return upstream_error('fraud', check)
    work(20, 60)  # the bank
    if random.random() < BANK_FAILURE_RATE:
        log.error('order %s: bank gateway did not answer', payment['order'])
        return flask.jsonify(error='bank gateway unavailable'), 503
    return flask.jsonify(order=payment['order'], status='charged')
