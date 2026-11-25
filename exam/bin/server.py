#!/usr/bin/env python3
"""ClusterDojo exam server: serves the UI and the tasks of the selected mock, runs the graders and stores results."""
import json
import os
import re
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

import markdown

EXAM = "/root/exam"
MOCKS = ("1", "2")
RESULTS = f"{EXAM}/results"
DURATION_MIN = 120
STATE_LOCK = threading.Lock()


def md(text):
    # python-markdown needs a blank line before a list (GitHub doesn't); add it, but never inside code fences
    out, fenced, prev = [], False, ""
    for line in text.splitlines():
        if line.startswith("```"):
            fenced = not fenced
        is_item = re.match(r"\s*([-*]|\d+\.) ", line)
        prev_item = re.match(r"\s*([-*]|\d+\.) ", prev) or prev.startswith("  ")
        if not fenced and is_item and prev.strip() and not prev_item:
            out.append("")
        out.append(line)
        prev = line
    return markdown.markdown("\n".join(out), extensions=["fenced_code", "tables"])


def mock():
    # state/mock.txt: the mock that is prepared on the clusters (prepare-mock.sh writes it), "1" by default
    try:
        m = open(f"{EXAM}/state/mock.txt").read().strip()
        return m if m in MOCKS else "1"
    except Exception:
        return "1"


def qdir():
    return f"{EXAM}/mock{mock()}"


def state_file():
    # every mock has its own timer and stopwatches
    return f"{EXAM}/state/exam-m{mock()}.json"


def load_questions():
    base = qdir()
    qs = []
    for i, d in enumerate(sorted(os.listdir(base)), start=1):
        raw = open(f"{base}/{d}/question.md", encoding="utf-8").read()
        meta, body = {}, raw
        m = re.match(r"^---\n(.*?)\n---\n(.*)$", raw, re.S)
        if m:
            body = m.group(2)
            for line in m.group(1).splitlines():
                k, _, v = line.partition(":")
                meta[k.strip()] = v.strip()
        docs = []
        for part in filter(None, (p.strip() for p in meta.get("docs", "").split(" ; "))):
            url, _, label = part.partition(" | ")
            docs.append({"url": url.strip(), "label": label.strip() or url.strip()})
        sol = f"{base}/{d}/solution.md"
        qs.append({
            "n": i, "label": f"Task {i}", "path": f"{base}/{d}",
            "dir": d, "title": meta.get("title", d), "host": meta.get("host", ""),
            "docs": docs, "html": md(body),
            "solution": md(open(sol, encoding="utf-8").read()) if os.path.exists(sol) else "",
        })
    return qs


def give_back(*paths):
    # Linux hosts (start.sh sets HOST_UID/HOST_GID): files written into the mounted exam/ belong to the user, not root
    uid = os.environ.get("HOST_UID")
    if not uid:
        return
    for p in paths:
        try:
            os.chown(p, int(uid), int(os.environ.get("HOST_GID", uid)))
        except (OSError, ValueError):
            pass


def read_state():
    try:
        return json.load(open(state_file()))
    except Exception:
        return {}


def write_state(s):
    path = state_file()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(s, f)
    give_back(os.path.dirname(path), path)


def grade_one(q):
    try:
        p = subprocess.run(["bash", f"{q['path']}/grade.sh"], capture_output=True, text=True, timeout=180)
        out = p.stdout
    except subprocess.TimeoutExpired as e:
        out = (e.stdout or b"").decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        out += "\nFAIL|Grader timed out|"
    checks = []
    for line in out.splitlines():
        parts = line.split("|", 2)
        if parts[0] in ("PASS", "FAIL") and len(parts) >= 2:
            checks.append({"ok": parts[0] == "PASS", "text": parts[1], "hint": parts[2] if len(parts) > 2 else ""})
    if not checks:
        checks.append({"ok": False, "text": "Grader produced no result", "hint": out[-300:]})
    return {"n": q["n"], "label": q["label"], "title": q["title"], "host": q["host"], "checks": checks,
            "got": sum(c["ok"] for c in checks), "of": len(checks)}


