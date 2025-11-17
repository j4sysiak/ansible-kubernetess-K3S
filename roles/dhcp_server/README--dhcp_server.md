# source ~/ansible-venv/bin/activate
# cd ~/dev/ansible-kubernetess-K3S


1. bash script do uruchomienia serwera DHCP w klastrze K3s za pomocą DaemonSet
DaemonSet to typ zasobu Kubernetes, który zapewnia, że jedna kopia poda działa na każdym węźle (node) w klastrze.
W kontekście serwera DHCP:
Serwer DHCP - przydziela adresy IP urządzeniom w sieci
Klaster K3s - lekka dystrybucja Kubernetes
DaemonSet - gwarantuje, że pod z serwerem DHCP uruchomi się na każdym węźle klastra
Zalety tego podejścia:
Jeśli masz wiele węzłów, każdy będzie miał swojego DHCP servera
Automatyczne skalowanie - nowy węzeł = automatycznie nowy pod DHCP
Bezpośredni dostęp do interfejsów sieciowych węzła (hostNetwork: true)

 
usun/restart pod (Po zmianie ConfigMap z subPath pamiętaj o restarcie poda):
Przeładuj ConfigMap:
ansible-playbook ... lub kubectl apply -f ....
- Zrestartuj DaemonSet: 
# kubectl rollout restart ds/dhcp-server -n dhcp
# kubectl --kubeconfig=k3s-kubeconfig delete pod -n dhcp -l app=dhcp-server
lub
# kubectl --kubeconfig=k3s-kubeconfig rollout restart ds/dhcp-server -n dhcp
lub usuń pod ręcznie:
# kubectl --kubeconfig=k3s-kubeconfig delete daemonset dhcp-server -n dhcp

(Opcjonalnie) Usuń cały namespace
# kubectl --kubeconfig=k3s-kubeconfig delete namespace dhcp

Weryfikacja, że pod już nie istnieje
# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp
    No resources found in dhcp namespace.

Potem uruchom playbook:
# ansible-playbook -i inventory deploy_dhcp_server.yml -e "dhcp_interface=eth0"

lub start z poziomu terminala:  (ale tego nie wykonuj raczej ręcznie jeśli używasz Ansible)
# kubectl --kubeconfig=k3s-kubeconfig apply -f dhcpd-daemonset.yaml
# kubectl --kubeconfig=k3s-kubeconfig create namespace dhcp

-------------  sprawdzenie działania  -----------------
1 Sprawdź czy DaemonSet działa i czy pod jest w stanie READY
  DaemonSet READY 1/1

# kubectl --kubeconfig=k3s-kubeconfig -n dhcp apply -f /tmp/dhcp-daemonset.yaml
# kubectl --kubeconfig=k3s-kubeconfig -n dhcp rollout restart ds/dhcp-server
# kubectl --kubeconfig=k3s-kubeconfig -n dhcp rollout status ds/dhcp-server

# kubectl --kubeconfig=k3s-kubeconfig rollout status daemonset/dhcp-server -n dhcp
    daemon set "dhcp-server" successfully rolled out

# kubectl --kubeconfig=k3s-kubeconfig rollout status ds/dhcp-server -n dhcp
    daemon set "dhcp-server" successfully rolled out

# kubectl --kubeconfig=k3s-kubeconfig get daemonset dhcp-server -n dhcp
    NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    dhcp-server   1         1         1       1            1           <none>          2d19h

# kubectl --kubeconfig=k3s-kubeconfig get ds dhcp-server -n dhcp
    NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    dhcp-server   1         1         1       1            1           <none>          2d17h

# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp -l app=dhcp-server -o wide
    NAME                READY   STATUS    RESTARTS       AGE    IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp-server-xlwwd   1/1     Running   2 (133m ago)   133m   172.17.0.2   k3s-master   <none>           <none>

# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp -o wide
    NAME                READY   STATUS    RESTARTS        AGE   IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp-server-xlwwd   1/1     Running   2 (6m55s ago)   7m    172.17.0.2   k3s-master   <none>           <none>

