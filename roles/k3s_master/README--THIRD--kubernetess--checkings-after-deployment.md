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


3) sprawdź czy port 6443 jest wystawiony na hoście
# docker port k3s-master 6443 || true
    0.0.0.0:6443
    [::]:6443


3a) --------------- jeśli widzisz 0.0.0.0:6443, użyj localhost:6443 w k3s-kubeconfig.
# sed -i 's/127.0.0.1:6443/localhost:6443/' ./k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A

    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    kube-system   coredns-7896679cc-s9frv                   1/1     Running   0          27m
    kube-system   local-path-provisioner-578895bd58-qxqqd   1/1     Running   0          27m
    kube-system   metrics-server-7b9c9c4b9c-j6d2k           1/1     Running   0          27m

3b) ---------------  Jeśli nie jest wystawiony, sprawdź IP kontenera i użyj go:

znajdź IP kontenera (użyj tego IP w kubeconfig)
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master
    172.17.0.2
 
# sed -i 's/127.0.0.1:6443/172.17.0.2:6443/' ./k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A



4) Test połączenia i TLS:
# curl -vk https://localhost:6443
# curl -k https://localhost:6443/version
  
   no i dupa:
{
"kind": "Status",
"apiVersion": "v1",
"metadata": {},
"status": "Failure",
"message": "Unauthorized",
"reason": "Unauthorized",
"code": 401
}

lub jeśli masz certy z kubeconfig:
# curl --cacert ca.crt --cert client.crt --key client.key https://localhost:6443/version

 ------   poprawa ------

5) sprawdź węzły i status klastra
# kubectl get nodes
    NAME         STATUS   ROLES           AGE   VERSION
    k3s-master   Ready    control-plane   10m   v1.34.1+k3s1

# kubectl get cs || true
    Warning: v1 ComponentStatus is deprecated in v1.19+
    NAME                 STATUS    MESSAGE   ERROR
    etcd-0               Healthy   ok
    controller-manager   Healthy   ok
    scheduler            Healthy   ok

6) sprawdź zdarzenia i opis dla namespace kube-system
# kubectl get events -A --sort-by='.metadata.creationTimestamp'
# kubectl -n kube-system describe pod <POD_NAME>

7) podejrzyj logi problematycznych podów (wszystkie kontenery)
# kubectl logs -n <NAMESPACE> <POD_NAME> --all-containers

8) sprawdź usługi i endpointy (np. kontroler ingress)
# kubectl get svc -A
    NAMESPACE     NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
    default       kubernetes       ClusterIP   10.43.0.1     <none>        443/TCP                  12m
    kube-system   kube-dns         ClusterIP   10.43.0.10    <none>        53/UDP,53/TCP,9153/TCP   12m
    kube-system   metrics-server   ClusterIP   10.43.254.7   <none>        443/TCP                  12m

# kubectl describe svc my-ingress-ingress-nginx-controller -n ingress-nginx
    Error from server (NotFound): namespaces "ingress-nginx" not found

9) Wyodrębnij i zdekoduj certy z kubeconfig używając lokalnego kubectl
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key
# chmod 600 client.key

 
10) Test uwierzytelnionego zapytania do API
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


Sukces — zapytanie z certyfikatem klienta zakończyło się powodzeniem i API zwróciło wersję k3s v1.34.1+k3s1. 
Oznacza to, że TLS oraz uwierzytelnienie klienta działają. 
Poprzednie 401 występowało, bo brakowało certyfikatu klienta (-k tylko wyłącza weryfikację certyfikatu, nie zapewnia autoryzacji).




Dodatkowe sprawdzenia wersji:

11) Pełna wersja (client + server)
# kubectl --kubeconfig=./k3s-kubeconfig version
    Client Version: v1.34.1
    Kustomize Version: v5.7.1
    Server Version: v1.34.1+k3s1

12) Wersja server w formacie JSON (może być potrzebne -o zamiast --output)
# kubectl --kubeconfig=./k3s-kubeconfig version -o json

13) Wyciągnij tylko gitVersion z JSON
# kubectl --kubeconfig=./k3s-kubeconfig version -o json | jq -r '.serverVersion.gitVersion'
    Command 'jq' not found, but can be installed with:
    sudo snap install jq  # version 1.5+dfsg-1, or
    sudo apt  install jq  # version 1.7.1-3ubuntu0.24.04.1
    See 'snap info jq' for additional versions.

 