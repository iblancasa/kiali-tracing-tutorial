#!/bin/sh
set -e
if [ "$SERVICE" = "loadgen" ]; then
  exec python -m services.loadgen
fi
exec waitress-serve --port 8080 --threads 16 "services.${SERVICE}:app"
