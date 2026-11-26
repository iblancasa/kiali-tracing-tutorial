"""pricing: list prices, minus whatever promotions says today."""
import flask

from .common import call, create_app, upstream_error, work

app = create_app('pricing')

LIST_PRICES = {'margherita': 8.5, 'diavola': 10.0, 'quattro-formaggi': 11.0, 'hawaiian': 10.5}


@app.route('/prices')
def prices():
    work(2, 6)
    promotions = call('GET', 'promotions', '/promotions')
    if promotions.status_code != 200:
        return upstream_error('promotions', promotions)
    discounts = promotions.json()
    return flask.jsonify({
        pizza: {'list_price': price, 'price': round(price * (100 - discounts.get(pizza, 0)) / 100, 2)}
        for pizza, price in LIST_PRICES.items()
    })
