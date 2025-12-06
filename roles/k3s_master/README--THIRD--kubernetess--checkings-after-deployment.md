Szybka procedura diagnostyczna i naprawcza:
Sprawdź stan podów i ewentualne błędy:


////////////////////////////  Na lokalnym hoście  //////////////////////////////////
sprawdź klienta kubectl (lokalnie)
# kubectl version --client
    Client Version: v1.34.1
    Kustomize Version: v5.7.1

1) Sprawdź i użyj wbudowanego k3s kubectl (jeśli jest)
   Czemu to ważne? Potwierdzasz, że k3s działa wewnątrz kontenera.

-------------  Restart kontenera Docker  --------------
jeżeli zrestartowałeś kontener Dockera (np. restart laptopa), uruchom "kubectl k3s" wewnątrz kontenera dockera:
# docker exec -it k3s-master bash
    nohup /usr/local/bin/k3s server --write-kubeconfig-mode 644 > /var/log/k3s.log 2>&1 &
    (trzeba poczekać minutę lub dwie na pełne uruchomienie k3s)
    exit

Bash - diagnostyka i naprawa kubectl -> k3s
Czy KUBECONFIG jest ustawione?
# echo "KUBECONFIG=$KUBECONFIG"


a to umozliwi użycie k3s kubectl poza dockerowym kontenerem, czyli na local hoście.
# export KUBECONFIG=$PWD/k3s-kubeconfig
sprawdź pody w klastrze k3s:
# docker exec -it k3s-master bash -c 'command -v k3s >/dev/null && k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -A || echo "k3s binary not found"'
lub alternatywnie:
# kubectl get pods -A  (to zadziala, jak bedziedz mial ustawiony KUBECONFIG na k3s-kubeconfig i plik byl skopiowany lokalnie)
    NAMESPACE          NAME                                       READY   STATUS    RESTARTS        AGE
    hello-kubernetes   hello-kubernetes-app-2-84d5b6c48b-zw8cf    1/1     Running   1 (3m49s ago)   46h
    hello-world        hello-world-7f86d974d5-2qfp2               1/1     Running   1 (3m49s ago)   47h
    ingress-nginx      ingress-nginx-controller-565c7596d-swhj5   1/1     Running   1 (3m49s ago)   2d
    kube-system        coredns-7896679cc-8tk9c                    1/1     Running   1 (3m49s ago)   2d
    kube-system        local-path-provisioner-578895bd58-kthsk    1/1     Running   1 (3m49s ago)   2d
    kube-system        metrics-server-7b9c9c4b9c-kqs8m            1/1     Running   1 (3m49s ago)   2d

opis:
ingress-nginx/ingress-nginx-controller-... — Ingress Controller (odpowiada za routing HTTP/HTTPS do usług). 
                                             1/1 Running 0 oznacza, że kontroler jest uruchomiony i zdrowy.
kube-system/coredns-... — DNS klastra (rozwiązywanie nazw usług/podów). 
                          1/1 Running 0 = działa poprawnie.
kube-system/local-path-provisioner-... — dostawca wolumenów lokalnych (dynamiczne PV). 
                                         1/1 Running 0 = działa.
kube-system/metrics-server-... — zbiera metryki CPU/RAM dla klastra. 
                                 1/1 Running 0 = działa.

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

sprawdz NAMESPACE i PODy  (Wynik: Te same 4 pody — ale teraz widzisz je z lokalnego hosta, używając kubectl na WSL.)
# kubectl get pods -A

    NAMESPACE          NAME                                       READY   STATUS    RESTARTS      AGE
    hello-kubernetes   hello-kubernetes-app-2-84d5b6c48b-zw8cf    1/1     Running   1 (15m ago)   46h
    hello-world        hello-world-7f86d974d5-2qfp2               1/1     Running   1 (15m ago)   47h
    ingress-nginx      ingress-nginx-controller-565c7596d-swhj5   1/1     Running   1 (15m ago)   2d
    kube-system        coredns-7896679cc-8tk9c                    1/1     Running   1 (15m ago)   2d
    kube-system        local-path-provisioner-578895bd58-kthsk    1/1     Running   1 (15m ago)   2d
    kube-system        metrics-server-7b9c9c4b9c-kqs8m            1/1     Running   1 (15m ago)   2d

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

    NAMESPACE          NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    default            kubernetes                           ClusterIP   10.43.0.1       <none>        443/TCP                      2d
    hello-kubernetes   hello-kubernetes-app-2               NodePort    10.43.109.110   <none>        80:30082/TCP                 46h
    hello-world        hello-world                          ClusterIP   10.43.158.198   <none>        80/TCP                       47h
    ingress-nginx      ingress-nginx-controller             NodePort    10.43.149.107   <none>        80:30104/TCP,443:32352/TCP   2d
    ingress-nginx      ingress-nginx-controller-admission   ClusterIP   10.43.40.61     <none>        443/TCP                      2d
    kube-system        kube-dns                             ClusterIP   10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       2d
    kube-system        metrics-server                       ClusterIP   10.43.32.117    <none>        443/TCP                      2d

Krótko o kolumnach: 
NAMESPACE (przestrzeń nazw), 
NAME (nazwa serwisu), 
TYPE (typ expose), 
CLUSTER-IP (wewnętrzny adres), 
EXTERNAL-IP (adres zewn.), 
PORT(S) (porty usługi :nodePort), 
AGE (wiek).

Opis serwisów:
default/kubernetes — ClusterIP 10.43.0.1 port 443
To wewnętrzny serwis API serwera Kubernetesa. Dostępny tylko z wnętrza klastra (pods, kontrolery) lub przez kubeconfig/tunel.

