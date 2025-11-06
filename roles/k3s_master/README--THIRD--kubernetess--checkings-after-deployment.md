Szybka procedura diagnostyczna i naprawcza:
Sprawdź stan podów i ewentualne błędy:


////////////////////////////  Na lokalnym hoście  //////////////////////////////////
sprawdź klienta kubectl (lokalnie)
# kubectl version --client
    Client Version: v1.34.1
    Kustomize Version: v5.7.1

1) Sprawdź i użyj wbudowanego k3s kubectl (jeśli jest)
# docker exec -it k3s-master bash -c 'command -v k3s >/dev/null && k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -A || echo "k3s binary not found"'

    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    kube-system   coredns-7896679cc-dvxqk                   1/1     Running   0          106s
    kube-system   local-path-provisioner-578895bd58-pb5fr   1/1     Running   0          106s
    kube-system   metrics-server-7b9c9c4b9c-xf65t           1/1     Running   0          106s


2) Zalecane: skopiuj kubeconfig na host i użyj lokalnego kubectl
# docker cp k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s-kubeconfig
    Successfully copied 4.61kB to /home/jacek/dev/ansible-kubernetess-K3S/k3s-kubeconfig

# chmod 600 ./k3s-kubeconfig


3) (jeśli w kubeconfig jest server: https://127.0.0.1:6443 -> zmień na adres dostępny z hosta)
    przykładowa zmiana (dostosuj IP):
# sed -i 's/127.0.0.1:6443/192.168.1.100:6443/' ./k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A
     E1029 22:03:04.715146   24126 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://192.168.1.100:6443/api?timeout=32s\": dial tcp 192.168.1.100:6443: i/o timeout"


 

4) znajdź IP kontenera (użyj tego IP w kubeconfig)
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master
    172.17.0.2

5) sprawdź czy port 6443 jest wystawiony na hoście
# docker port k3s-master 6443 || true
    0.0.0.0:6443
    [::]:6443

6) jeśli w kubeconfig jest server: https://127.0.0.1:6443 -> zamień na znalezione IP:6443
# sed -i 's/127.0.0.1:6443/CONTAINER_IP:6443/' ./k3s-kubeconfig

7) ustaw i użyj lokalnego kubectl
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A


8) skopiuj kubeconfig z kontenera
# docker cp k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s-kubeconfig
    Successfully copied 4.61kB to /home/jacek/dev/ansible-kubernetess-K3S/k3s-kubeconfig

# chmod 600 ./k3s-kubeconfig

9) sprawdź wartość server: w pliku
# grep '^  server:' -n ./k3s-kubeconfig || true

10) jeśli trzeba, zamień 127.0.0.1:6443 na localhost:6443 (host nasłuchuje na 0.0.0.0:6443)
# sed -i 's/127.0.0.1:6443/localhost:6443/' ./k3s-kubeconfig

11) ustaw kubeconfig i przetestuj
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A
    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    kube-system   coredns-7896679cc-dvxqk                   1/1     Running   0          9m3s
    kube-system   local-path-provisioner-578895bd58-pb5fr   1/1     Running   0          9m3s
    kube-system   metrics-server-7b9c9c4b9c-xf65t           1/1     Running   0          9m3s

12) szybki test API
# curl -k https://127.0.0.1:6443/version
    {
    "kind": "Status",
    "apiVersion": "v1",
    "metadata": {},
    "status": "Failure",
    "message": "Unauthorized",
    "reason": "Unauthorized",
    "code": 401
    }(

13) sprawdź węzły i status klastra
# kubectl get nodes
    NAME         STATUS   ROLES           AGE   VERSION
    k3s-master   Ready    control-plane   10m   v1.34.1+k3s1

# kubectl get cs || true
    Warning: v1 ComponentStatus is deprecated in v1.19+
    NAME                 STATUS    MESSAGE   ERROR
    etcd-0               Healthy   ok
    controller-manager   Healthy   ok
    scheduler            Healthy   ok

14) sprawdź zdarzenia i opis dla namespace kube-system
# kubectl get events -A --sort-by='.metadata.creationTimestamp'
# kubectl -n kube-system describe pod <POD_NAME>

14) podejrzyj logi problematycznych podów (wszystkie kontenery)
# kubectl logs -n <NAMESPACE> <POD_NAME> --all-containers

