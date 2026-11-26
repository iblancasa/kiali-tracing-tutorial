"""notifications: tells the customer the pizza is on its way."""
import logging

import flask

from .common import create_app, work

app = create_app('notifications')
log = logging.getLogger('notifications')


@app.route('/notify', methods=['POST'])
def notify():
    message = flask.request.get_json()
    work(2, 8)
    log.info('order %s: sms sent, eta %s min', message['order'], message['eta_minutes'])
    return flask.jsonify(sent=True)
