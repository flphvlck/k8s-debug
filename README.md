# k8s-debug
Docker images primarily purposed for debugging or playing with Kubernetes with simple Node.js service on port 8080 which serves container's hostname.

**filiphavlicek/k8s-debug:root** - runs under root  
**filiphavlicek/k8s-debug:nonroot** - runs under regular user k8s-debug

## Deploy
From command line definititions
```
kubectl create deployment k8s-debug --image=filiphavlicek/k8s-debug:root
kubectl create service clusterip k8s-debug --tcp=80:8080
```
From yaml files
```
kubectl apply -f https://raw.githubusercontent.com/phidlipus/k8s-debug/master/deployment.yaml
kubectl apply -f https://raw.githubusercontent.com/phidlipus/k8s-debug/master/service.yaml
```
Ingress resource (don't forget to replace the hostname)
```
curl -s -o - https://raw.githubusercontent.com/phidlipus/k8s-debug/master/ingress.yaml | sed "s/@@HOSTNAME@@/yourhostname.domain.tld/g" | kubectl apply -f -
```

## Clean
```
kubectl delete all -l app=k8s-debug
kubectl delete ingress k8s-debug
```

## Example with DaemonSet
Delete previously deployed Deployment
```
kubectl delete deployment k8s-debug
```
Deploy damonset
```
kubectl apply -f https://raw.githubusercontent.com/phidlipus/k8s-debug/master/daemonset.yaml
```
Debug
```
for pod in $(kubectl get pods -l app=k8s-debug -o=name); do pod="${pod#pod/}"; echo "$pod"; kubectl exec -it "${pod#pod/}" -- bash -c "env | grep ^NODE_NAME=; echo -n "API_IP="; dig +short kubernetes.default.svc.cluster.local"; echo; done
```
