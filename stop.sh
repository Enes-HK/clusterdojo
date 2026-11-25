#!/usr/bin/env bash
# Pauses ClusterDojo to free RAM/CPU. ./start.sh resumes it with your progress intact.   (Windows: stop.cmd)
docker rm -f dojo-terminal >/dev/null 2>&1
for c in dojo1 dojo2 dojo3 dojo4; do
  for id in $(docker ps -q --filter "label=io.x-k8s.kind.cluster=$c"); do docker stop "$id" >/dev/null; done
done
echo "Stopped."
