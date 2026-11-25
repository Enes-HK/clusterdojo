**What this tests:** how a Service finds its Pods, why a running Pod can still get no traffic, and what to do when a Service can't use a selector.

**1. No endpoints.** Every label in a Service selector must match, so extra labels narrow it. Compare the two:

```bash
k -n support get svc helpdesk -o jsonpath='{.spec.selector}'    # app=helpdesk, tier=backend
k -n support get pods --show-labels                        # app=helpdesk, version=v1
k -n support edit svc helpdesk                                  # delete tier: backend
k -n support get endpointslices -l kubernetes.io/service-name=helpdesk
```

**2. Running but not ready.** A Service only sends traffic to Pods that are *ready*. The Pod shows `0/1 Running`, and the slice lists it with `ready: false`. The events say why:

```bash
k -n support get pods -l app=reporter                        # 0/1 Running
k -n support describe pod -l app=reporter | grep -A3 Readiness  # http-get :8081 ... connection refused
k -n support get deploy reporter -o yaml | grep -B2 -A6 'containerPort\|readinessProbe'
k -n support edit deploy reporter                            # readinessProbe.httpGet.port: 8080
k -n support get endpointslices -l kubernetes.io/service-name=reporter
```

The app listens on `8080`, but the probe asks `8081`, so it never passes. Point the probe at the real port. Deleting the probe would also make the Pod ready, but the task says to keep it.

**3. Service without a selector.** With no selector, nothing fills in endpoints for you, so you write the EndpointSlice yourself. The label connects it to the Service, and the port name must match the Service's.

```bash
k -n external get pod remote-db -o wide       # the IP
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: warehouse-db
  namespace: support
spec:
  ports:
  - name: db
    port: 3306
    targetPort: 9500
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: warehouse-db-1
  namespace: support
  labels:
    kubernetes.io/service-name: warehouse-db     # this links it to the Service
addressType: IPv4
ports:
- name: db                                      # same name as the Service port
  port: 9500
  protocol: TCP
endpoints:
- addresses:
  - <the IP>
```

**Traps**
- The EndpointSlice `ports` value is the real backend port, `9500`. The Service's `3306` is what clients use.
- If the Service port has a name, the slice's port needs the same name.
- A probe on a Pod can't be edited in place. Change the Deployment, which rolls out a new Pod.
