W terminalu WSL (lub Intelij) aktywuj środowisko: 

#  source ~/ansible-venv/bin/activate
#  cd ~/dev/ansible-kubernetess-K3S

----------------  roles/k3s_master  --------------------
# Step.1
zbudować i uruchomić kontener Docker z K3s Master:
GO TO --> roles/k3s_master/README--FIRST---Docker.md

# Step.2
GO TO --> README--SECOND--kubernetess-K3S.md

# Step.3
GO TO --> README--THIRD--kubernetess--checkings-after-deployment.md

# Step.4
GO TO --> roles/hello_world_nginx/README.md

# Step.5
GO TO --> roles/hello_kubernetes_app/README--hello_kubernetes_app.md


---------------  instalacja Ingress Nginx przez Helm ręcznie 6A i za pomocą taska 6B --------------------------------------------------------------------------
# Step.6A   (instalacja helma (w tasku) na WSL oraz instalacja ręczna Ingress NGINX w klastrze K3s przy użyciu tego helma)
GO TO --> roles/installing_charts_using_helm/README--installing_charts_using_helm.md

# Step.6B  (musi być zainstalowany helm w WSL jak wyżej 6A)
GO TO --> roles/deploy_app_using_helm_chart/READNE--deploy_app_using_helm_chart.md
----------------  end of roles/k3s_master  -------------------------------------------------------------------------




-------------------- kube_monitoring_stack ----------------------
# Step.7   (musi być zainstalowany helm w WSK jak wyżej 6A)
rola: kube_monitoring_stack:
1. przygotowuje Grafanę do udostępnienia przez Ingress
2. Deploy Kube Prometheus Stack using Helm

Użyjemy potężnego modułu kubernetes.core.helm.
# ansible-galaxy collection install community.kubernetes

GO TO --> roles/kube_monitoring_stack/README--kube_monitoring_stack.md.md
--------------------- end of kube_monitoring_stack ----------------------




------------------- dhcp_server ---------------------- 
# Step.8
GO TO --> roles/dhcp_server/README.md   
utruchomienie serwera DHCP w klastrze K3s za pomocą DaemonSet
------------------- end of dhcp_server ----------------------




















