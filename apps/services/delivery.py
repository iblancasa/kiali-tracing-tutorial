"""delivery: books a rider. Needs a route from maps to give an ETA."""
import flask

from .common import call, create_app, upstream_error, work

app = create_app('delivery')


@app.route('/deliveries', methods=['POST'])
def deliveries():
    delivery = flask.request.get_json()
    work(3, 10)
    route = call('GET', 'maps', '/route', params={'to': delivery['address']})
    if route.status_code != 200:
        return upstream_error('maps', route)
    return flask.jsonify(order=delivery['order'], minutes=route.json()['minutes'])
