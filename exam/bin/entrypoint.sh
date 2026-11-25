#!/bin/bash
# Starts the exam services inside the terminal container.
cd /root/exam || exit 1
mkdir -p state results charts-repo
# Linux hosts (start.sh sets HOST_UID/HOST_GID): what this container wrote into the mounted exam/ belongs to the user
[ -n "${HOST_UID:-}" ] && chown -R "$HOST_UID:${HOST_GID:-$HOST_UID}" state results charts-repo kubeconfigs 2>/dev/null

# Helm chart repo "acme" (reachable from the nodes as http://charts.acme:8879)
python3 -m http.server 8879 -d /root/exam/charts-repo >/var/log/charts.log 2>&1 &

# Browser terminal, logged in as student on the main terminal. Its page gets ui/terminal-clipboard.js injected
# (exam-style copy/paste): take ttyd's built-in page from a throwaway instance and add the script before </body>.
ttyd -p 7682 -i lo true >/dev/null 2>&1 & tmp=$!
for _ in $(seq 50); do curl -sf http://localhost:7682/ -o /tmp/ttyd-default.html && break; sleep 0.1; done
kill $tmp 2>/dev/null
idx=()
python3 - <<'EOF' && idx=(-I /tmp/ttyd-index.html)
page = open("/tmp/ttyd-default.html", encoding="utf-8").read()
js = open("/root/exam/ui/terminal-clipboard.js", encoding="utf-8").read()
assert "</body>" in page
open("/tmp/ttyd-index.html", "w", encoding="utf-8").write(page.replace("</body>", f"<script>{js}</script></body>", 1))
EOF
ttyd -p 7681 -W "${idx[@]}" -t fontSize=15 -t 'theme={"background":"#1e1e1e"}' su - student >/var/log/ttyd.log 2>&1 &

exec python3 /root/exam/bin/server.py
