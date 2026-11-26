"""fraud: decides if an order looks suspicious. Nobody steals pizza."""
import flask

from .common import create_app, work

app = create_app('fraud')


@app.route('/check', methods=['POST'])
def check():
    work(15, 40)
    return flask.jsonify(suspicious=False)
