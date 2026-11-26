"""orders: takes an order through its whole life. Reserve the ingredients,
charge the card, tell the kitchen, book a rider, tell the customer."""
import logging
import uuid

import flask

from .common import call, create_app, upstream_error, work

app = create_app('orders')
log = logging.getLogger('orders')


@app.route('/orders', methods=['POST'])
def create_order():
    order = flask.request.get_json()
    order_id = uuid.uuid4().hex[:8]
    work(3, 10)

    reserved = call('POST', 'inventory', '/reserve', json=order)
    if reserved.status_code != 200:
        return upstream_error('inventory', reserved)

    charged = call('POST', 'payments', '/charge', json={'order': order_id, 'qty': order['qty']})
    if charged.status_code != 200:
        # Give the ingredients back, the pizza is not going to happen.
        call('POST', 'inventory', '/release', json=order)
        log.warning('order %s cancelled: payments answered %s', order_id, charged.status_code)
        return upstream_error('payments', charged)

    ticket = call('POST', 'kitchen', '/tickets', json={'order': order_id, **order})
    if ticket.status_code != 200:
        return upstream_error('kitchen', ticket)

    delivery = call('POST', 'delivery', '/deliveries', json={'order': order_id, 'address': order['address']})
    if delivery.status_code != 200:
        return upstream_error('delivery', delivery)

    eta = ticket.json()['minutes'] + delivery.json()['minutes']
    call('POST', 'notifications', '/notify', json={'order': order_id, 'eta_minutes': eta})
    log.info('order %s confirmed pizza=%s eta=%smin', order_id, order['pizza'], eta)
    return flask.jsonify(order=order_id, eta_minutes=eta)
