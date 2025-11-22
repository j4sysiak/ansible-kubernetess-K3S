Zainstaluj kolekcję community.kubernetes (zawiera ona moduł Helm):
# ansible-galaxy collection install community.kubernetes

Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/community-kubernetes-2.0.1.tar.gz to /home/jacek/.ansible/tmp/ansible-local-126046fcfucf3/tmplm334ulj/community-kubernetes-2.0.1-gjj73dxz
Installing 'community.kubernetes:2.0.1' to '/home/jacek/.ansible/collections/ansible_collections/community/kubernetes'
community.kubernetes:2.0.1 was installed successfully
'kubernetes.core:5.4.1' is already installed, skipping.

$ helm version
version.BuildInfo{Version:"v3.19.2", GitCommit:"8766e718a0119851f10ddbe4577593a45fadf544", GitTreeState:"clean", GoVersion:"go1.24.9"}

*********************************************************************************************
1) Upewnij się, że Twój klaster K3s i ingress-nginx działają.
   (Jeśli kontener jest zatrzymany. Uruchom go za pomocą:  # docker start k3s-master)

# docker ps
    CONTAINER ID   IMAGE              COMMAND                  CREATED          STATUS          PORTS                                                                                                                           NAMES
    3c4eed22df7a   k3s-master-image   "/bin/bash /usr/loca…"   49 minutes ago   Up 39 minutes   0.0.0.0:6443->6443/tcp, [::]:6443->6443/tcp, 0.0.0.0:2222->22/tcp, [::]:2222->22/tcp, 0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   k3s-master


2) Sprawdź, czy "mózg" klastra (node) jest gotowy:
# kubectl --kubeconfig=k3s-kubeconfig get nodes
    NAME         STATUS   ROLES           AGE   VERSION
    k3s-master   Ready    control-plane   35m   v1.34.1+k3s1


3) Sprawdź, czy Ingress Nginx działa  (uruchamialismy go w kroku 6A i 6B):
# kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6766768fbc-l2nf2   1/1     Running   0          15m


4)  Podsumowanie
    Jeśli wszystkie trzy komendy ( `docker ps`, `kubectl get nodes`, `kubectl get pods -n ingress-nginx` ) 
    dadzą wyniki zgodne z oczekiwaniami, to znaczy, że Twoja platforma jest w 100% gotowa 
    na przyjęcie roli kube_monitoring_stack. 
    Możesz śmiało uruchamiać playbook deploy_monitoring.yml 



5)  Uruchom playbook:
# ansible-playbook -i inventory/hosts.ini destroy_kube_monitoring_stack.yml -vvv
# ansible-playbook -i inventory/hosts.ini destroy_kube_monitoring_stack---HeavyDuty.yml -vvv
# ansible-playbook -i inventory/hosts.ini deploy_monitoring.yml -vvv   /  (Może to potrwać kilka minut).

*Pobieranie chartów Helm*
Przy pierwszym `deploy_monitoring.yml` Helm musi:
dociągnąć indeks repozytorium,
pobrać chart `prometheus-community/kube-prometheus-stack`.

# kubectl --kubeconfig=./k3s-kubeconfig get pods -A
    NAMESPACE         NAME                                                       READY   STATUS    RESTARTS   AGE
    hello-namespace   hello-kubernetes-bd87d88d7-6wh9l                           1/1     Running   0          6h5m
    hello-namespace   hello-kubernetes-bd87d88d7-vzvhp                           1/1     Running   0          6h5m
    hello-namespace   hello-kubernetes-bd87d88d7-zmnzd                           1/1     Running   0          6h5m
    hello-world       hello-world-7f86d974d5-wxc6f                               1/1     Running   0          6h33m
    ingress-nginx     my-ingress-ingress-nginx-controller-6766768fbc-l2nf2       1/1     Running   0          75m
    kube-system       coredns-7896679cc-lsvwt                                    1/1     Running   0          8h
    kube-system       local-path-provisioner-578895bd58-csnjt                    1/1     Running   0          8h
    kube-system       metrics-server-7b9c9c4b9c-2bjxw                            1/1     Running   0          8h
    kube-system       svclb-my-ingress-ingress-nginx-controller-c0dbd07b-jnjj7   2/2     Running   0          75m