15) sprawdź usługi i endpointy (np. kontroler ingress)
# kubectl get svc -A
    NAMESPACE     NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
    default       kubernetes       ClusterIP   10.43.0.1     <none>        443/TCP                  12m
    kube-system   kube-dns         ClusterIP   10.43.0.10    <none>        53/UDP,53/TCP,9153/TCP   12m
    kube-system   metrics-server   ClusterIP   10.43.254.7   <none>        443/TCP                  12m

# kubectl describe svc my-ingress-ingress-nginx-controller -n ingress-nginx
    Error from server (NotFound): namespaces "ingress-nginx" not found

16) jeśli chcesz testować dostęp do serwisów z hosta
# curl -k https://127.0.0.1:6443/version
{
"kind": "Status",
"apiVersion": "v1",
"metadata": {},
"status": "Failure",
"message": "Unauthorized",
"reason": "Unauthorized",
"code": 401
}

17) test ingress (dostosuj host/port)
# curl -v http://localhost/

* Host localhost:80 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:80...
* connect to ::1 port 80 from ::1 port 35666 failed: Connection refused
*   Trying 127.0.0.1:80...
* connect to 127.0.0.1 port 80 from 127.0.0.1 port 40832 failed: Connection refused
* Failed to connect to localhost port 80 after 1 ms: Couldn't connect to server
* Closing connection
  curl: (7) Failed to connect to localhost port 80 after 1 ms: Couldn't connect to server


18) jeśli chcesz mieć kubeconfig globalnie dostępny na hoście:
# mkdir -p ~/.kube

19) zachowaj backup jeśli istnieje
[ -f ~/.kube/config ] && mv ~/.kube/config ~/.kube/config.bak
kubectl config view --flatten --minify > ~/.kube/config
chmod 600 ~/.kube/config


20) Wyodrębnij i zdekoduj certy z kubeconfig używając lokalnego kubectl
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key
# chmod 600 client.key

21) Teraz wykonaj zapytanie uwierzytelnione klientem
# curl --cacert ca.crt --cert client.crt --key client.key https://127.0.0.1:6443/version

{
"major": "1",
"minor": "34",
"emulationMajor": "1",
"emulationMinor": "34",
"minCompatibilityMajor": "1",
"minCompatibilityMinor": "33",
"gitVersion": "v1.34.1+k3s1",
"gitCommit": "24fc436e6ea59c56ebc37727baa4e6c9a201ee01",
"gitTreeState": "clean",
"buildDate": "2025-09-22T21:39:43Z",
"goVersion": "go1.24.6",
"compiler": "gc",
"platform": "linux/amd64"
}


22) Alternatywa: użyj kubectl (już działa) zamiast ręcznego curl
# kubectl --kubeconfig=./k3s-kubeconfig version --short
    error: unknown flag: --short
    See 'kubectl version --help' for usage.


23) Pełna wersja (client + server)
# kubectl --kubeconfig=./k3s-kubeconfig version
    Client Version: v1.34.1
    Kustomize Version: v5.7.1
    Server Version: v1.34.1+k3s1

24) Wersja server w formacie JSON (może być potrzebne -o zamiast --output)
# kubectl --kubeconfig=./k3s-kubeconfig version -o json

25) Wyciągnij tylko gitVersion z JSON
# kubectl --kubeconfig=./k3s-kubeconfig version -o json | jq -r '.serverVersion.gitVersion'
    Command 'jq' not found, but can be installed with:
    sudo snap install jq  # version 1.5+dfsg-1, or
    sudo apt  install jq  # version 1.7.1-3ubuntu0.24.04.1
    See 'snap info jq' for additional versions.

26) Alternatywa bez kubectl — bezpośrednie zapytanie API używając certyfikatów wyekstrahowanych z `k3s-kubeconfig`
# curl --cacert ca.crt --cert client.crt --key client.key https://127.0.0.1:6443/version
    {
    "major": "1",
    "minor": "34",
    "emulationMajor": "1",
    "emulationMinor": "34",
    "minCompatibilityMajor": "1",
    "minCompatibilityMinor": "33",
    "gitVersion": "v1.34.1+k3s1",
    "gitCommit": "24fc436e6ea59c56ebc37727baa4e6c9a201ee01",
    "gitTreeState": "clean",
    "buildDate": "2025-09-22T21:39:43Z",
    "goVersion": "go1.24.6",
    "compiler": "gc",
    "platform": "linux/amd64"
    }

