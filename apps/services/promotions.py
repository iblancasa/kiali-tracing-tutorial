"""promotions: percentage off per pizza. The Hawaiian needs the help."""
import flask

from .common import create_app, work

app = create_app('promotions')


@app.route('/promotions')
def promotions():
    work(2, 6)
    return flask.jsonify({'hawaiian': 30, 'margherita': 10})
