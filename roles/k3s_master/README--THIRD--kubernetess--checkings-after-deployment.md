Szybka procedura diagnostyczna i naprawcza:
Sprawdź stan podów i ewentualne błędy:


////////////////////////////  Na lokalnym hoście  //////////////////////////////////
sprawdź klienta kubectl (lokalnie)
# kubectl version --client
    Client Version: v1.34.1
    Kustomize Version: v5.7.1

1) Sprawdź i użyj wbudowanego k3s kubectl (jeśli jest)
   Czemu to ważne? Potwierdzasz, że k3s działa wewnątrz kontenera.
# docker exec -it k3s-master bash -c 'command -v k3s >/dev/null && k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -A || echo "k3s binary not found"'

    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    kube-system   coredns-7896679cc-dvxqk                   1/1     Running   0          106s
    kube-system   local-path-provisioner-578895bd58-pb5fr   1/1     Running   0          106s
    kube-system   metrics-server-7b9c9c4b9c-xf65t           1/1     Running   0          106s

opis:
coredns — serwer DNS dla klastra
local-path-provisioner — zapewnia dynamiczne wolumeny (PersistentVolumes)
metrics-server — zbiera metryki zużycia CPU/RAM

2) Zalecane: skopiuj kubeconfig na localnego wsl hosta i użyj lokalnego kubectl
   Czemu to ważne? Teraz kubectl na hoście może łączyć się z k3s działającym w kontenerze.
# docker cp k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s-kubeconfig
    Successfully copied 4.61kB to /home/jacek/dev/ansible-kubernetess-K3S/k3s-kubeconfig

# chmod 600 ./k3s-kubeconfig


3) sprawdź czy port 6443 jest wystawiony na hoście
   Wynik: 0.0.0.0:6443 — port jest zmapowany na hosta.
   Co to znaczy?
   API k3s nasłuchuje na localhost:6443 (host WSL).
   Możesz łączyć się bezpośrednio przez https://localhost:6443
 
# docker port k3s-master 6443 || true
    0.0.0.0:6443
    [::]:6443


3a) --------------- jeśli widzisz 0.0.0.0:6443, użyj localhost:6443 w k3s-kubeconfig.
# sed -i 's/127.0.0.1:6443/localhost:6443/' ./k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig

Zastąpiłeś 127.0.0.1:6443 → localhost:6443 w pliku kubeconfig (choć to to samo, ale czasem localhost działa lepiej).
Ustawiłeś zmienną KUBECONFIG, żeby kubectl automatycznie używał tego pliku.

sprawdz NAMESPACE i PODy  (Wynik: Te same 3 pody — teraz widzisz je z lokalnego hosta, używając kubectl na WSL.)
# kubectl get pods -A

    NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
    kube-system   coredns-7896679cc-q68d7                   1/1     Running   0          14m
    kube-system   local-path-provisioner-578895bd58-4t997   1/1     Running   0          14m
    kube-system   metrics-server-7b9c9c4b9c-8t95f           1/1     Running   0          14m

alternatywnie:
3b) ---------------  Jeśli nie jest wystawiony port 6443, sprawdź IP kontenera i użyj go:

znajdź IP kontenera (użyj tego IP w kubeconfig)
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master
    172.17.0.2
 
# sed -i 's/127.0.0.1:6443/172.17.0.2:6443/' ./k3s-kubeconfig
# export KUBECONFIG=$PWD/k3s-kubeconfig
# kubectl get pods -A



4) Test połączenia i TLS:
# curl -vk https://localhost:6443
# curl -k https://localhost:6443/version
  
   no i dupa:  401
{
"kind": "Status",
"apiVersion": "v1",
"metadata": {},
"status": "Failure",
"message": "Unauthorized",
"reason": "Unauthorized",
"code": 401
}

Wynik: 401 Unauthorized — API wymaga certyfikatu klienta.
Czemu to ważne? Potwierdziłeś, że:
API działa (nie ma błędu połączenia).
TLS działa (HTTPS połączenie się nawiązało).
Brak autoryzacji (potrzebujesz certyfikatu klienta).
 go to -> Ekstrakcja certyfikatów z kubeconfig (kroki: 5 - 9)


