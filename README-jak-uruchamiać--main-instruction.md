W terminalu WSL (lub Intelij) aktywuj środowisko: 

# source ~/ansible-venv/bin/activate

----------------  roles/k3s_master  --------------------
# Step.1
zbudować i uruchomić kontener Docker z K3s Master:
GO TO --> roles/k3s_master/README--FIRST---Docker.md

# Step.2
GO TO --> README--SECOND--kubernetess-K3S.md

# Step.3
GO TO --> README--THIRD--kubernetess--checkings-after-deployment.md

# Step.4
GO TO --> roles/helm_installer/README--install_helm.md

# Step.5
GO TO --> roles/deploy_app/README--deploy_app.md

# Step.6
GO TO --> roles/hello_kubernetes_app/README--hello_kubernetes_app.md

----------------  end of roles/k3s_master  --------------------
# Step.7
rola: kube_monitoring_stack:
1. przygotowuje Grafanę do udostępnienia przez Ingress
2. Deploy Kube Prometheus Stack using Helm

Użyjemy potężnego modułu kubernetes.core.helm.
# ansible-galaxy collection install community.kubernetes

GO TO --> roles/kube_monitoring_stack/README--uruchomienie-K3s-i-weryfikacja.md




















