roles/dhcp_server_dockerhub/
├── defaults/
│   └── main.yml              # Domyślne zmienne (obraz z Docker Hub)
├── tasks/
│   └── main.yml              # Zadania Ansible
├── templates/
│   ├── daemonset.yaml.j2     # DaemonSet K3s
│   └── dhcpd.conf.j2         # ConfigMap z konfiguracją DHCP
└── README.md                 # Dokumentacja roli

----------------------------------------------------------------------------
# DHCP Server Docker Hub Role
----------------------------------------------------------------------------
This Ansible role deploys a DHCP server using a Docker Hub image in a K3s cluster. 
It creates a DaemonSet to ensure that the DHCP server runs on all nodes in the cluster.
## Prerequisites
- A running K3s cluster.
- Ansible installed on your control node.
- The `k3s-kubeconfig` file available in your project directory.
- The `kubernetes.core` Ansible collection installed.
 
This configuration will deploy a DHCP server on all nodes in the K3s cluster u
sing the specified Docker Hub image and DHCP settings.

//////////////////////////////

Zainstaluj kolekcję community.kubernetes (zawiera ona moduł Helm):
# ansible-galaxy collection install community.kubernetes

Rola: dhcp_server_dockerhub
Wdraża serwer **ISC DHCP Server** w klastrze **K3s** przy użyciu obrazu z **Docker Hub**.

Wymagania

- Działający klaster K3s
- Plik `k3s-kubeconfig` w katalogu projektu
- Zainstalowana kolekcja `kubernetes.core`

Zmienne

| Zmienna | Domyślna wartość | Opis |
|---------|------------------|------|
| `dhcp_namespace` | `dhcp-dockerhub` | Namespace w K3s |
| `dhcp_image` | `networkboot/dhcpd:latest` | Obraz z Docker Hub |
| `dhcp_interface` | `eth0` | Interfejs sieciowy węzła |
| `dhcp_subnet` | `172.17.0.0` | Podsieć DHCP |
| `dhcp_range_start` | `172.17.20.100` | Początek zakresu IP |
| `dhcp_range_end` | `172.17.20.200` | Koniec zakresu IP |


    Porównanie ról: (dhcp_server  i  dhcp_server_dockerhub)
    Cecha         | dhcp_server (lokalna)            | dhcp_server_dockerhub (Docker Hub)  
    --------------+----------------------------------+----------------------------------
    Obraz           localhost/isc-dhcp-server:latest   networkboot/dhcpd:latest
    DaemonSet       dhcp-server                        dhcp-server-dockerhub
    Namespace       dhcp                               dhcp-dockerhub
    Zakres IP       172.17.10.100–200                  172.17.20.100–200
    Źródło obrazu   Lokalny build                      Docker Hub (publiczny)
    DaemonSet       dhcp-server                        dhcp-server-dockerhub
 
🎉 Podsumowanie
✅ Utworzono nową rolę dhcp_server_dockerhub
✅ Używa obrazu z Docker Hub (networkboot/dhcpd:latest)
✅ Zarządzana przez K3s (DaemonSet + namespace)
✅ Inny zakres IP (172.17.20.100–200)
✅ Niezależna od pierwotnej roli – możesz uruchomić obie jednocześnie!

Wyłącz starą rolę przed uruchomieniem nowej (ZALECANE)
Unikniesz konfliktów portów
Jeden serwer DHCP w sieci to standard (łatwiejsze debugowanie)
Klienci dostaną spójne odpowiedzi

1. Usuń DaemonSet starego serwera
# kubectl --kubeconfig=k3s-kubeconfig delete daemonset dhcp-server -n dhcp

2. (Opcjonalnie) Usuń cały namespace
# kubectl --kubeconfig=k3s-kubeconfig delete namespace dhcp

3. Sprawdź, czy port 67 jest wolny na wszystkich węzłach
# ss -ulnp | grep :67

4. Uruchom nową rolę
   Użycie playbooka do wdrożenia serwera DHCP:
# ansible-playbook -i inventory deploy_dhcp_dockerhub.yml -e "dhcp_image=networkboot/dhcpd:latest dhcp_interface=eth0 dhcp_namespace=dhcp-dockerhub"

ansible-playbook -i inventory deploy_dhcp_dockerhub.yml -e "dhcp_interface=eth0"

5. Weryfikacja:
Sprawdź, czy stary pod już nie istnieje
# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp
    No resources found in dhcp namespace.

6. Sprawdź nowy pod ( Weryfikacja wdrożenia )
  
# kubectl --kubeconfig=k3s-kubeconfig get ns | grep dhcp-dockerhub
    dhcp-dockerhub     Active   28m

# kubectl --kubeconfig=k3s-kubeconfig get daemonset -n dhcp-dockerhub
    NAME                    DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    dhcp-server-dockerhub   1         1         1       1            1           <none>          20m

# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp-dockerhub
    NAME                          READY   STATUS    RESTARTS   AGE
    dhcp-server-dockerhub-6s67c   1/1     Running   0          3m37s

# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp-dockerhub -o wide
    NAME                          READY   STATUS    RESTARTS   AGE    IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp-server-dockerhub-6s67c   1/1     Running   0          5m9s   172.17.0.2   k3s-master   <none>           <none>          <none>

# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp-dockerhub -l app=dhcp-server-dockerhub --tail=50

Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
Internet Systems Consortium DHCP Server 4.4.1
Copyright 2004-2018 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/
Config file: /data/dhcpd.conf
Database file: /data/dhcpd.leases
PID file: /var/run/dhcpd.pid
Wrote 0 leases to leases file.
Listening on LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16
Sending on   LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16
Sending on   Socket/fallback/fallback-net
Server starting service.


Podgląd pliku lease (Podgląd plików w kontenerze)
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp-dockerhub -l app=dhcp-server-dockerhub -o jsonpath='{.items[0].metadata.name}')
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp-dockerhub "$POD" -- sh -c 'ls -l /data && cat /data/dhcpd.leases || true'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    total 8
    -rw-r--r-- 1 root root 269 Nov 16 16:57 dhcpd.conf
    -rw-r--r-- 1 root root 286 Nov 16 16:57 dhcpd.leases
    -rw-r--r-- 1 root root   0 Nov 16 16:57 dhcpd.leases~
    # The format of this file is documented in the dhcpd.leases(5) manual page.
    # This lease file was written by isc-dhcp-4.4.1
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    8 /data/dhcpd.leases
    authoring-byte-order little-endian;
    server-duid "\000\001\000\0010\254\277\005\322\311\203\006S\347";

 


(Opcjonalnie) sprawdź i wyłącz starą rolę, jeśli jeszcze jest 
# kubectl --kubeconfig=k3s-kubeconfig get daemonset -A | grep dhcp-server || true
    dhcp-dockerhub   dhcp-server-dockerhub   1         1         1       1            1           <none>          25m

# kubectl --kubeconfig=k3s-kubeconfig delete daemonset dhcp-server -n dhcp || true
    Error from server (NotFound): daemonsets.apps "dhcp-server" not found

Sprawdź nasłuch (na węźle)
# ss -ulnp | grep ":67"

(Opcjonalnie) uruchom tymczasowy klient BusyBox i obserwuj nowe lease
# kubectl run dhcp-test --image=busybox:1.36 --restart=Never --command -- sh -c 'udhcpc -i eth0 -v || sleep 10'
# kubectl logs dhcp-test