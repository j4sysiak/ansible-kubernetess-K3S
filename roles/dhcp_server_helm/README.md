Aby wdrożyć serwer DHCP przez Helm na K3s, wykonaj następujące kroki:
1. Instalacja wymaganych narzędzi

Zainstaluj kolekcje Ansible dla Kubernetes
# ansible-galaxy collection install kubernetes.core
# ansible-galaxy collection install community.kubernetes

Kolekcja community.kubernetes (lub kubernetes.core) to moduły Ansible, nie część Kubernetes ani K3s.
Dlaczego musisz ją zainstalować?
K3s to klaster Kubernetes — silnik uruchamiający kontenery i zarządzający zasobami.
Ansible to narzędzie automatyzacji, które nie ma wbudowanej obsługi Kubernetes. Aby Ansible mógł komunikować się z klastrem K3s (np. wdrażać zasoby przez API Kubernetes, używać Helm), potrzebuje dedykowanych modułów.
Kolekcje kubernetes.core / community.kubernetes dostarczają moduły takie jak:
kubernetes.core.k8s — ogólne zarządzanie zasobami K8s (Deployment, Service, ConfigMap itp.)
kubernetes.core.helm — wdrażanie chartów Helm z poziomu Ansible
kubernetes.core.k8s_info — pobieranie informacji o zasobach



# Upewnij się, że Helm jest zainstalowany (jeśli nie, zainstaluj)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
    Dload  Upload   Total   Spent    Left  Speed
    100 11929  100 11929    0     0  27146      0 --:--:-- --:--:-- --:--:-- 27173
    Helm v3.19.2 is available. Changing from version v3.19.0.
    Downloading https://get.helm.sh/helm-v3.19.2-linux-amd64.tar.gz
    Verifying checksum... Done.
    Preparing to install helm into /usr/local/bin
    helm installed into /usr/local/bin/helm




2. Utworzenie playbooka wdrożeniowego
   Utwórz plik deploy_dhcp_helm.yml w katalogu głównym projektu:
```yaml
---
- name: Deploy DHCP via Helm on K3s
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
  # Możesz nadpisać te zmienne przez -e
  dhcp_image_repository: networkboot/dhcpd
  dhcp_image_tag: latest
  dhcp_interface: eth0
  dhcp_subnet: 172.17.30.0
  dhcp_netmask: 255.255.255.0
  dhcp_range_start: 172.17.30.100
  dhcp_range_end: 172.17.30.200
  dhcp_routers:
  - 172.17.30.1
  dhcp_dns_servers:
  - 8.8.8.8
  - 1.1.1.1
  dhcp_domain_name: lan
  roles:
    - role: dhcp_server_helm
```

3. Dostosowanie konfiguracji
   Sprawdź i dostosuj zmienne w roles/dhcp_server_helm/defaults/main.yml według swojej sieci:
   dhcp_interface – interfejs sieciowy (np. eth0)
   dhcp_subnet, dhcp_netmask – parametry sieci
   dhcp_range_start, dhcp_range_end – zakres przydzielanych IP
   dhcp_routers, dhcp_dns_servers – bramki i DNS


4. Podstawowe wdrożenie


Aby usunąć poprzedniego poda DHCP wdrożonego przez dhcp_server_docker, wykonaj:
1. Ręczne usunięcie (szybkie)

Znajdź nazwę poda
# kubectl get pods -A | grep dhcp
    default            dhcp-test                                  1/1     Running   0             95m
    dhcp-dockerhub     dhcp-server-dockerhub-6s67c                1/1     Running   0             108m

Usuń pod (zamień <namespace> i <pod-name>)
# kubectl delete pod <pod-name> -n <namespace>
Usuń pod w namespace 'default'
# kubectl delete pod dhcp-test -n default

Usuń pod w namespace 'dhcp-dockerhub'
# kubectl delete pod dhcp-server-dockerhub-6s67c -n dhcp-dockerhub

