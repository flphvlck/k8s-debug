# k8s-debug
A project primarily intended for debugging and experimenting with Kubernetes. The k8s-debug container runs a Node.js service on port 8080 that returns pod details (when running in Kubernetes) along with other useful information.

Source git repository: [https://github.com/flphvlck/k8s-debug](https://github.com/flphvlck/k8s-debug)  
Docker repositories:
  * [https://quay.io/filiphavlicek/k8s-debug](https://quay.io/filiphavlicek/k8s-debug)
  * [https://hub.docker.com/r/flphvlck/k8s-debug](https://hub.docker.com/r/flphvlck/k8s-debug)

## Tags
**quay.io/filiphavlicek/k8s-debug:root** - runs under root  
**quay.io/filiphavlicek/k8s-debug:nonroot** - runs under regular user k8s-debug

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