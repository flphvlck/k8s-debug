# k8s-debug
Docker images primarily purposed for debugging or playing with Kubernetes with simple Node.js service on port 8080 which serves container's hostname.  
Source git repository: [https://github.com/flphvlck/k8s-debug](https://github.com/flphvlck/k8s-debug)  
Docker repository: [https://quay.io/filiphavlicek/k8s-debug](https://quay.io/filiphavlicek/k8s-debug)

## Tags
**quay.io/filiphavlicek/k8s-debug:root** - runs under root  
**quay.io/filiphavlicek/k8s-debug:nonroot** - runs under regular user k8s-debug

## Deploy with deployment
From command line definititions
```
kubectl create namespace k8s-debug
kubectl -n k8s-debug create deployment k8s-debug --image=quay.io/filiphavlicek/k8s-debug:root
kubectl -n k8s-debug create service clusterip k8s-debug --tcp=80:8080
```
From yaml files
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/service.yaml
```
Ingress resource (don't forget to replace the hostname)
```
curl -s -o - https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/ingress.yaml | sed "s/@@HOSTNAME@@/yourhostname.domain.tld/g" | kubectl apply -f -
```

## Deploy with daemonset
Deploy daemonset instead of deployment
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/daemonset.yaml
```
Debug example
```
for pod in $(kubectl -n k8s-debug get pods -l app=k8s-debug -o=name); do pod="${pod#pod/}"; echo "$pod"; kubectl -n k8s-debug exec -it "${pod#pod/}" -- bash -c "env | grep ^NODE_NAME=; echo -n "API_IP="; dig +short kubernetes.default.svc.cluster.local"; echo; done
```

## Deploy with pod
Deploy pod instead of deployment
```
kubectl apply -f https://raw.githubusercontent.com/flphvlck/k8s-debug/refs/heads/main/pod.yaml
``` 

## Clean
```
kubectl -n k8s-debug delete all -l app=k8s-debug
kubectl -n k8s-debug delete ingress k8s-debug
```
Or delete whole namespace
```
kubectl delete namespace k8s-debug
```
