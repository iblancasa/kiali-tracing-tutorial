"""ratings: stars per pizza. Only reviews v2 calls it."""
import flask

from .common import create_app, work

app = create_app('ratings')


@app.route('/ratings')
def ratings():
    work(2, 8)
    return flask.jsonify({'margherita': 5, 'diavola': 4, 'quattro-formaggi': 5, 'hawaiian': 2})
