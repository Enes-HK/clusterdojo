# ClusterDojo

Hands-on Kubernetes administration practice on your own machine: real kubeadm clusters in Docker, a browser terminal next to the tasks, automatic grading per check, and a solution with explanation for every task.

- **Two mock exams with 16 tasks each.** Each takes about 2 hours: troubleshooting, cluster setup, networking, workloads and storage
- **4 clusters** (Kubernetes 1.37 via [kind](https://kind.sigs.k8s.io/)), with broken kubelets, control plane components and add-ons to repair
- **A terminal machine:** you start on `base` and `ssh` into each instance, with a 120-minute timer
- **Per-task stopwatch** with a target time, so you see where your minutes go
- **Graded per check** (✔/✘ with the reason), then *Solution and explanation* for each task
- Runs completely on your machine. No account, no cloud.

> ClusterDojo is an independent, free community project. It isn't affiliated with, endorsed by or connected to the Linux Foundation or the CNCF. The tasks are original scenarios written with Claude Code. They cover the topics listed in the public [CKA curriculum](https://github.com/cncf/curriculum) and aren't taken from or based on any exam.

## About this project
>**Disclaimer**:\
**This repo does not contain actual exam content and was purely made/generated with Claude Code**

I wanted to create this project and use it to practice and prepare myself for the CKA Exam. This public version is a rebuild with new tasks, written only from the public curriculum.

Going through other mock exams and redoing them didnt feel like I was actually learning how to do X, but rather I learned how to solve this specific question.\
That is why I wanted to have more exam like practice, where you actually have to troubleshoot instead of just repeating the same questions.\
And since I couldn't find a free one that was similiar to other high quality ones that I had already done, I decided to use **the power of AI** to help me learn and have it generate questions/scenarios for me, since writing my own troubleshooting question didn't make any sense.

I also recreated a similiar copy/pasting restriction, since you are on a [remote desktop VM during the exam](https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad). And my muscle memory of copy/pasting everything with **CTRL SHIFT V** was losing me time and nerves.\
But learning that you basically have two clipboards to store data in can become very useful if you learn how to deal with it.\
Copying variables out of the question that you will probably paste more than once (e.g. namespace) and copying with the basic linux selection (**M3 to paste**) in the actual terminal became a good tool to save some time.\
I already know that I could've configured the copy&paste setting in the terminal, but this still is how I chose to do it.


#### My copy&paste Tip:
- Copying out of the question or inside the VM with **CTRL SHIFT C**\
(you mostly copy variables with just a leftclick on the text, similiar to other mock exams)\
    -> Pasting with **CTRL SHIFT V**
- Copying/Selecting Text inside the terminal with **double leftclick** (like you usually do in linux environments)\
    -> Pasting with **M3** (Scrollwheel button)

The rest of this repo was made with Claude.\
If you find any bugs or have some suggestions, feel free to [open an issue](../../issues).

This concludes any human written Text btw. 

**Have fun and good luck with the Exam!**

## Requirements

- One of:
    - **Windows 10/11** with [Docker Desktop](https://www.docker.com/products/docker-desktop/) (WSL 2 backend)
    - **macOS** (Intel or Apple Silicon) with [Docker Desktop](https://www.docker.com/products/docker-desktop/)
    - **Linux** (x86-64 or ARM64) with [Docker Engine](https://docs.docker.com/engine/install/) (your user in the `docker` group) or Docker Desktop
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) on your `PATH`, e.g. `winget install Kubernetes.kind` (Windows) or `brew install kind` (macOS)
- Docker with about **10 GB of memory** (Docker Desktop → Settings → Resources) and ~15 GB of free disk
- Internet on the first start (images and add-ons)
- A desktop browser: Chrome, Edge or Firefox, also on macOS. Safari isn't supported, because its clipboard rules break pasting into the terminal

**Linux only:** 4 kind clusters need higher inotify limits than most distributions have by default. `start.sh` checks them and prints the command to raise them if needed (`fs.inotify.max_user_instances=512`, `fs.inotify.max_user_watches=524288`).

Linux and macOS have seen less testing than Windows. If something doesn't work, please [open an issue](../../issues).

## Start / stop / reset

On Windows, double-click the `.cmd` files in the repository folder. On Linux and macOS, run the `.sh` scripts from a terminal in the repository folder:

| Windows | Linux / macOS | |
|---|---|---|
| `start.cmd` | `./start.sh` | Start, or resume where you left off. The first start builds two images, creates 4 clusters and prepares Mock 1 (~10–15 min) |
| `stop.cmd` | `./stop.sh` | Pause: frees RAM, keeps your progress |
| `reset.cmd` | `./reset.sh` | Start from scratch: new images and clusters. Progress is lost, earlier scores are kept |

The UI opens at **http://localhost:8484**. The terminal alone is at http://localhost:7681. Both only listen on `localhost`.

**Running it on another machine** (e.g. a Linux server or VM) and practising from your laptop: open an SSH tunnel from the laptop and use the same address there. The terminal has no login, so don't expose the ports to the network.

```bash
ssh -L 8484:localhost:8484 -L 7681:localhost:7681 you@that-machine
```

Then open http://localhost:8484 on the laptop. Browsers only let a page read the clipboard on `localhost` or `https`, so this also keeps Ctrl+Shift+V working.

ClusterDojo never touches other kind clusters on your machine. It only uses the clusters `dojo1`–`dojo4` and the container `dojo-terminal`.

## How it works

- You start on `student@base`. Each task shows the instance to use: `ssh dojo1` … `ssh dojo4`, workers as `ssh dojo1-node1`, `dojo1-node2`, `dojo2-node1`, `dojo3-node1`.
- On every instance: `sudo -i` for root, `k` = kubectl with completion, vim with 2-space indent.
- Answer files go to `/home/student/answers/<task>/` on the instance the task names, e.g. `/home/student/answers/m1-06/`.
- **Clipboard:** copy from the task and paste into the terminal with **Ctrl+Shift+V** on every OS; on macOS **Cmd+Shift+V** works too. **Right-click → Paste** works too and needs no browser permission. Ctrl+V and Cmd+V don't paste there. If your browser asks whether `localhost` may read the clipboard, allow it. If the browser can't read the clipboard at all (e.g. a page opened by IP address), Ctrl+Shift+V opens a small paste box: paste into it with Cmd+V / Ctrl+V and the text goes to the terminal.
- **Stopwatch** (⏱ bottom left): only the open task counts. Switching pauses it, coming back resumes it. It turns red past the target time. ⏸ pauses, ↺ resets it for that task.
- **End mock** grades everything. Scores are saved in `exam/results/` as `.md` and `.json`, including the time per task.
- The clusters stay as they are after grading, so you can keep working on what you missed. **Check this task** then grades just the open task and shows its solution.

### Switching mocks

Before you start the timer, and after you end a mock, the header shows **Switch to Mock 2** (or 1) and **Mock N again**. Both first put the clusters back into a clean state (repaired nodes, control planes and add-ons), then set up every task of that mock. That takes about 5–10 minutes. The UI shows a notice meanwhile and opens the mock when it's ready.

Each mock keeps its own timer, and scores are saved per mock.

## Mock 1

| # | Task | Instance | Target |
|---|---|---|---|
| 1 | Node NotReady | dojo3 | 6 min |
| 2 | Control plane keeps restarting | dojo4 | 8 min |
| 3 | Three Service repairs | dojo2 | 9 min |
| 4 | A Pod that keeps restarting | dojo1 | 6 min |
| 5 | Which Pod owns this container? | dojo3 | 5 min |
| 6 | etcd snapshot | dojo2 | 5 min |
| 7 | A new user with a client certificate | dojo1 | 10 min |
| 8 | Kustomize overlay with generated config | dojo2 | 8 min |
| 9 | A Namespace stuck in Terminating | dojo3 | 6 min |
| 10 | NetworkPolicy across Namespaces | dojo1 | 9 min |
| 11 | Gateway API redirects, rewrites and headers | dojo1 | 9 min |
| 12 | Forward a private DNS domain | dojo2 | 7 min |
| 13 | Init container, sidecar, Secret and probe | dojo2 | 10 min |
| 14 | A stuck rollout | dojo1 | 6 min |
| 15 | Spread a Deployment over zones | dojo1 | 6 min |
| 16 | Get a deleted claim's data back | dojo3 | 6 min |

## Mock 2

| # | Task | Instance | Target |
|---|---|---|---|
| 1 | Node NotReady, two faults | dojo3-node1 | 7 min |
| 2 | New Pods never start | dojo4 | 5 min |
| 3 | Only new Services fail | dojo3 | 6 min |
| 4 | kubectl top doesn't work | dojo2 | 6 min |
| 5 | Tolerations, a missing scheduler and a waiting Pod | dojo2 | 7 min |
| 6 | Helm values, rollback and versions | dojo2 | 7 min |
| 7 | A pipeline gets 403 Forbidden | dojo4 | 7 min |
| 8 | A leaked join token | dojo3 | 5 min |
| 9 | A Pod that keeps coming back | dojo1 | 5 min |
| 10 | Gateway with TLS and weighted routes | dojo1 | 12 min |
| 11 | Lock down outgoing traffic | dojo2 | 7 min |
| 12 | A route across three Namespaces | dojo1 | 6 min |
| 13 | Sidecar and config file | dojo1 | 7 min |
| 14 | Take a node out for maintenance | dojo1 | 7 min |
| 15 | Tame a CronJob | dojo1 | 6 min |
| 16 | Static volumes and StorageClass | dojo2 | 9 min |

### Set one task up again

```bash
docker exec dojo-terminal bash /root/exam/mock2/14-node-maintenance/setup.sh
```

Tasks that break a node, a control plane component or an add-on are only fully reset by switching mocks or **Mock N again**, which repair the clusters first.

## Instances

| Instance | Nodes | Add-ons |
|---|---|---|
| dojo1 | control plane + 2 workers | Gateway API, NGINX Gateway Fabric |
| dojo2 | control plane + 1 worker | metrics-server, Helm repository `http://charts.acme:8879` |
| dojo3 | control plane + 1 worker | |
| dojo4 | control plane only | |

The Helm repository is served by the terminal container.

**Not covered:** upgrading a node with apt and joining a new node with kubeadm can't be simulated on kind nodes.

## Troubleshooting

- **After a Docker restart** the UI is gone: run `start.cmd` / `./start.sh` again. It restarts the clusters and the terminal container. If Pods on one cluster can't reach another node (e.g. `kubectl top` fails or Namespaces hang in `Terminating`), restart kindnet: `kubectl -n kube-system delete pod -l app=kindnet` on that cluster.
- **The UI keeps saying the mock is being prepared:** the log is in `exam/state/prepare.log`, one log per task in `exam/state/setup-m<N>-*.log`. If the preparation was interrupted (e.g. Docker stopped), delete `exam/state/preparing` and run the start script again.
- **Paste doesn't work in the terminal:** use Ctrl+Shift+V (macOS: also Cmd+Shift+V) or right-click → Paste. Ctrl+Shift+V either pastes the text or opens the paste box. Use Chrome, Edge or Firefox. If neither happens, reload the page with Ctrl+Shift+R / Cmd+Shift+R. After a `git pull`, run the start script again so the terminal loads the current clipboard script.
- **Linux: `Permission denied` on files in `exam/`** (written by the container as root, e.g. when it was started without `start.sh`): `sudo chown -R $USER: exam`.

## Contributing and checking the graders

Every task is a folder `exam/mockN/NN-topic/` with four files:

- `question.md`: the task, with front matter (`title`, `host`, `docs`, and `setup: last` for tasks that break a node, a control plane component or an add-on) and a `> Target: N minutes` line
- `setup.sh`: prepares or breaks the cluster. It has to be safe to run again
- `grade.sh`: prints one `PASS|check` or `FAIL|check|reason` line per check
- `solution.md`: the solution and the traps

plus a reference solution `exam/tests/solve/mN-NN.sh` (**spoilers**). `exam/tests/verify.sh` proves a task works: setup → grade (must fail) → solve → grade (must be full) → setup → grade → solve.

```bash
docker exec -e M=1 dojo-terminal bash /root/exam/tests/verify.sh 4 14     # tasks 4 and 14 of mock 1
docker exec -e M=2 dojo-terminal bash /root/exam/tests/verify.sh all      # all of mock 2
```

`exam/bin/heal.sh` undoes every node, control plane and add-on fault. `exam/bin/prepare-mock.sh N` runs it and then every setup of mock N.

Helpers for setup and grade scripts are in `exam/bin/lib.sh` (`kc <cluster>`, `hc`, `on <host>`, `answers`, `put`, `pass`/`fail`, `probe`, `wait_for`, `live`).

## License

[MIT](LICENSE). Feedback and new tasks are welcome as issues or pull requests.
