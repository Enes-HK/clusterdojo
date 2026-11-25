#!/usr/bin/env bash
# Starts ClusterDojo on Linux and macOS: images, 4 kind clusters, the terminal container, then opens the exam UI.
# Usage:  ./start.sh        (Windows: start.cmd)
set -u
cd "$(dirname "$0")" || exit 1
root=$PWD
clusters="dojo1 dojo2 dojo3 dojo4"
node_image=clusterdojo/node:v1.37.0
term_image=clusterdojo/terminal:latest
terminal=dojo-terminal
ui_port=8484

die() { echo "ERROR: $*" >&2; exit 1; }

for tool in docker kind ssh-keygen; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found. See README.md -> Requirements."
done
docker info >/dev/null 2>&1 \
  || die "Docker isn't running, or your user can't use it (check with: docker info). Start it and run ./start.sh again."

# Linux with Docker Engine: 4 kind clusters need more inotify instances than most distributions allow by default.
# Too few and Pods fail with "too many open files". (macOS: Docker Desktop's VM takes care of this.)
if [ "$(uname -s)" = Linux ] && [ -r /proc/sys/fs/inotify/max_user_instances ]; then
  inst=$(cat /proc/sys/fs/inotify/max_user_instances) watches=$(cat /proc/sys/fs/inotify/max_user_watches)
  if [ "$inst" -lt 512 ] || [ "$watches" -lt 524288 ]; then
    echo "Your inotify limits are too low for 4 kind clusters (max_user_instances=$inst, max_user_watches=$watches)."
    echo "Raise them, then run ./start.sh again:"
    echo "  sudo sysctl fs.inotify.max_user_instances=512 fs.inotify.max_user_watches=524288"
    echo "To keep them after a reboot:"
    echo "  printf 'fs.inotify.max_user_instances = 512\nfs.inotify.max_user_watches = 524288\n' | sudo tee /etc/sysctl.d/99-kind.conf"
    exit 1
  fi
fi

# SSH key shared by the terminal and all nodes: created on the first start, never committed
keys=$root/images/keys
rebuild=0
if [ ! -f "$keys/id_ed25519" ]; then
  echo "Creating the SSH key for the exam machines..."
  mkdir -p "$keys"
  ssh-keygen -q -t ed25519 -N '' -C clusterdojo -f "$keys/id_ed25519" || die "Couldn't create the SSH key."
  rebuild=1
fi

for pair in "$node_image node" "$term_image terminal"; do
  set -- $pair
  if [ "$rebuild" = 1 ] || ! docker image inspect "$1" >/dev/null 2>&1; then
    echo "Building the $2 image..."
    docker build -q -f "$root/images/$2/Dockerfile" -t "$1" "$root/images" >/dev/null || die "Building the $2 image failed."
  fi
done

existing=$(kind get clusters 2>/dev/null)
fresh=0
for c in $clusters; do
  if ! printf '%s\n' "$existing" | grep -qx "$c"; then
    echo "Creating cluster $c..."
    kind create cluster --name "$c" --config "$root/clusters/$c.yaml" --image "$node_image" --wait 120s \
      || die "Creating cluster $c failed."
    fresh=1
  else
    for id in $(docker ps -aq --filter "label=io.x-k8s.kind.cluster=$c"); do docker start "$id" >/dev/null; done
  fi
  kind get kubeconfig --internal --name "$c" > "$root/exam/kubeconfigs/$c" \
    || die "Couldn't read the kubeconfig of cluster $c."
done

# Local time in the exam UI and score files: the host's current UTC offset as a POSIX TZ string (UTC+1 -> <+0100>-01:00)
off=$(date +%z)
case $off in -*) posix=+ ;; *) posix=- ;; esac
tz="<$off>$posix${off:1:2}:${off:3:2}"

# Linux: files the container writes into exam/ (state, results) are handed back to your user, not left to root
owner=()
[ "$(uname -s)" = Linux ] && owner=(-e "HOST_UID=$(id -u)" -e "HOST_GID=$(id -g)")

docker rm -f "$terminal" >/dev/null 2>&1
# ${owner[@]+...}: macOS ships bash 3.2, where an empty array counts as unset under set -u
docker run -d --name "$terminal" --hostname terminal --network kind -e "TZ=$tz" ${owner[@]+"${owner[@]}"} \
  --network-alias charts.acme \
  -p "127.0.0.1:$ui_port:8080" -p 127.0.0.1:7681:7681 -v "$root/exam:/root/exam" "$term_image" >/dev/null \
  || die "Starting the terminal container failed (is port $ui_port or 7681 already in use?)."

# new clusters: every question has to be prepared again (inside the container, which owns exam/state)
[ "$fresh" = 1 ] && docker exec "$terminal" rm -f /root/exam/state/setup-done
if ! docker exec "$terminal" test -f /root/exam/state/setup-done; then
  echo "Preparing the clusters and the mock (first start takes ~10 minutes)..."
  docker exec "$terminal" bash /root/exam/bin/setup-all.sh
fi

url=http://localhost:$ui_port
if command -v open >/dev/null 2>&1 && [ "$(uname -s)" = Darwin ]; then open "$url"
elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$url" >/dev/null 2>&1 &
fi
echo "Exam UI: $url"
