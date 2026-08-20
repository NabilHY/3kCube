## Part 2: K3s and Three Simple Applications
 
This part drops the two-node setup entirely — a single Alpine VM running k3s in server mode, hosting three deployments behind one Ingress. The goal: route incoming requests to a different app purely based on the `Host` header.
 
### The request path
 
A request doesn't go straight to a pod. It passes through a fixed chain:
 
```
client → Ingress (Traefik) → Service:80 → Pod:8080
```
 
**Traefik** — the Ingress controller k3s ships with by default — is the component actually reading the `Host` header and deciding where a request goes. It's a real pod, listening and routing just like any other workload, not something baked invisibly into k3s itself.
 
Once Traefik decides "this goes to `app-one`," it forwards to the **Service**, not directly to a pod. That's the point of the three port fields you'll see in every manifest here:
 
| Field | Lives on | Purpose |
|---|---|---|
| `containerPort: 8080` | Pod | What the container process actually listens on |
| `targetPort: 8080` | Service | Which port on the pod to forward to |
| `port: 80` | Service | What the Service exposes to everything else in the cluster |
 
The Ingress backend only ever references the Service's `port: 80` — it never touches `targetPort` or `containerPort` directly. The Service is the only thing that knows how to translate 80 down to 8080 on the pod.
 
The other thing tying a Deployment to a Service is labels, not names. A Service continuously watches the cluster for pods matching its `selector` and populates its endpoint list from whatever matches. If that selector doesn't match any pod's labels, the Service isn't broken — it still exists, still has a ClusterIP — it just has zero endpoints to send traffic to. Anything routing through it (including Ingress) hits a dead end.
 
### Replicas: what "3 replicas" actually means
 
`app-two` runs `replicas: 3`. That doesn't mean three identical pods — pod names are unique within a namespace. What you actually get is three pods sharing a common ReplicaSet hash, each with its own random suffix:
 
```
app-two-6bc974bc98-qtjj7
app-two-6bc974bc98-nzwth
app-two-6bc974bc98-qhp0p
```
 
The **ReplicaSet** — not the Deployment directly — is what keeps exactly 3 of them alive at all times. The Deployment's job is one layer up: managing rollout strategy and versioning. If a pod dies, the ReplicaSet notices and replaces it; if you push a new image version, the Deployment creates a new ReplicaSet and hands off the transition.
 
### Ingress: a deliberately redundant rule
 
`04-ingress.yml` defines a `defaultBackend` pointing at `app-three`, and *also* an explicit `host: app3.com` rule pointing at the same place. That second rule is technically redundant — any host that doesn't match an explicit rule already falls through to the default backend, so removing the `app3.com` block entirely wouldn't change behavior at all. Kept here for explicitness, since the subject's diagram treats app3 as a named third app rather than purely "whatever's left over."
 
### `deployments.sh`: sleep vs. actually waiting
 
The provisioning script applies all manifests, then walks through pods → deployments → services → logs — but it gates every step with a hardcoded `sleep` (30s, then a string of 10s waits) instead of checking for actual readiness. That works, but it's a guess: it assumes every pod will be scheduled, image-pulled, and running inside that window. If it isn't, `kubectl logs -l app=app-one` won't retry or wait — it just fails or returns nothing, silently, for that run.
 
The correct approach is to block on a real condition instead of a fixed clock:
 
```sh
kubectl wait --for=condition=Ready pod -l app=app-one --timeout=120s
```
 
or, for full rollout health rather than just "a pod exists and is ready":
 
```sh
kubectl rollout status deployment/app-one
```
 
This is a known simplification in the current script, not an oversight to hide — worth calling out plainly rather than pretending the timing is guaranteed.
 
### `server.sh`: no token this time, on purpose
 
Compared to Part 1, this `server.sh` has no `token:` field written into `/etc/rancher/k3s/config.yaml` at all. That's correct here, not a regression — a token exists to let an *agent* authenticate and join a *server*. With no agent in this part, there's nothing to authenticate, so the field simply doesn't apply.
 
The `--flannel-iface=eth1` flag does still matter here even with only one node — flannel needs to know which interface to bind its overlay network to regardless of cluster size, and that's the private network interface set up for this VM, not something that only becomes relevant once a second node joins.
 
### Verifying it works
 
```sh
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: app3.com" http://192.168.56.110
curl http://192.168.56.110              # no Host header — hits the default backend
```
 
`test-apps.py` automates exactly this, looping over all four cases and printing the status code for each.

