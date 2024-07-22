#!/usr/bin/env bash

TMP_DIR=$(mktemp -d)
POD_IP_LIST="${TMP_DIR}/pod-ip.list"
POD_SCRIPT="${TMP_DIR}/pod-k8s-debug.sh"
NOC="\e[0m"
BLUE="\e[34;1m"

kubectl get ns k8s-debug &>/dev/null || kubectl create ns k8s-debug
kubectl -n k8s-debug get svc k8s-debug &>/dev/null || kubectl apply -f https://gitlab.com/filip.havlicek/k8s-debug/raw/master/service.yaml
if ! kubectl -n k8s-debug get daemonset k8s-debug &>/dev/null; then
    kubectl apply -f https://gitlab.com/filip.havlicek/k8s-debug/raw/master/daemonset.yaml
    kubectl -n k8s-debug rollout status daemonset k8s-debug -w
fi

cat<<"EOF">"$POD_SCRIPT"
#!/usr/bin/env bash

NOC="\e[0m"
YELLOW="\e[33;1m"

#env | grep ^KUBERNETES_NODE_NAME= | sed "s/=/: /g"
echo -e "${YELLOW}RESOLVING TEST${NOC}"
echo -n "K8S API IP: "
dig +short kubernetes.default.svc.cluster.local
echo -n "NIC.CZ IP: "
dig +short nic.cz
echo -e "${YELLOW}SERVICE CURL TEST${NOC}"
curl k8s-debug
echo -e "${YELLOW}INTER POD CURL TEST${NOC}"
IPS_COUNT=$(wc -l < /tmp/pod-ip.list)
LINE=0
while read -r POD_IP; do
    ((LINE++))
    curl "${POD_IP}:8080"
    if [[ "$LINE" -lt "$IPS_COUNT" ]]; then
        echo "---"
    fi
done< <(cat /tmp/pod-ip.list)
EOF
chmod +x "$POD_SCRIPT"

kubectl -n k8s-debug get pods -l app=k8s-debug --output custom-columns=IP:.status.podIP --no-headers > "$POD_IP_LIST"

for POD in $(kubectl -n k8s-debug get pods -l app=k8s-debug -o=name); do
    POD="${POD#pod/}"
    kubectl -n k8s-debug cp "$POD_IP_LIST" "${POD}:/tmp"
    kubectl -n k8s-debug cp "$POD_SCRIPT" "${POD}:/tmp"
    NODE=$(kubectl -n k8s-debug get pod "$POD" --output custom-columns=NODE:.spec.nodeName --no-headers)
    echo -e "${BLUE}${NODE^^} - ${POD}${NOC}"
    echo -n "POD IP: "
    kubectl -n k8s-debug get pod "${POD}" --output custom-columns=IP:.status.podIP --no-headers
    kubectl -n k8s-debug exec -it "$POD" -- bash -c "/tmp/pod-k8s-debug.sh"
    echo
done

rm -rf "$TMP_DIR"