Uwaga: Jeśli pod dhcp-server-dockerhub-6s67c jest częścią DaemonSet, zostanie automatycznie odtworzony. 
W takim przypadku musisz najpierw usunąć DaemonSet:
# kubectl delete daemonset -n dhcp-dockerhub --all

Teraz usuń cały namespace dhcp-dockerhub
(Jeśli chcesz usunąć cały namespace wraz z wszystkimi zasobami (pod, ConfigMap itp.)):
# kubectl delete namespace dhcp-dockerhub


Usuń ConfigMap (jeśli istnieje)
# kubectl delete configmap dhcp-config -n <namespace>
# kubectl delete configmap dhcp-config -n default
# kubectl delete configmap dhcp-config -n dhcp-dockerhub

Usuń namespace (jeśli dedykowany dla DHCP)
# kubectl delete namespace <namespace>
# kubectl delete namespace default
# kubectl delete namespace dhcp-dockerhub



Weryfikacja usunięcia:
Sprawdź, czy pody zostały usunięte
# kubectl get pods -A | grep dhcp
Powinno zwrócić pusty wynik lub tylko pody z nowego wdrożenia
OK / zwrócilo pusty wynik

 

////////// drugi sposob usuwania //////////////

Usuwanie przez playbook (zalecane)
   Utwórz plik undeploy_dhcp_docker.yml:

```yaml
---
- name: Remove DHCP Docker deployment
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    dhcp_namespace: default  # zamień na właściwy namespace
  tasks:
    - name: Delete DHCP pod
      kubernetes.core.k8s:
        state: absent
        api_version: v1
        kind: Pod
        name: dhcp-server
        namespace: "{{ dhcp_namespace }}"
      ignore_errors: true

    - name: Delete DHCP ConfigMap
      kubernetes.core.k8s:
        state: absent
        api_version: v1
        kind: ConfigMap
        name: dhcp-config
        namespace: "{{ dhcp_namespace }}"
      ignore_errors: true

    - name: Wait for pod termination
      kubernetes.core.k8s_info:
        kind: Pod
        name: dhcp-server
        namespace: "{{ dhcp_namespace }}"
      register: pod_info
      until: pod_info.resources | length == 0
      retries: 30
      delay: 2
      ignore_errors: true
```

odpal:
# ansible-playbook undeploy_dhcp_docker.yml -e "dhcp_namespace=default"
# ansible-playbook undeploy_dhcp_docker.yml -e "dhcp_namespace=dhcp-dockerhub"

//////////////////////////////////////////
3. Weryfikacja usunięcia

# Sprawdź, czy pod został usunięty
kubectl get pods -A | grep dhcp

# Sprawdź, czy ConfigMap został usunięty
kubectl get configmap -A | grep dhcp

/////////////////////////////////

Po usunięciu możesz bezpiecznie uruchomić nowy playbook z Helm:
# ansible-playbook -i inventory deploy_dhcp_helm.yml \
-e "dhcp_image_repository=networkboot/dhcpd" \
-e "dhcp_image_tag=latest" \
-e "dhcp_interface=eth0"

 

5. Weryfikacja

Sprawdź status release'u Helm
# helm list -n dhcp-helm

# Sprawdź DaemonSet
kubectl get daemonset -n dhcp-helm

# Sprawdź logi DHCP
kubectl logs -n dhcp-helm -l app.kubernetes.io/name=dhcpd -f

# Sprawdź ConfigMap
kubectl get configmap -n dhcp-helm
kubectl describe configmap dhcp-server-helm-config -n dhcp-helm




6. Odinstalowanie (jeśli potrzeba)
   helm uninstall dhcp-server-helm -n dhcp-helm
   kubectl delete namespace dhcp-helm


Playbook automatycznie utworzy namespace dhcp-helm, zainstaluje chart lokalny z katalogu roles/dhcp_server_helm/charts/dhcpd i wdroży DaemonSet z konfiguracją DHCP.