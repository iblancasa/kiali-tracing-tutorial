"""kitchen: turns an order into a ticket for the cooks."""
import random

import flask

from .common import call, create_app, upstream_error, work

app = create_app('kitchen')


@app.route('/tickets', methods=['POST'])
def tickets():
    ticket = flask.request.get_json()
    work(3, 10)
    recipe = call('GET', 'inventory', f"/ingredients/{ticket['pizza']}")
    if recipe.status_code != 200:
        return upstream_error('inventory', recipe)
    return flask.jsonify(order=ticket['order'], ingredients=recipe.json()['ingredients'],
                         minutes=random.randint(8, 14))