# kubectl --kubeconfig=./k3s-kubeconfig get crd | head
    NAME                                        CREATED AT
    addons.k3s.cattle.io                        2025-11-22T09:48:57Z
    alertmanagerconfigs.monitoring.coreos.com   2025-11-22T17:10:15Z
    alertmanagers.monitoring.coreos.com         2025-11-22T17:10:15Z
    etcdsnapshotfiles.k3s.cattle.io             2025-11-22T09:48:57Z
    helmchartconfigs.helm.cattle.io             2025-11-22T09:48:57Z
    helmcharts.helm.cattle.io                   2025-11-22T09:48:57Z
    podmonitors.monitoring.coreos.com           2025-11-22T17:10:15Z
    probes.monitoring.coreos.com                2025-11-22T17:10:15Z
    prometheusagents.monitoring.coreos.com      2025-11-22T17:10:15Z
 


6) Weryfikacja:
   Sprawdź pody:
# kubectl --kubeconfig=k3s-kubeconfig get pods -n monitoring

    NAME                                                   READY   STATUS                 RESTARTS   AGE
    prometheus-prometheus-stack-kube-prom-prometheus-0     2/2     Running                0          17m
    prometheus-stack-grafana-749bbd849-tl4cl               3/3     Running                0          18m
    prometheus-stack-kube-prom-operator-86d95b6967-b68fm   1/1     Running                0          18m
    prometheus-stack-kube-state-metrics-59d55c4c-6qmfx     1/1     Running                0          18m
    prometheus-stack-prometheus-node-exporter-7f9b5        0/1     CreateContainerError   0          18m


prometheus...-prometheus-0 ... Running: Sukces! Główny komponent, Prometheus, działa.
prometheus-stack-grafana... Running: Sukces! Grafana działa.
prometheus-stack-kube-prom-operator... Running: Sukces! Operator, czyli "mózg" zarządzający całością, działa.
prometheus-stack-kube-state-metrics... Running: Sukces! Komponent zbierający metryki o stanie obiektów w klastrze działa.
prometheus-stack-prometheus-node-exporter-7f9b5 ... CreateContainerError: To jest mały problem, ale nie jest on przyczyną błędu 404. Node Exporter to agent, który ma działać na każdym węźle, aby zbierać metryki z samego systemu operacyjnego. W naszym specyficznym środowisku kontenerowym bez systemd czasami ma on problemy ze startem. Możemy go na razie zignorować.


7) Sprawdź Ingress:
# kubectl --kubeconfig=k3s-kubeconfig get ingress -n monitoring

    NAME                       CLASS    HOSTS           ADDRESS   PORTS   AGE
    prometheus-stack-grafana   <none>   grafana.local             80      19m

prometheus-stack-grafana ... grafana.local ... 80: Sukces! Zasób Ingress został poprawnie stworzony. 
Mówi on: "Ruch przychodzący na host grafana.local na porcie 80 ma być kierowany do serwisu Grafany".

 

Wielki Finał:
Edytuj plik C:\Windows\System32\drivers\etc\hosts jako administrator i dodaj linię: 127.0.0.1 grafana.local
Poczekaj chwilę po zakończeniu playbooka (około 15-30 sekund), 
aż Ingress Controller wczyta nową konfigurację.

trzeba trochę cierpliwości za pierwszym razem ... około 10 min - poszedlem do Lidla i jak wróciłem to dzialala strona. 
Otwórz przeglądarkę i wejdź na http://grafana.local:8081
Zaloguj się (użytkownik: admin, hasło: prom-operator) i zobacz gotowe dashboardy monitorujące Twój klaster.

Użytkownik: admin
Hasło: prom-operator