sprawdzenie jakiego obrazu używa pod
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp -l app=dhcp-server -o jsonpath='{.items[0].metadata.name}')
# kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp "$POD" -o jsonpath='{.spec.containers[0].image}'
    networkboot/dhcpd:latest(ansible-venv) 

lub
# export KUBECONFIG=k3s-kubeconfig
# IMG=$(kubectl -n dhcp get ds dhcp-server -o jsonpath='{.spec.template.spec.containers[0].image}')
# echo "DS image: $IMG"
    DS image: networkboot/dhcpd:latest

Czy taki tag istnieje w containerd K3s?
# docker exec k3s-master sh -lc 'k3s ctr --namespace k8s.io images ls || /var/lib/rancher/k3s/data/current/bin/ctr --namespace k8s.io images ls' | grep -F "$IMG" || echo "BRAK OBRAZU: $IMG"
    docker.io/networkboot/dhcpd:latest  application/vnd.oci.image.manifest.v1+json   sha256:b1a8d99bf071ddb9302ace091752b7872ac6dd2a48a76f3b74fadf8fb0e13796 5.5 MiB    linux/amd64                                                                                                         io.cri-containerd.image=managed

Zdarzenia poda (zobaczysz m.in. ErrImageNeverPull / ImageInspectError)
# POD=$(kubectl -n dhcp get pod -l app=dhcp-server -o jsonpath='{.items[0].metadata.name}')
# kubectl -n dhcp describe pod "$POD" | sed -n '/Events:/,$p'

(te bledy poniżej były kiedy probowalem uruchomic reczny build obrazu isc-dhcp-server i nie bylo go w containerd K3s):
Type     Reason     Age                   From               Message
  ----     ------     ----                  ----               -------
Normal   Scheduled  13m                   default-scheduler  Successfully assigned dhcp/dhcp-server-4tq7m to k3s-master
Normal   Pulled     13m                   kubelet            Container image "busybox:1.36" already present on machine
Normal   Created    13m                   kubelet            Created container: init-leases
Normal   Started    13m                   kubelet            Started container init-leases
Warning  Failed     10m (x6 over 13m)     kubelet            Error: failed to create containerd task: failed to create shim task: OCI runtime create failed: runc create failed: unable to start container process: error during container init: exec: "eth0": executable file not found in $PATH
Warning  BackOff    3m34s (x47 over 13m)  kubelet            Back-off restarting failed container isc-dhcp in pod dhcp-server-4tq7m_dhcp(759e9655-854e-4f9b-95e8-279555136677)
Normal   Pulled     3m7s (x8 over 13m)    kubelet            Container image "networkboot/dhcpd:latest" already present on machine
Normal   Created    3m7s (x8 over 13m)    kubelet            Created container: isc-dhcp


(a tu jest ok, kiedy wrocilem do obrazu networkboot/dhcpd:latest z Docker Hub):
Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
Normal  Scheduled  97s   default-scheduler  Successfully assigned dhcp/dhcp-server-qp6vh to k3s-master
Normal  Pulled     97s   kubelet            Container image "busybox:1.36" already present on machine
Normal  Created    97s   kubelet            Created container: init-leases
Normal  Started    96s   kubelet            Started container init-leases
Normal  Pulling    96s   kubelet            Pulling image "networkboot/dhcpd:latest"
Normal  Pulled     95s   kubelet            Successfully pulled image "networkboot/dhcpd:latest" in 1.247s (1.247s including waiting). Image size: 68312697 bytes.
Normal  Created    94s   kubelet            Created container: isc-dhcp
Normal  Started    94s   kubelet            Started container isc-dhcp



2. Logi zawierają "Listening on LPF/eth0"  -- oraz braku Not configured to listen on any interfaces!
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp -l app=dhcp-server -o jsonpath='{.items[0].metadata.name}')
# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp "$POD" --tail=100 | grep -i 'Listening on LPF'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    Listening on LPF/eth0/42:83:27:62:a5:54/172.17.0.0/16

