#!/usr/bin/env bash
# Record the terminal sessions of the tutorial website, then convert them to
# the .txt transcripts the <Terminal> component renders (site/src/terminals/).
#
# Needs: asciinema >= 3 and a cluster fresh from `make prepare` (the demo not
# deployed yet). Walks through steps 2, 3 and 4 and leaves the cluster at the
# end of step 4. Takes about 15 minutes.
#
# Usage: ./scripts/record-casts.sh [cast-name ...]   (no args = all, in order)
set -euo pipefail
cd "$(dirname "$0")/.."
TERMS=$PWD/site/src/terminals
mkdir -p "$TERMS"

# rec <name> <<'CAST' ... shell lines ... CAST
# Each line is echoed with a prompt, then executed, so the cast reads like a
# real session without typing noise.
rec() {
  local name=$1 script
  script=$(mktemp)
  {
    echo 'set -e'
    while IFS= read -r line; do
      [ -z "$line" ] && { echo 'echo'; continue; }
      printf 'printf "\\033[1;32m$\\033[0m %%s\\n" %q\n' "$line"
      echo "$line"
      echo 'sleep 0.8'
    done
  } > "$script"
  echo "== recording $name"
  asciinema rec --overwrite --quiet -f asciicast-v2 -i 2 --window-size 120x24 \
    -c "bash $script" "$TERMS/$name.cast"
  rm -f "$script"
}

ARGS=("$@")
# w <name>: true when no names were given, or <name> is one of them
w() { [ ${#ARGS[@]} -eq 0 ] || [[ " ${ARGS[*]} " == *" $1 "* ]]; }
# On a full run, give the proxies and the Collector time to deliver the spans
# of the new pods before the next recording looks at them.
settle() { [ ${#ARGS[@]} -gt 0 ] || sleep "$1"; }

w check && rec check <<'CAST'
make check
CAST

w status && rec status <<'CAST'
make status
make urls
CAST

# Step 2
w deploy && { rec deploy <<'CAST'
make deploy-apps 2>&1 | grep -v '^Waiting'
kubectl get pods -n demo
CAST
settle 90; }

w traffic && rec traffic <<'CAST'
kubectl -n loadgen logs deployment/loadgen --tail=8
make order
CAST

w sidecar && rec sidecar <<'CAST'
kubectl -n demo get pod -l app=orders -o jsonpath='{range .items[0].spec.initContainers[*]}{.name}{"\n"}{end}{range .items[0].spec.containers[*]}{.name}{"\n"}{end}'
CAST

w promql && rec promql <<'CAST'
curl -s localhost:9090/api/v1/query --data-urlencode 'query=sum by (destination_workload, response_code) (rate(istio_requests_total{reporter="destination", destination_workload_namespace="demo", response_code=~"5.."}[2m])) > 0' | jq -r '.data.result[] | "\(.metric.destination_workload)\tHTTP \(.metric.response_code)\t\(.value[1] | tonumber * 100 | round / 100) req/s"'
CAST

# Step 3
w broken && rec broken <<'CAST'
scripts/traces.py --lines 5
scripts/traces.py orders.demo --lines 5 --show 1
CAST

w propagate && { rec propagate <<'CAST'
make propagate 2>&1 | grep -v '^Waiting'
CAST
settle 75; }

w propagated && rec propagated <<'CAST'
scripts/traces.py --minutes 1 --lines 5 --show 1
CAST

# Step 4
w unpropagate && { rec unpropagate <<'CAST'
make unpropagate 2>&1 | grep -v '^Waiting' | tail -4
CAST
settle 75; }

w rebroken && rec rebroken <<'CAST'
scripts/traces.py --minutes 1 --lines 3
CAST

w instrument && { rec instrument <<'CAST'
make instrument 2>&1 | grep -v '^Waiting'
CAST
# Old pods take a while to go away; the next recording looks at the new ones.
kubectl -n demo wait --for=delete pod -l app=orders,pod-template-hash!="$(kubectl -n demo get rs -l app=orders --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.labels.pod-template-hash}')" --timeout=120s >/dev/null 2>&1 || true
settle 75; }

w injected && rec injected <<'CAST'
kubectl -n demo get pod -l app=orders -o jsonpath='{range .items[0].spec.initContainers[*]}{.name}{"\n"}{end}'
kubectl -n demo get pod -l app=orders -o jsonpath='{range .items[0].spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}' | grep -E 'PYTHONPATH|OTEL_(SERVICE_NAME|TRACES_EXPORTER|EXPORTER_OTLP|PROPAGATORS|PYTHON)'
CAST

w instrumented && rec instrumented <<'CAST'
scripts/traces.py --minutes 1 --lines 5 --show 1
CAST

python3 scripts/casts-to-text.py
ls "$TERMS"