lub jeśli masz certy z kubeconfig:
# curl --cacert ca.crt --cert client.crt --key client.key https://localhost:6443/version
 
    curl: (60) SSL certificate problem: self-signed certificate in certificate chain
    More details here: https://curl.se/docs/sslcerts.html

    curl failed to verify the legitimacy of the server and therefore could not
    establish a secure connection to it. To learn more about this situation and
    how to fix it, please visit the web page mentioned above.

 ------   poprawa ------

5) sprawdź węzły (NODES) i status klastra
# kubectl get nodes
    NAME         STATUS   ROLES           AGE   VERSION
    k3s-master   Ready    control-plane   10m   v1.34.1+k3s1

Co to znaczy?
Masz 1 węzeł (k3s-master) z rolą control-plane (master node).
Status Ready — węzeł jest zdrowy i gotowy do uruchamiania podów.


Sprawdzenie komponentów klastra
# kubectl get cs || true
    Warning: v1 ComponentStatus is deprecated in v1.19+
    NAME                 STATUS    MESSAGE   ERROR
    etcd-0               Healthy   ok
    controller-manager   Healthy   ok
    scheduler            Healthy   ok

etcd-0, controller-manager, scheduler — wszystkie Healthy.
Ostrzeżenie: ComponentStatus jest przestarzałe od v1.19 (ale nadal działa).
Czemu to ważne? Wszystkie kluczowe komponenty klastra działają poprawnie.



6) sprawdź zdarzenia i opis dla namespace kube-system
# kubectl get events -A --sort-by='.metadata.creationTimestamp'
# kubectl -n kube-system describe pod <POD_NAME>
examples: mamy 3 pody w kube-system
# kubectl -n kube-system describe pod coredns-7896679cc-s9frv
# kubectl -n kube-system describe pod local-path-provisioner-578895bd58-4t997
# kubectl -n kube-system describe pod metrics-server-7b9c9c4b9c-8t95f


7) podejrzyj logi problematycznych podów (wszystkie kontenery)
# kubectl logs -n <NAMESPACE> <POD_NAME> --all-containers

8) sprawdź services (usługi) i endpointy (np. kontroler ingress)
# kubectl get svc -A
    NAMESPACE     NAME             TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)                  AGE
    default       kubernetes       ClusterIP   10.43.0.1     <none>        443/TCP                  12m
    kube-system   kube-dns         ClusterIP   10.43.0.10    <none>        53/UDP,53/TCP,9153/TCP   12m
    kube-system   metrics-server   ClusterIP   10.43.254.7   <none>        443/TCP                  12m

kubernetes — API serwer (ClusterIP 10.43.0.1).
kube-dns — DNS dla podów (port 53).
metrics-server — metryki CPU/RAM.
Czemu to ważne? Podstawowe usługi systemowe działają.


Próba sprawdzenia Ingress Controller
# kubectl describe svc my-ingress-ingress-nginx-controller -n kube-system
    Error from server (NotFound): services "my-ingress-ingress-nginx-controller" not found

Co to znaczy?
Może być zainstalowany w innym namespace (np. ingress-nginx).
Może mieć inną nazwę.
Może nie być jeszcze zainstalowany.
Jak to naprawić?
kubectl get svc -A | grep ingress
Jeśli nic nie widzisz — Ingress Controller nie jest zainstalowany. Trzeba go dodać ręcznie lub przez playbook.



9) Ekstrakcja certyfikatów z kubeconfig. Wyodrębnij i zdekoduj certy z kubeconfig używając lokalnego kubectl
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt
# kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key
# chmod 600 client.key

Co zrobiłeś:
Wyciągnąłeś 3 certyfikaty z kubeconfig (są tam zakodowane w base64):
ca.crt — certyfikat CA (Certificate Authority) — weryfikuje tożsamość serwera API.
client.crt — certyfikat klienta — Twoja tożsamość.
client.key — klucz prywatny klienta — używany do podpisywania żądań.
Czemu to ważne? Te 3 pliki pozwalają Ci bezpośrednio uwierzytelnić się w API (np. przez curl).
 
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

Co zrobiłeś:
Wysłałeś zapytanie do endpoint /version API z poprawnym uwierzytelnieniem.
API rozpoznało Cię jako zaufanego klienta i zwróciło wersję k3s.
Czemu to ważne? Sukces — TLS + uwierzytelnienie klienta działają poprawnie!
 


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

# sudo snap install jq


# kubectl --kubeconfig=./k3s-kubeconfig version -o json | jq -r '.serverVersion.gitVersion'
v1.34.1+k3s1