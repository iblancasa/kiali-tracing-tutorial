#!/usr/bin/env bash
# Verify the tools needed for the tutorial.
# Usage: [CLUSTER=name] check-tools.sh [host-port ...]   (ports the kind config maps; warns if taken)
set -u
PORTS=("$@")
ok=1
need() {
  if command -v "$1" >/dev/null 2>&1; then
    printf "  [ok]   %-8s %s\n" "$1" "$($2 2>/dev/null | head -1)"
  else
    printf "  [MISS] %-8s %s\n" "$1" "$3"; ok=0
  fi
}
echo "Checking tools..."
need docker  "docker version --format {{.Server.Version}}" "https://docs.docker.com/get-docker/ (or colima / podman with docker CLI)"
need kubectl "kubectl version --client"                     "https://kubernetes.io/docs/tasks/tools/"
need helm    "helm version --short"                         "https://helm.sh/docs/intro/install/"
need curl    "curl --version"                               "install curl with your package manager"

if ! docker info >/dev/null 2>&1; then
  echo "  [MISS] docker daemon is not running"; ok=0
fi

# kind comes from the Makefile (bin/kind-<version>), not from the PATH.
KIND=${KIND:-kind}
if "$KIND" version >/dev/null 2>&1; then
  printf "  [ok]   %-8s %s\n" kind "$("$KIND" version | cut -d' ' -f1-2)"
else
  printf "  [MISS] %-8s %s\n" kind "run 'make check', which downloads it into bin/"; ok=0
fi

# The ports are only a problem before the cluster exists. Afterwards the
# cluster itself is the one listening on them.
if "$KIND" get clusters 2>/dev/null | grep -qx "${CLUSTER:-kiali-tracing}"; then
  echo "  [ok]   cluster  kind cluster ${CLUSTER:-kiali-tracing} already exists"
else
  for p in ${PORTS[@]+"${PORTS[@]}"}; do
    if lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "  [WARN] port $p is in use on this host. Free it, or use 'make port-forward' later."
    fi
  done
fi

[ $ok -eq 1 ] && echo "All good." || { echo "Install the missing tools and run 'make check' again."; exit 1; }