Podgląd ciągły (przerwij Ctrl+C)
Zapisz nazwę poda
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp -l app=dhcp-server -o jsonpath='{.items[0].metadata.name}')
# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp "$POD" -f
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    You must add the 'docker run' option '--net=host' if you want to provide DHCP service to the host network.
    Internet Systems Consortium DHCP Server 4.4.1
    Copyright 2004-2018 Internet Systems Consortium.
    All rights reserved.
    For info, please visit https://www.isc.org/software/dhcp/
    Config file: /data/dhcpd.conf
    Database file: /data/dhcpd.leases
    PID file: /var/run/dhcpd.pid
    Wrote 0 leases to leases file.
    Listening on LPF/eth0/42:83:27:62:a5:54/172.17.0.0/16
    Sending on   LPF/eth0/42:83:27:62:a5:54/172.17.0.0/16
    Sending on   Socket/fallback/fallback-net
    Server starting service.

Szukaj linii typu: Listening on LPF/eth0/... oraz braku Not configured to listen on any interfaces!
# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp -l app=dhcp-server --tail=200 -f

3. Port 67/UDP otwarty w podzie (hostNetwork: true)
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'ss -lunp | grep ":67" || netstat -lunp | grep ":67" || echo "Brak wpisu dla 67/UDP"'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    sh: 1: ss: not found
    sh: 1: netstat: not found
    Brak wpisu dla 67/UDP

4. Plik `dhcpd.leases` istnieje i rośnie
Sprawdź obecność i rozmiar
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'ls -l /data/dhcpd.leases'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    -rw-r--r-- 1 root root 280 Nov 15 15:10 /data/dhcpd.leases


