from time import sleep
import flask
import random

app = flask.Flask(__name__)

@app.route('/')
def bye():
    # Simulate some work
    sleep(0.15)
    if random.random() < 0.3:
        return flask.Response("bye")
    else:
        return flask.Response("error", status=500)


if __name__ == "__main__":
    app.run()
