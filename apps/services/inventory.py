"""inventory: how many of each pizza the kitchen can still make. The
counters live in Redis, the only thing in the shop that is not HTTP."""
import os

import flask
import redis

from .common import create_app, work

app = create_app('inventory')
store = redis.Redis(host=os.environ.get('REDIS_HOST', 'redis'), port=6379, decode_responses=True,
                    socket_timeout=2, socket_connect_timeout=2)

RESTOCK = 500
RECIPES = {
    'margherita': ['dough', 'tomato', 'mozzarella', 'basil'],
    'diavola': ['dough', 'tomato', 'mozzarella', 'salami', 'chili'],
    'quattro-formaggi': ['dough', 'mozzarella', 'gorgonzola', 'parmesan', 'fontina'],
    'hawaiian': ['dough', 'tomato', 'mozzarella', 'ham', 'pineapple'],
}


@app.route('/reserve', methods=['POST'])
def reserve():
    order = flask.request.get_json()
    key = f"stock:{order['pizza']}"
    work(1, 4)
    store.setnx(key, RESTOCK)
    left = store.decrby(key, order['qty'])
    if left < 0:
        # The supplier arrives instantly. It is a demo.
        store.set(key, RESTOCK)
        left = RESTOCK
    return flask.jsonify(pizza=order['pizza'], left=left)


@app.route('/release', methods=['POST'])
def release():
    order = flask.request.get_json()
    left = store.incrby(f"stock:{order['pizza']}", order['qty'])
    return flask.jsonify(pizza=order['pizza'], left=left)


@app.route('/ingredients/<pizza>')
def ingredients(pizza):
    work(1, 4)
    return flask.jsonify(pizza=pizza, ingredients=RECIPES.get(pizza, RECIPES['margherita']))