Sprawdź treść pliku konfiguracyjnego i plik leases w podzie
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp -l app=dhcp-server -o jsonpath="{.items[0].metadata.name}")
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'ls -l /data && echo "---" && cat /data/dhcpd.conf || true'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    total 12
    -rw-r--r-- 1 root root 239 Nov 15 15:10 dhcpd.conf
    -rw-r--r-- 1 root root 280 Nov 15 15:10 dhcpd.leases
    -rw-r--r-- 1 root root 219 Nov 15 15:10 dhcpd.leases~
    ---
    ddns-update-style none;
    default-lease-time 600;
    max-lease-time 7200;
    authoritative;

    subnet 172.17.0.0 netmask 255.255.0.0 {
    range 172.17.10.100 172.17.10.200;
    option routers 172.17.0.1;
    option domain-name-servers 8.8.8.8, 8.8.4.4;


Podejrzyj zawartość
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'tail -n 50 /data/dhcpd.leases || cat /data/dhcpd.leases'

(Opcjonalnie) Obserwuj wzrost rozmiaru co 5 s (przerwij Ctrl+C)
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'while true; do stat -c "%s bytes" /data/dhcpd.leases; sleep 5; done'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    280 bytes

Test ruchu DHCP (tcpdump na DISCOVER/OFFER/REQUEST/ACK)
# kubectl --kubeconfig=k3s-kubeconfig run dhcp-debug -n dhcp --rm -it \
--image=nicolaka/netshoot --overrides='{"spec":{"hostNetwork":true}}' -- \
sh -c 'tcpdump -ni eth0 port 67 or port 68'

(Opcjonalnie) Pod klienta próbujący pobrać lease (jeśli masz narzędzia)
# kubectl --kubeconfig=k3s-kubeconfig run dhcp-client -n dhcp --rm -it \
--image=alpine:3.19 --overrides='{"spec":{"hostNetwork":true}}' -- \
sh -c 'apk add --no-cache dhclient busybox-extras >/dev/null 2>&1 || true; dhclient -v eth0 || udhcpc -i eth0 -vv'




5. Zweryfikuj konfigurację i mounty
Zobacz szczegóły poda (Args, env, eventy)
# kubectl --kubeconfig=k3s-kubeconfig describe daemonset dhcp-server -n dhcp
# kubectl --kubeconfig=k3s-kubeconfig describe pod -n dhcp -l app=dhcp-server

6. Zobacz ConfigMap
# kubectl --kubeconfig=k3s-kubeconfig get cm dhcpd-config -n dhcp -o yaml
    data:
    dhcpd.conf: |-
    ddns-update-style none;
    default-lease-time 600;
    max-lease-time 7200;
    authoritative;

        subnet 172.17.0.0 netmask 255.255.0.0 {
          range 172.17.10.100 172.17.10.200;
          option routers 172.17.0.1;
          option domain-name-servers 8.8.8.8, 8.8.4.4;
        }
    kind: ConfigMap
    metadata:
    creationTimestamp: "2025-11-12T21:38:05Z"
    name: dhcpd-config
    namespace: dhcp
    resourceVersion: "11597"
    uid: d7d576c0-77dd-4591-9360-07a1d9589e31




Opcjonalnie: sprawdź nasłuch na porcie 67/UDP na węźle
W podzie (jeśli jest ss/netstat) lub na węźle
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp "$POD" -- sh -c 'ss -lunp | grep ":67" || netstat -lunp | grep ":67" || true'


Szybki pod do diagnostyki (tcpdump):
# kubectl --kubeconfig=k3s-kubeconfig run dhcp-debug -n dhcp --rm -it \
--image=nicolaka/netshoot --overrides='{"spec":{"hostNetwork":true}}' -- \
sh -c 'tcpdump -ni eth0 port 67 or port 68'

--------------  podsumowanie  -----------------
Serwer DHCP działa poprawnie:
✅ DaemonSet READY 1/1 – pod uruchomiony i gotowy
✅ Logi poprawne – Listening on LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16 oraz Server starting service.
✅ Plik dhcpd.leases istnieje – 280 bajtów (pusta baza, ponieważ nie było jeszcze żądań DHCP)
✅ ConfigMap poprawny – zakres 172.17.10.100-200, router 172.17.0.1, DNS 8.8.8.8, 8.8.4.4


-------------  co my tutaj zrobiliśmy  -----------------
Podsumowanie: Docker → K3s → DHCP Server
1. Instalacja Docker
   Zainstalowano Docker Engine na hoście (system Linux).
   Skonfigurowano podstawowe uprawnienia użytkownika do zarządzania kontenerami.
   Sprawdzono działanie: docker ps, docker run hello-world.
 
2. Instalacja K3s (lekki Kubernetes)
Zainstalowano K3s – minimalną dystrybucję Kubernetes bez balasta.
Uruchomiono klaster z jednym węzłem (master).
Pobrany kubeconfig z węzła → plik k3s-kubeconfig do lokalnego zarządzania klastrem:
# kubectl --kubeconfig=k3s-kubeconfig get nodes
    NAME         STATUS   ROLES           AGE     VERSION
    k3s-master   Ready    control-plane   4d21h   v1.34.1+k3s1
K3s działa w kontenerze Docker lub bezpośrednio na maszynie.

3. Stworzenie namespace dla DHCP
   Utworzono dedykowany namespace dhcp:
# kubectl --kubeconfig=k3s-kubeconfig create namespace dhcp


4. ConfigMap z konfiguracją DHCP
   Stworzono ConfigMap zawierający plik roles/dhcp_server/files/dhcpd.conf

Parametry:
Zakres adresów:   172.17.10.100  - 172.17.10.200;
Gateway: 172.17.0.1
DNS: Google Public DNS (8.8.8.8, 8.8.4.4)

Zastosowano:
# kubectl --kubeconfig=k3s-kubeconfig apply -f dhcpd-configmap.yaml


5. DaemonSet z serwerem DHCP
   Utworzono DaemonSet – zapewnia uruchomienie jednego poda na każdym węźle klastra.
   Kluczowe elementy YAML:
plik:   roles/dhcp_server/templates/daemonset.yaml.j2
zastosowano:
# kubectl --kubeconfig=k3s-kubeconfig apply -f dhcp-daemonset.yaml

    Użyto tu użyto obrazu:  localhost/isc-dhcp-server:latest   
    Można użyć obrazu networkboot/dhcpd:latest z Docker Hub. --> przyklad w roli dhcp_server_dockerhub
    hostNetwork: true – pod ma bezpośredni dostęp do interfejsów sieciowych węzła (potrzebne do DHCP).
    Montowanie ConfigMap do /data/dhcpd.conf w podzie.
    emptyDir do przechowywania pliku dhcpd.leases (tymczasowy, znika po usunięciu poda).

    Porównanie ról: (dhcp_server  i  dhcp_server_dockerhub)
    Cecha         | dhcp_server (lokalna)            | dhcp_server_dockerhub (Docker Hub)  
    --------------+----------------------------------+----------------------------------
    Obraz           localhost/isc-dhcp-server:latest   networkboot/dhcpd:latest
    DaemonSet       dhcp-server                        dhcp-server-dockerhub
    Namespace       dhcp                               dhcp-dockerhub
    Zakres IP       172.17.10.100–200                  172.17.20.100–200
    Źródło obrazu   Lokalny build                      Docker Hub (publiczny)
    DaemonSet       dhcp-server                        dhcp-server-dockerhub


6. Uruchomienie przez Ansible Playbook
   Stworzyliśmy playbook Ansible (deploy_dhcp_server.yml), który automatyzuje:
   Tworzenie namespace dhcp.
   Tworzenie ConfigMap z dhcpd.conf.
   Wdrożenie DaemonSet.
   Uruchomiono:
# ansible-playbook -i inventory deploy_dhcp_server.yml -e "dhcp_interface=eth0"

7. Weryfikacja działania
   ✅ 1. DaemonSet READY 1/1
# kubectl --kubeconfig=k3s-kubeconfig get daemonset dhcp-server -n dhcp
     NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE
     dhcp-server   1         1         1       1            1

    ✅ 2. Pod w stanie Running
# kubectl --kubeconfig=k3s-kubeconfig get pods -n dhcp -l app=dhcp-server -o wide
    NAME                READY   STATUS    RESTARTS        AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp-server-xlwwd   1/1     Running   2 (3h42m ago)   3h42m   172.17.0.2   k3s-master   <none>           <none>

    ✅ 3. Logi potwierdzają nasłuch
# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp -l app=dhcp-server --tail=100 | grep -i 'Listening'
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    Listening on LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16

    ✅ 4. Plik dhcpd.leases istnieje
# POD=$(kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp -l app=dhcp-server -o jsonpath='{.items[0].metadata.name}')
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp $POD -- ls -lh /data/dhcpd.leases
    -rw-r--r-- 1 root root 280 Nov 15 15:10 /data/dhcpd.leases

Plik rośnie po każdym zapytaniu DHCP (DISCOVER/REQUEST).

8. Kluczowe koncepcje
   Komponent         Rola
   Docker            Uruchamia kontenery (m.in. K3s).
   K3s               Lekki Kubernetes do zarządzania aplikacjami kontenerowymi.
   Namespace         Logiczny podział zasobów (dhcp).
   ConfigMap         Przechowuje plik konfiguracyjny dhcpd.conf.
   DaemonSet         Zapewnia uruchomienie jednego poda na każdym węźle.
   hostNetwork       Daje podowi bezpośredni dostęp do interfejsów sieciowych hosta (port 67/UDP).
   EmptyDir          Tymczasowy wolumen /data (znika po usunięciu poda).
   initContainer     Tworzy pusty plik dhcpd.leases przed startem głównego kontenera.

9. Podsumowanie – Czemu to działa?
   K3s uruchamia DaemonSet z hostNetwork: true.
   Pod dostaje bezpośredni dostęp do interfejsu eth0 węzła (172.17.0.x).
   Serwer ISC DHCP (networkboot/dhcpd) nasłuchuje na porcie 67/UDP.
   Konfiguracja z ConfigMap montowana jest do /data/dhcpd.conf w kontenerze.
   Plik dhcpd.leases zapisuje przydzielone adresy (początkowo pusty – 280 bajtów).
   InitContainer (busybox) tworzy plik lease przed startem głównego kontenera.
   Serwer odpowiada na zapytania DHCP klientów w sieci 172.17.0.0/16.

10. Test działania (opcjonalnie)
    Aby sprawdzić, czy DHCP faktycznie przydziela adresy:
    Uruchom klienta DHCP w sieci 172.17.x.x:

# kubectl --kubeconfig=k3s-kubeconfig run dhcp-client -n dhcp --rm -it \
--image=alpine:3.19 --overrides='{"spec":{"hostNetwork":true}}' -- \
sh -c 'apk add --no-cache dhclient; dhclient -v eth0'


Sprawdź plik dhcpd.leases – powinien rosnąć:
# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp $POD -- cat /data/dhcpd.leases
    Defaulted container "isc-dhcp" out of: isc-dhcp, init-leases (init)
    # The format of this file is documented in the dhcpd.leases(5) manual page.
    # This lease file was written by isc-dhcp-4.4.1

    # authoring-byte-order entry is generated, DO NOT DELETE
    authoring-byte-order little-endian;

    lease 172.17.10.100 {
    starts 6 2025/11/15 19:02:49;
    ends 6 2025/11/15 19:12:49;
    cltt 6 2025/11/15 19:02:49;
    binding state active;
    next binding state free;
    rewind binding state free;
    hardware ethernet d2:c9:83:06:53:e7;
    }


Obserwuj pakiety DHCP (tcpdump):
# kubectl --kubeconfig=k3s-kubeconfig run dhcp-debug -n dhcp --rm -it \
--image=nicolaka/netshoot --overrides='{"spec":{"hostNetwork":true}}' -- \
tcpdump -ni eth0 port 67 or port 68

Jeśli widzisz DHCP Discover, DHCP Offer, DHCP Request, DHCP ACK → wszystko działa! 🎉


11. Następne kroki (opcjonalnie)
    Trwałe przechowywanie lease'ów: Zamień emptyDir na hostPath lub PersistentVolumeClaim (PVC).
    Monitoring: Dodaj Prometheus/Grafana do śledzenia stanu serwera.
    Skalowanie: Dodaj więcej węzłów → automatycznie uruchomi się pod DHCP na każdym.
 
To wszystko! Masz w pełni działający serwer DHCP w Kubernetes K3s, zarządzany przez Ansible. 🚀


-------------------------  Some OLD checkings -----------------

Sprawdź namespace dhcp (jeśli został utworzony)
# kubectl --kubeconfig=k3s-kubeconfig get daemonset -n dhcp

    NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    dhcp-server   1         1         0       1            0           <none>          2m35s


Zobacz wszystkie namespacey
# kubectl --kubeconfig=k3s-kubeconfig get namespaces

    NAME               STATUS   AGE
    default            Active   2d1h
    dhcp               Active   7m49s
    hello-kubernetes   Active   47h
    hello-world        Active   2d
    ingress-nginx      Active   2d1h
    kube-node-lease    Active   2d1h
    kube-public        Active   2d1h
    kube-system        Active   2d1h

# Sprawdź pod namespace = dhcp
kubectl --kubeconfig=k3s-kubeconfig get pods -A | grep dhcp

    dhcp    dhcp-server-dnf8s     0/1     ImagePullBackOff   11 (8m9s ago)   2d15h


-------------------------------------------------------
Sprawdź pody
# kubectl --kubeconfig=k3s-kubeconfig get pods -o wide

(ansible-venv) jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ kubectl --kubeconfig=k3s-kubeconfig get pods -o wide
No resources found in default namespace.

Sprawdź logi
# kubectl --kubeconfig=k3s-kubeconfig logs -l app=dhcp-server -f

Sprawdź DaemonSet
# kubectl --kubeconfig=k3s-kubeconfig get daemonset dhcp-server