Poniżej szybkie komendy do weryfikacji i ponownego uruchomienia K3s oraz DHCP po restarcie.

1. Sprawdź kontener K3s
Sprawdź, czy kontener K3s żyje i odśwież kubeconfig:
czy działa kontener z K3s (np. `k3s-master`)
# docker ps --filter name=k3s
    CONTAINER ID   IMAGE              COMMAND                  CREATED      STATUS        PORTS                                                                                                                                                                NAMES
    1a628ad8df47   k3s-master-image   "/bin/bash /usr/loca…"   6 days ago   Up 22 hours   0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:6443->6443/tcp, [::]:6443->6443/tcp, 0.0.0.0:2222->22/tcp, [::]:2222->22/tcp   k3s-master


jeśli nie działa
# docker start k3s-master

i ...
2. Odśwież plik kubeconfig (jeśli mógł zniknąć)
# docker exec k3s-master cat /etc/rancher/k3s/k3s.yaml > k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig


//////////////////////////////////////////////////////////////////

3. Sprawdź stan klastra

# kubectl --kubeconfig=k3s-kubeconfig cluster-info
    Kubernetes control plane is running at https://localhost:6443
    CoreDNS is running at https://localhost:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
    Metrics-server is running at https://localhost:6443/api/v1/namespaces/kube-system/services/https:metrics-server:https/proxy

# kubectl --kubeconfig=k3s-kubeconfig get nodes
    NAME         STATUS   ROLES           AGE     VERSION
    k3s-master   Ready    control-plane   5d15h   v1.34.1+k3s1

# kubectl --kubeconfig=k3s-kubeconfig get pods -A -o wide
    NAMESPACE          NAME                                       READY   STATUS    RESTARTS      AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp               dhcp-server-xlwwd                          1/1     Running   2 (20h ago)   20h     172.17.0.2   k3s-master   <none>           <none>
    hello-kubernetes   hello-kubernetes-app-2-84d5b6c48b-zw8cf    1/1     Running   2 (21h ago)   5d12h   10.42.0.21   k3s-master   <none>           <none>
    hello-world        hello-world-7f86d974d5-2qfp2               1/1     Running   2 (21h ago)   5d13h   10.42.0.24   k3s-master   <none>           <none>
    ingress-nginx      ingress-nginx-controller-565c7596d-swhj5   1/1     Running   2 (21h ago)   5d15h   10.42.0.25   k3s-master   <none>           <none>
    kube-system        coredns-7896679cc-8tk9c                    1/1     Running   2 (21h ago)   5d15h   10.42.0.22   k3s-master   <none>           <none>
    kube-system        local-path-provisioner-578895bd58-kthsk    1/1     Running   2 (21h ago)   5d15h   10.42.0.23   k3s-master   <none>           <none>
    kube-system        metrics-server-7b9c9c4b9c-kqs8m            1/1     Running   2 (21h ago)   5d15h   10.42.0.20   k3s-master   <none>           <none>

//////////////////////////////////////////////////////////////////

5. Weryfikacja DHCP (DaemonSet + pod + logi)

znajdź DaemonSet i pody DHCP (dowolny namespace)
# kubectl --kubeconfig=k3s-kubeconfig get ds,po -A -l app=dhcp-server -o wide
    NAMESPACE   NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE     CONTAINERS   IMAGES                     SELECTOR
    dhcp        daemonset.apps/dhcp-server   1         1         1       1            1           <none>          3d14h   isc-dhcp     networkboot/dhcpd:latest   app=dhcp-server

    NAMESPACE   NAME                    READY   STATUS    RESTARTS      AGE   IP           NODE         NOMINATED NODE   READINESS GATES
    dhcp        pod/dhcp-server-xlwwd   1/1     Running   2 (20h ago)   20h   172.17.0.2   k3s-master   <none>           <none>


# kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp -l app=dhcp-server --tail=50
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
Listening on LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16
Sending on   LPF/eth0/d2:c9:83:06:53:e7/172.17.0.0/16
Sending on   Socket/fallback/fallback-net
Server starting service.
DHCPDISCOVER from d2:c9:83:06:53:e7 via eth0
DHCPOFFER on 172.17.10.100 to d2:c9:83:06:53:e7 via eth0
DHCPREQUEST for 172.17.10.100 (172.17.0.2) from d2:c9:83:06:53:e7 via eth0
Wrote 1 leases to leases file.
DHCPACK on 172.17.10.100 to d2:c9:83:06:53:e7 via eth0
reuse_lease: lease age 0 (secs) under 25% threshold, reply with unaltered, existing lease for 172.17.10.100
DHCPREQUEST for 172.17.10.100 (172.17.0.2) from d2:c9:83:06:53:e7 via eth0
DHCPACK on 172.17.10.100 to d2:c9:83:06:53:e7 via eth0


# kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp -l app=dhcp-server -- cat /data/dhcpd.leases

////////////////////////////////////////////////

6. Test działania DHCP (klient)

# kubectl --kubeconfig=k3s-kubeconfig run dhcp-test -n dhcp --rm -it   --image=alpine:3.19 --overrides='{"spec":{"hostNetwork":true}}' --   sh -c 'apk add --no-cache dhclient; dhclient -v eth0'
    All commands and output from this session will be recorded in container logs, 
        including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
