# ansible-playbook deploy_helm_chart.yml


Weryfikacja: Sprawdź, czy pody ingress-nginx znowu działają:
# kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx