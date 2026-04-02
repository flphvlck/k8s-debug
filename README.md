# k8s-debug
A project primarily intended for debugging and experimenting with Kubernetes. The k8s-debug container runs a Node.js service on port 8080 that returns pod details (when running in Kubernetes) along with other useful information.

Source git repository: [https://github.com/flphvlck/k8s-debug](https://github.com/flphvlck/k8s-debug)  
Image repositories:
  * [https://quay.io/filiphavlicek/k8s-debug](https://quay.io/filiphavlicek/k8s-debug)
  * [https://hub.docker.com/r/flphvlck/k8s-debug](https://hub.docker.com/r/flphvlck/k8s-debug)

## HTTP server (server.js)
The container runs a simple Node.js HTTP server on port 8080. On each request it returns hostname, timestamp, pod information (when running in Kubernetes), and request details (headers, method, path).

Features:
- **X-Delay** - accepts `X-Delay` header (value in seconds) to simulate response delays
- **POST/PUT** - accepts and discards request body, returns the amount of data received (useful for testing proxy upload limits)
- **Kubernetes probe detection** - requests with `kube-probe/*` User-Agent get a fast `200 ok` with no logging (also useful for quick health checks)

```
# Simulate 5 second response delay
curl -H "X-Delay: 5" http://<service-address>:8080/

# POST data - response includes "Data received: X.XX MiB (Y bytes)"
curl -X POST --data-binary @largefile.bin http://<service-address>:8080/

# Generate and send 100 MiB of data
dd if=/dev/zero bs=1M count=100 | curl -X POST -H "Content-Type: application/octet-stream" --data-binary @- http://<service-address>:8080/

# Quick 200 ok without logging (simulates kube-probe)
curl -A "kube-probe/1.31" http://<service-address>:8080/
```

## Tags
**quay.io/filiphavlicek/k8s-debug:root** - based on Debian, runs under root
**quay.io/filiphavlicek/k8s-debug:nonroot** - based on Debian, runs under regular user k8s-debug
**quay.io/filiphavlicek/k8s-debug:slim** - based on Alpine image, no debug tools
**quay.io/filiphavlicek/k8s-debug:slim** - based on Ubuntu, without Node.js service, using it in k9s plugins

## Deploy with Helm
```
helm repo add k8s-debug https://flphvlck.github.io/k8s-debug
helm repo update
helm -n k8s-debug install <release_name> --create-namespace k8s-debug/k8s-debug
```

## Deploy with K8s manifests
### Deploy with deployment
From command line definititions
```
kubectl create namespace k8s-debug
kubectl -n k8s-debug create deployment k8s-debug --image=quay.io/filiphavlicek/k8s-debug:root
kubectl -n k8s-debug create service clusterip k8s-debug --tcp=80:8080
```
From yaml files
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/service.yaml
```
Ingress resource (don't forget to replace the hostname)
```
curl -s -o - https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/ingress.yaml | sed "s/@@HOSTNAME@@/yourhostname.domain.tld/g" | kubectl apply -f -
```

### Deploy with daemonset
Deploy daemonset instead of deployment
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/daemonset.yaml
```
Debug example
```
for pod in $(kubectl -n k8s-debug get pods -l app=k8s-debug -o=name); do pod="${pod#pod/}"; echo "$pod"; kubectl -n k8s-debug exec -it "${pod#pod/}" -- bash -c "env | grep ^NODE_NAME=; echo -n API_IP=; dig +short kubernetes.default.svc.cluster.local"; echo; done
```

### Deploy with pod
Deploy pod instead of deployment
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/manifests/pod.yaml
```