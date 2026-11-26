"""reviews: what people say about each pizza.

Two versions run side by side from the same code. v1 returns text only.
v2 (RATINGS_ENABLED=true) also asks the ratings service for stars."""
import os

import flask

from .common import call, create_app, upstream_error, work

app = create_app('reviews')

RATINGS_ENABLED = os.environ.get('RATINGS_ENABLED', 'false').lower() == 'true'
VERSION = os.environ.get('VERSION', 'v1')

REVIEWS = {
    'margherita': ['The one to judge a pizzeria by'],
    'diavola': ['Hot. Properly hot'],
    'quattro-formaggi': ['Four cheeses, zero regrets'],
    'hawaiian': ['I will not apologise', 'Why'],
}


@app.route('/reviews')
def reviews():
    work(3, 10)
    stars = {}
    if RATINGS_ENABLED:
        ratings = call('GET', 'ratings', '/ratings')
        if ratings.status_code != 200:
            return upstream_error('ratings', ratings)
        stars = ratings.json()
    response = flask.jsonify({
        pizza: [{'text': text, 'stars': stars.get(pizza)} for text in texts]
        for pizza, texts in REVIEWS.items()
    })
    response.headers['x-reviews-version'] = VERSION
    return response
