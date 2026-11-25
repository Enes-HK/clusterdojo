#!/usr/bin/env bash
# Throws away the exam clusters and your progress, rebuilds the images and starts a fresh environment.
# Your earlier scores in exam/results are kept. Other kind clusters (not dojo1-dojo4) are not touched.   (Windows: reset.cmd)
cd "$(dirname "$0")" || exit 1
root=$PWD
docker rm -f dojo-terminal >/dev/null 2>&1
for c in dojo1 dojo2 dojo3 dojo4; do kind delete cluster --name "$c"; done
# exam/state may belong to root (written by the container on Linux): remove it from a container too
if docker image inspect clusterdojo/terminal:latest >/dev/null 2>&1; then
  docker run --rm --entrypoint rm -v "$root/exam:/root/exam" clusterdojo/terminal:latest -rf /root/exam/state
fi
rm -rf "$root/exam/state" 2>/dev/null
docker image rm clusterdojo/node:v1.37.0 clusterdojo/terminal:latest >/dev/null 2>&1
exec "$root/start.sh"