(1/20) Installing coreutils-env (9.4-r2)
(2/20) Installing coreutils-fmt (9.4-r2)
(3/20) Installing coreutils-sha512sum (9.4-r2)
(4/20) Installing libacl (2.3.1-r4)
(5/20) Installing libattr (2.5.1-r5)
(6/20) Installing skalibs (2.14.0.1-r0)
(7/20) Installing utmps-libs (0.1.2.2-r0)
(8/20) Installing coreutils (9.4-r2)
(9/20) Installing libcap2 (2.69-r1)
(10/20) Installing zstd-libs (1.5.5-r8)
(11/20) Installing libelf (0.190-r1)
(12/20) Installing libmnl (1.0.5-r2)
(13/20) Installing iproute2-minimal (6.6.0-r0)
(14/20) Installing libxtables (1.8.10-r3)
(15/20) Installing iproute2-tc (6.6.0-r0)
(16/20) Installing iproute2-ss (6.6.0-r0)
(17/20) Installing iproute2 (6.6.0-r0)
Executing iproute2-6.6.0-r0.post-install
(18/20) Installing run-parts (4.11.2-r2)
(19/20) Installing libgcc (13.2.1_git20231014-r0)
(20/20) Installing dhclient (4.4.3_p1-r4)
Executing busybox-1.36.1-r20.trigger
OK: 14 MiB in 35 packages
Internet Systems Consortium DHCP Client 4.4.3-P1
Copyright 2004-2022 Internet Systems Consortium.
All rights reserved.
For info, please visit https://www.isc.org/software/dhcp/

RTNETLINK answers: Operation not permitted
Listening on LPF/eth0/d2:c9:83:06:53:e7
Sending on   LPF/eth0/d2:c9:83:06:53:e7
Sending on   Socket/fallback
DHCPDISCOVER on eth0 to 255.255.255.255 port 67 interval 5
DHCPOFFER of 172.17.10.100 from 172.17.0.2
DHCPREQUEST for 172.17.10.100 on eth0 to 255.255.255.255 port 67
DHCPACK of 172.17.10.100 from 172.17.0.2
RTNETLINK answers: Operation not permitted
mv: cannot move '/etc/resolv.conf.dhclient-new.lzs9PRdf0F' to '/etc/resolv.conf': Resource busy
bound to 172.17.10.100 -- renewal in 234 seconds.
Session ended, resume using 'kubectl attach dhcp-test -c dhcp-test -i -t' command when the pod is running
pod "dhcp-test" deleted from dhcp namespace


////////////////////////////////////////////////// 

Jeśli DHCP nie działa
# kubectl --kubeconfig=k3s-kubeconfig describe ds dhcp-server -n dhcp
# kubectl --kubeconfig=k3s-kubeconfig delete pod -n dhcp -l app=dhcp-server
# kubectl --kubeconfig=k3s-kubeconfig rollout restart ds/dhcp-server -n dhcp


7. Ponowne wdrożenie (jeśli pliki zniknęły):

ansible-playbook -i inventory deploy_dhcp_server.yml -e "dhcp_interface=eth0"


///////////////

8. Weryfikacja portów serwera API

ss -tlpn | grep 6443
curl -sk https://localhost:6443/healthz


///////////////////////

9. Sprawdzenie procesu w kontenerze K3s

docker exec k3s-master ps -ef | grep k3s
docker exec k3s-master journalctl -u k3s --no-pager | tail -50


/////////////////////////////////////

10. Szybka kontrola sieci

docker exec k3s-master ip addr show
kubectl --kubeconfig=k3s-kubeconfig get pod -n dhcp -l app=dhcp-server -o jsonpath='{.items[0].status.podIP}'


/////////////////////////////////////////

11. Typowe objawy problemów
* brak odpowiedzi cluster-info → kube-apiserver nie działa
* pod DHCP w CrashLoopBackOff → sprawdź logi
* brak pliku k3s-kubeconfig → odśwież z kontenera

////////////////////////////////////////


12. Minimalny restart całego środowiska (gdyby było źle)

docker restart k3s-master
sleep 10
docker exec k3s-master cat /etc/rancher/k3s/k3s.yaml > k3s-kubeconfig
kubectl --kubeconfig=k3s-kubeconfig get nodes
kubectl --kubeconfig=k3s-kubeconfig rollout restart ds/dhcp-server -n dhcp



/////////////////////////////////////////


13. Monitoring szybki (skrót)

watch -n5 'kubectl --kubeconfig=k3s-kubeconfig get nodes; kubectl --kubeconfig=k3s-kubeconfig get po -n dhcp'


////////////////////////////////////////

14. Czyszczenie zablokowanych locków DHCP (rzadko potrzebne)

kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp -l app=dhcp-server -- rm -f /var/run/dhcpd.pid
kubectl --kubeconfig=k3s-kubeconfig rollout restart ds/dhcp-server -n dhcp


//////////////////////////////////////////

15. Potwierdzenie wersji serwera DHCP

kubectl --kubeconfig=k3s-kubeconfig exec -n dhcp -l app=dhcp-server -- dhcpd --version


To wystarcza do pełnej weryfikacji i ewentualnego ponownego uruchomienia K3s oraz DHCP po restarcie.




