def score():
    qs = load_questions()
    with ThreadPoolExecutor(max_workers=6) as ex:
        res = list(ex.map(grade_one, qs))
    got, of = sum(r["got"] for r in res), sum(r["of"] for r in res)
    st = read_state()
    for r in res:
        r["seconds"] = round(st.get("qtimes", {}).get(str(r["n"]), 0))
    result = {"time": datetime.now().strftime("%Y-%m-%d %H:%M"), "mock": mock(), "got": got, "of": of,
              "percent": round(100 * got / of) if of else 0, "questions": res,
              "started_at": st.get("started_at"), "ended_at": st.get("ended_at")}
    os.makedirs(RESULTS, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M") + f"-mock{mock()}"
    with open(f"{RESULTS}/score-{stamp}.json", "w") as f:
        json.dump(result, f, indent=1)
    lines = [f"# ClusterDojo — Mock {mock()}, score {result['time']}", "",
             f"**{got} / {of} subtasks = {result['percent']} %**", "",
             "| # | Topic | Score | Time |", "|---|---|---|---|"]
    lines += [f"| {r['n']} | {r['title']} | {r['got']}/{r['of']} | {mmss(r['seconds'])} |" for r in res]
    lines += ["", "## Details", ""]
    for r in res:
        lines += [f"### {r['label']} | {r['title']} — {r['got']}/{r['of']}", ""]
        lines += [f"- {'✅' if c['ok'] else '❌'} {c['text']}" + (f" — _{c['hint']}_" if c["hint"] and not c["ok"] else "")
                  for c in r["checks"]]
        lines.append("")
    with open(f"{RESULTS}/score-{stamp}.md", "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    give_back(RESULTS, f"{RESULTS}/score-{stamp}.json", f"{RESULTS}/score-{stamp}.md")
    with STATE_LOCK:
        st = read_state()
        st["scored_at"] = time.time()
        write_state(st)
    return result


def mmss(sec):
    return f"{sec // 60}:{sec % 60:02d}" if sec else "–"


class H(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else (json.dumps(body) if ctype == "application/json" else body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype + "; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            return self.send(200, open(f"{EXAM}/ui/index.html", "rb").read(), "text/html")
        if self.path == "/api/exam":
            st = read_state()
            qs = load_questions()
            ended = bool(st.get("ended_at"))
            for q in qs:
                if not ended:
                    q["solution"] = ""
            ready = os.path.exists(f"{EXAM}/state/setup-done") and not os.path.exists(f"{EXAM}/state/preparing")
            return self.send(200, {"questions": qs, "mock": mock(), "mocks": list(MOCKS), "state": st,
                                   "duration_min": DURATION_MIN, "ready": ready,
                                   "preparing": os.path.exists(f"{EXAM}/state/preparing"), "now": time.time()})
        if self.path == "/api/results/latest":
            files = sorted(f for f in os.listdir(RESULTS) if f.endswith(f"-mock{mock()}.json")) if os.path.isdir(RESULTS) else []
            return self.send(200, json.load(open(f"{RESULTS}/{files[-1]}")) if files else {})
        self.send(404, {"error": "not found"})

    def do_POST(self):
        if self.path == "/api/score":
            return self.send(200, score())
        with STATE_LOCK:
            st = read_state()
            if self.path == "/api/start":
                if not st.get("started_at"):
                    st["started_at"] = time.time()
                    write_state(st)
                return self.send(200, st)
            if self.path == "/api/end":
                if not st.get("ended_at"):
                    st["ended_at"] = time.time()
                    write_state(st)
                return self.send(200, st)
            if self.path == "/api/qtime":
                # time spent per question: {"n": 3, "add": 12.5} adds seconds, {"n": 3, "reset": true} clears it
                try:
                    body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
                    n = str(int(body["n"]))
                except Exception:
                    return self.send(400, {"error": "bad request"})
                qt = st.setdefault("qtimes", {})
                if body.get("reset"):
                    qt.pop(n, None)
                else:
                    qt[n] = qt.get(n, 0) + max(0.0, min(float(body.get("add", 0)), 600.0))
                write_state(st)
                return self.send(200, qt)
            m = re.fullmatch(r"/api/mock/(\d+)", self.path)
            if m:
                # prepare a mock (the other one, or the same one again for a new attempt); not while a timer runs
                running = st.get("started_at") and not st.get("ended_at")
                if m.group(1) not in MOCKS or running or os.path.exists(f"{EXAM}/state/preparing"):
                    return self.send(409, {"error": "not now"})
                open(f"{EXAM}/state/preparing", "w").write(str(time.time()))
                with open(f"{EXAM}/state/prepare.log", "w") as log:
                    subprocess.Popen(["bash", f"{EXAM}/bin/prepare-mock.sh", m.group(1)], stdout=log, stderr=log,
                                     start_new_session=True)
                return self.send(200, {"preparing": True})
        m = re.fullmatch(r"/api/check/(\d+)", self.path)
        if m and st.get("ended_at"):
            q = next((x for x in load_questions() if x["n"] == int(m.group(1))), None)
            if q:
                return self.send(200, {**grade_one(q), "solution": q["solution"]})
        self.send(404, {"error": "not found"})


if __name__ == "__main__":
    print("exam server on :8080", flush=True)
    ThreadingHTTPServer(("0.0.0.0", 8080), H).serve_forever()
