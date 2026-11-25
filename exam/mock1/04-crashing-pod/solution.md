**What this tests:** reading a crash after the fact. Which container instance `k logs` shows depends on what the Pod is doing right now, and the reason for the crash is in the Pod's status, not in the logs.

**1. Logs of the crashed instance**

```bash
k -n billing get pods                                    # RESTARTS > 0, READY 0/1, STATUS OOMKilled or CrashLoopBackOff
k -n billing get pod -l app=invoice-worker -o jsonpath='{.items[0].status.containerStatuses[0].state}'; echo
```

- `state` is `terminated`: the crashed instance is still the current one, and the kubelet waits (back-off) before it starts the next. Plain `k logs` shows it:
  ```bash
  k -n billing logs deploy/invoice-worker > /home/student/answers/m1-04/previous.log
  ```
- `state` is `running`: a new instance has already started, and the crashed one is now the previous one:
  ```bash
  k -n billing logs deploy/invoice-worker --previous > /home/student/answers/m1-04/previous.log
  ```

```bash
cat /home/student/answers/m1-04/previous.log             # starting ... loading open invoices, nothing after that
```

The kubelet keeps only one dead instance per container. While the crashed instance is still the current one, `--previous` points to the instance before it, which is already deleted: `unable to retrieve container logs`.

**2. Why it was terminated**

```bash
k -n billing describe pod -l app=invoice-worker | grep -A5 -E 'State|Last State'
#   Reason:    OOMKilled
#   Exit Code: 137
echo OOMKilled/137 > /home/student/answers/m1-04/termination
```

Exit code 137 is 128 + 9: the process got SIGKILL. With the reason `OOMKilled`, the kernel killed it because the container went over its memory limit.

**3. Give it enough memory**

```bash
k -n billing set resources deploy/invoice-worker -c worker --requests=memory=64Mi --limits=memory=128Mi
k -n billing rollout status deploy/invoice-worker
k -n billing get pods                                    # 1/1 Running, 0 restarts
k -n billing logs deploy/invoice-worker                  # ... waiting for jobs
```

**Traps**
- `unable to retrieve container logs` with `--previous`: the crashed instance is still the current one. Use `k logs` without `--previous`, and check the file isn't empty.
- `Error/1` is the usual guess. Read the `terminated` part of the status (`state` or `lastState`), not the Pod's STATUS column alone.
- Change the Deployment, not the Pod: the Deployment would replace an edited Pod anyway.
