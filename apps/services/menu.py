"""menu: the list of pizzas, with today's prices and what people say."""
import flask

from .common import call, create_app, upstream_error, work

app = create_app('menu')

PIZZAS = [
    {'id': 'margherita', 'name': 'Margherita'},
    {'id': 'diavola', 'name': 'Diavola'},
    {'id': 'quattro-formaggi', 'name': 'Quattro formaggi'},
    {'id': 'hawaiian', 'name': 'Hawaiian'},
]


@app.route('/menu')
def menu():
    work(3, 10)
    prices = call('GET', 'pricing', '/prices')
    if prices.status_code != 200:
        return upstream_error('pricing', prices)
    reviews = call('GET', 'reviews', '/reviews')
    if reviews.status_code != 200:
        return upstream_error('reviews', reviews)
    prices, reviews = prices.json(), reviews.json()
    return flask.jsonify(pizzas=[
        {**pizza, **prices[pizza['id']], 'reviews': reviews.get(pizza['id'], [])}
        for pizza in PIZZAS
    ])