ingress-nginx/ingress-nginx-controller — NodePort 10.43.149.107 porty 80:30104/TCP, 443:32352/TCP
Główny Ingress Controller. 
Usługa przekierowuje ruch HTTP/HTTPS do odpowiednich Ingressów. 
Brak EXTERNAL-IP oznacza, że nie ma LoadBalancer\‑a — ruch z zewnątrz można kierować na dowolny nodeIP:30104 (HTTP) lub nodeIP:32352 (HTTPS).

ingress-nginx/ingress-nginx-controller-admission — ClusterIP 10.43.40.61 port 443
Webhook/admission service używany przez kontroler ingress do walidacji/zarządzania certyfikatami. Tylko wewnętrzne użycie.

kube-system/kube-dns — ClusterIP 10.43.0.10 porty 53/UDP, 53/TCP, 9153/TCP
CoreDNS — rozwiązywanie nazw w klastrze (usługi/pody). Port 9153 to endpoint metryk/dla debugu.

kube-system/metrics-server — ClusterIP 10.43.32.117 port 443
Zbiera metryki CPU/Memory dla HPA i kubectl top. Tylko dostęp wewnątrz klastra.

Uwagi praktyczne:
ClusterIP są dostępne tylko wewnątrz klastra; 
aby dostać się z zewnątrz, użyj NodePort, LoadBalancer lub port‑forwarding.
Brak EXTERNAL-IP nie oznacza błędu — po prostu brak zewnętrznego LB.

ingress-nginx   ingress-nginx-controller             NodePort    10.43.161.247   <none>        80:30960/TCP,443:32160/TCP   32m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP   10.43.17.53     <none>        443/TCP                      32m

Próba sprawdzenia Ingress Controller
# kubectl describe svc ingress-nginx-controller -n kube-system
    Error from server (NotFound): services "ingress-nginx-controller" not found
# kubectl describe svc ingress-nginx-controller-admission -n kube-system
    Error from server (NotFound): services "ingress-nginx-controller-admission" not found

Co to znaczy?
Może być zainstalowany w innym namespace (np. Ingress Nginx).
Może mieć inną nazwę.
Może nie być jeszcze zainstalowany.
Jak to naprawić?
Sprawdź wszystkie serwisy i znajdź ingress-nginx:
# kubectl get svc -A | grep ingress
Jeśli nic nie widzisz — Ingress Controller nie jest zainstalowany. Trzeba go dodać ręcznie lub przez playbook.

    ingress-nginx   ingress-nginx-controller             NodePort    10.43.161.247   <none>        80:30960/TCP,443:32160/TCP   37m
    ingress-nginx   ingress-nginx-controller-admission   ClusterIP   10.43.17.53     <none>        443/TCP                      37m



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

10)
Test uwierzytelnionego zapytania do API - tj. test połączenia i TLS:

 - użyj kubectl z kubeconfig
# kubectl --kubeconfig=./k3s-kubeconfig version
    Client Version: v1.34.1
    Kustomize Version: v5.7.1
    Server Version: v1.34.1+k3s1

 - curl z certyfikatem klienta
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


-----------------------  podsumowanie  -----------------------
Przeprowadziłeś kompleksową diagnostykę klastra k3s działającego w kontenerze Docker.
Sprawdziłeś stan podów, usług, węzłów oraz komponentów klastra.
Zweryfikowałeś działanie TLS i uwierzytelnianie klienta za pomocą certyfikatów wyodrębnionych z kubeconfig.
Wszystkie kluczowe elementy klastra działają poprawnie, a zapytania do API są uwierzytelniane.
Masz teraz solidną podstawę do dalszej pracy z Kubernetes i wdrażania aplikacji w klastrze k3s. 
////////////////////////////////////////////////////////////////////////////////

Stan aktualny (rola k3s_master uruchomiona) — zwięzłe podsumowanie:
K3s master działa (kontener/instancja uruchomiona zgodnie z rolą roles/k3s_master).
Wersja serwera: v1.34.1+k3s1 (potwierdzone przez GET /version z certyfikatem klienta).
Podstawowe komponenty klastra uruchomione i zdrowe (kubectl get pods -A):
ingress-nginx — Ingress Controller (1/1 Running).
kube-system/coredns — DNS klastra (1/1 Running).
kube-system/local-path-provisioner — provisioner wolumenów lokalnych (1/1 Running).
kube-system/metrics-server — zbieranie metryk (1/1 Running).
Serwisy (kubectl get svc -A):
default/kubernetes — ClusterIP 10.43.0.1:443 (wewnętrzny API server).
ingress-nginx/ingress-nginx-controller — NodePort 10.43.149.107 z mapowaniem 80:30104/TCP, 443:32352/TCP — dostęp do Ingress z zewnątrz przez NODE_IP:30104 (HTTP) i NODE_IP:32352 (HTTPS).
ingress-nginx-controller-admission — ClusterIP webhook (wewnętrzny).
kube-dns — ClusterIP 10.43.0.10 (DNS; porty 53 UDP/TCP, 9153 metryki).
metrics-server — ClusterIP (wewnętrzny).
Dostęp do API:
API na porcie 6443 wymaga uwierzytelnienia (client cert / token). curl --cacert ca.crt --cert client.crt --key client.key https://localhost:6443/version działa — kubeconfig znajduje się standardowo w /etc/rancher/k3s/k3s.yaml (lub lokalny kubeconfig używany wcześniej).
Środowisko deweloperskie / repozytorium:
Praca w ~/dev/ansible-kubernetess-K3S, aktywowane ansible-venv.
README wskazuje kolejne role/etapy do uruchomienia (helm, deploy aplikacji, monitoring).
Krótko: podstawowy klaster K3s jest uruchomiony i zdrowy — DNS, ingress, storage i metrics działają; API jest zabezpieczone i dostępne po uwierzytelnieniu.