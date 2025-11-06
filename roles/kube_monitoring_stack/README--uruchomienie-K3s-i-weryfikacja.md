Zainstaluj kolekcję community.kubernetes (zawiera ona moduł Helm):
# ansible-galaxy collection install community.kubernetes

Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/community-kubernetes-2.0.1.tar.gz to /home/jacek/.ansible/tmp/ansible-local-126046fcfucf3/tmplm334ulj/community-kubernetes-2.0.1-gjj73dxz
Installing 'community.kubernetes:2.0.1' to '/home/jacek/.ansible/collections/ansible_collections/community/kubernetes'
community.kubernetes:2.0.1 was installed successfully
'kubernetes.core:5.4.1' is already installed, skipping.

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


3) Sprawdź, czy "bramkarz" (Ingress Nginx) działa:
# kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6b974db7d5-qcglk   1/1     Running   0          12m


4)  Podsumowanie
    Jeśli wszystkie trzy komendy ( `docker ps`, `kubectl get nodes`, `kubectl get pods -n ingress-nginx` ) 
    dadzą wyniki zgodne z oczekiwaniami, to znaczy, że Twoja platforma jest w 100% gotowa 
    na przyjęcie roli kube_monitoring_stack. 
    Możesz śmiało uruchamiać playbook deploy_monitoring.yml 



5)  Uruchom playbook:
# ansible-playbook deploy_monitoring.yml      /  (Może to potrwać kilka minut).

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

Otwórz przeglądarkę i wejdź na http://grafana.local:8081
Zaloguj się (użytkownik: admin, hasło: prom-operator) i zobacz gotowe dashboardy monitorujące Twój klaster.

Użytkownik: admin
Hasło: prom-operator













