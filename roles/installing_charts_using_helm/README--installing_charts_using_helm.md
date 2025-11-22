
Przeczytaj to: ansible-kubernetess-K3S\README__opis_podstawowych_pojęć_Kubernetesa.md

Ingress Nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy and Load-Balancer.

Helm nie jest częścią Ingress Nginx.
Helm to niezależne narzędzie (package manager dla Kubernetesa). 
Ingress Nginx to kontroler Ingress (zestaw manifestów/zasobów), który możesz zainstalować
np. przy pomocy Helma (Chart Ingress Nginx) lub bezpośrednio przez manifesty.

Przykład instalacji przez Helm (bash):

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig
 

Sprawdź wersję helma: (na lokalnym hoscie, nie w kontenerze):
$ helm version
version.BuildInfo{Version:"v3.19.2", GitCommit:"8766e718a0119851f10ddbe4577593a45fadf544", GitTreeState:"clean", GoVersion:"go1.24.9"}

 
------------------------------------- ten task tylko zainstaluje Helm na WSL -------------------------------------------------------
# ansible-playbook -i inventory/hosts.ini destroy_installing_charts_using_helm.yml --ask-become-pass    (jacek)
# ansible-playbook -i inventory/hosts.ini deploy_installing_charts_using_helm.yml --ask-become-pass    (jacek)

password na roota: jacek


lub 

Zrobimy to w bezpieczny sposób, tworząc dedykowany plik konfiguracyjny dla Twojego użytkownika.
Jak to zrobić?
W swoim terminalu WSL/Ubuntu wykonaj następującą komendę:

# sudo visudo -f /etc/sudoers.d/90-jacek

sudo visudo: To jest specjalne, bezpieczne narzędzie do edycji plików konfiguracyjaxcyjnych sudo. Zawsze go używaj!
-f /etc/sudoers.d/90-jacek: Mówi visudo, aby stworzył i edytował nowy plik o nazwie 90-jacek w specjalnym katalogu. Dzięki temu nie modyfikujemy głównego pliku sudoers i łatwo możemy cofnąć zmiany.
Po wykonaniu komendy otworzy się edytor tekstu (prawdopodobnie nano). Wklej do tego pliku jedną, jedyną linię:
 
jacek ALL=(ALL) NOPASSWD: ALL


jacek: Nazwa Twojego użytkownika.
ALL=(ALL): Może uruchamiać polecenia jako dowolny użytkownik.
NOPASSWD: ALL: Najważniejsza część. Może uruchamiać wszystkie polecenia (ALL) bez pytania o hasło.
Zapisz i zamknij plik:
W nano: Ctrl + X, następnie Y (aby potwierdzić zapis), a następnie Enter (aby potwierdzić nazwę pliku).
visudo sprawdzi składnię pliku przed zapisaniem. Jeśli wszystko jest w porządku, wróci do linii komend.
Weryfikacja
Aby sprawdzić, czy zmiana zadziałała, spróbuj uruchomić jakąś prostą komendę sudo, np.:
 
sudo ls /root

jeszcze raz bez hasła:
# ansible-playbook -i inventory/hosts.ini destroy_installing_charts_using_helm.yml
# ansible-playbook -i inventory/hosts.ini deploy_installing_charts_using_helm.yml

***********************************************************************************

Dodaj Ingress Nginx z repozytorium GitHuba/ingress-nginx
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

Objaśnienie komendy Helm:
---------------------------------------------------------------
helm  - CLI Helma, menedżera pakietów dla Kubernetesa.
repo  - Podkomenda do zarządzania repozytoriami chartów (lista, dodawanie, usuwanie, update).
add   - Akcja: dodaj nowe repozytorium do lokalnej konfiguracji Helma.
ingress-nginx  - Nazwa, jaką lokalnie nadajesz temu repozytorium:
- później używasz jej w komendach, np. ingress-nginx/ingress-nginx przy helm install
- jest to alias, możesz nazwać inaczej, ale wtedy używasz tej swojej nazwy.

https://kubernetes.github.io/ingress-nginx - URL repozytorium chartów:
- pod tym adresem Helm szuka pliku index.yaml z listą dostępnych chartów i wersji
- przy helm repo update Helm pobierze stamtąd aktualny indeks.
  Efekt końcowy: 
  w lokalnej konfiguracji Helma zapisuje się repo ingress-nginx wskazujące na podany URL, 
  dzięki czemu możesz później instalować chart ingress-nginx poprzez helm install ... ingress-nginx/ingress-nginx.

- # helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  dodaje konkretne repozytorium (tu: ingress-nginx).
  Możesz dodać inne repozytoria z innymi chartami, np.:

 
Prometheus
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

Grafana
# helm repo add grafana https://grafana.github.io/helm-charts

Odśwież wszystkie repo
# helm repo update

Instalacja Prometheusa (przykład)
# helm install my-prometheus prometheus-community/prometheus --namespace monitoring --create-namespace --kubeconfig=k3s-kubeconfig

Instalacja Grafany (przykład)
# helm install my-grafana grafana/grafana --namespace monitoring --create-namespace --kubeconfig=k3s-kubeconfig

-----------------------


Zaktualizuj listę dostępnych chartów
# helm repo update

```"ingress-nginx" already exists with the same configuration, skipping
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "grafana" chart repository (https://grafana.github.io/helm-charts):
 Get "https://grafana.github.io/helm-charts/index.yaml": read tcp 172.22.156.245:43654->185.199.111.153:443: read: connection reset by peer
...Unable to get an update from the "prometheus-community" chart repository (https://prometheus-community.github.io/helm-charts):
 Get "https://prometheus-community.github.io/helm-charts/index.yaml": read tcp 172.22.156.245:52896->185.199.108.153:443: read: connection reset by peer
...Successfully got an update from the "ingress-nginx" chart repository
Update Complete. ⎈Happy Helming!⎈
```
-----------------------   diagnostyka błędu:

1. Sprawdź po IPv4, czy w ogóle możesz pobrać index.yaml
# curl -v -4 https://kubernetes.github.io/ingress-nginx/index.yaml
# curl -v -4 https://grafana.github.io/helm-charts/index.yaml
# curl -v -4 https://prometheus-community.github.io/helm-charts/index.yaml

2. Wymuś konkretny IP (podaj jeden z `dig`)
#  curl -v --resolve kubernetes.github.io:443:185.199.110.153 https://kubernetes.github.io/ingress-nginx/index.yaml
#  curl -v --resolve grafana.github.io:443:185.199.110.153 https://grafana.github.io/helm-charts/index.yaml
#  curl -v --resolve prometheus-community.github.io:443:185.199.110.153 https://prometheus-community.github.io/helm-charts/index.yaml

--------->  to gówno raz dziala a raz nie dziala <---------
    (ansible-venv) jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ helm repo update
    Hang tight while we grab the latest from your chart repositories...
    ...Unable to get an update from the "grafana" chart repository (https://grafana.github.io/helm-charts):
    Get "https://grafana.github.io/helm-charts/index.yaml": read tcp 172.22.156.245:43020->185.199.109.153:443: read: connection reset by peer
    ...Successfully got an update from the "ingress-nginx" chart repository
    ...Successfully got an update from the "prometheus-community" chart repository


3. Sprawdź TLS/TCP bezpośrednio
# openssl s_client -connect grafana.github.io:443 -servername grafana.github.io
# openssl s_client -connect prometheus-community.github.io:443 -servername prometheus-community.github.io


4. Sprawdź proxy i DNS w WSL
env | grep -i proxy || true
cat /etc/resolv.conf


Sprawdź DNS
# dig +short kubernetes.github.io
    185.199.111.153
    185.199.109.153
    185.199.110.153
    185.199.108.153

# nslookup kubernetes.github.io
    Server:         10.255.255.254
    Address:        10.255.255.254#53

    Non-authoritative answer:
    Name:   kubernetes.github.io
    Address: 185.199.108.153
    Name:   kubernetes.github.io
    Address: 185.199.111.153
    Name:   kubernetes.github.io
    Address: 185.199.109.153
    Name:   kubernetes.github.io
    Address: 185.199.110.153
    Name:   kubernetes.github.io
    Address: 2606:50c0:8000::153
    Name:   kubernetes.github.io
    Address: 2606:50c0:8001::153
    Name:   kubernetes.github.io
    Address: 2606:50c0:8002::153
    Name:   kubernetes.github.io
    Address: 2606:50c0:8003::153

Sprawdź TCP/TLS do hosta (podaj IP z dig/nslookup jeśli trzeba)
# openssl s_client -connect kubernetes.github.io:443 -servername kubernetes.github.io

Śledzenie trasy (może wymagać instalacji traceroute)
# traceroute 185.199.109.153

Sprawdź czy masz ustawione proxy w środowisku
# env | grep -i proxy || true

Sprawdź lokalne reguły sieciowe w WSL/linuksie
# ip addr show
# sudo ufw status || true

Jeśli sieć działa, odśwież repozytoria helma
# helm repo remove ingress-nginx
    "ingress-nginx" has been removed from your repositories

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    "ingress-nginx" has been added to your repositories

# helm repo update
    (ansible-venv) jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ helm repo update
    Hang tight while we grab the latest from your chart repositories...
    ...Successfully got an update from the "ingress-nginx" chart repository
    ...Successfully got an update from the "prometheus-community" chart repository
    ...Successfully got an update from the "grafana" chart repository
    Update Complete. ⎈Happy Helming!⎈

Wygląda na to, że połączenia do serwerów GitHub Pages są przerywane (TCP RST) — przyczyny: problem z siecią/ISP, WSL, ściana ogniowa/proxy, 
  IPv6/MTU lub chwilowy błąd po stronie trasy. 
Uruchom poniższe polecenia diagnostyczne w WSL (kolejno) i sprawdź wyników — pokażą czy to DNS, IPv6/IPv4, trasa lub blokada.


# Sprawdź dostęp po IPv4
curl -v -4 https://kubernetes.github.io/ingress-nginx/index.yaml

# Wymuś połączenie do konkretnego IP (podaj IP z dig/nslookup)
curl -v --resolve kubernetes.github.io:443:185.199.111.153 https://kubernetes.github.io/ingress-nginx/index.yaml

# Sprawdź TLS/TCP bezpośrednio
openssl s_client -connect 185.199.111.153:443 -servername kubernetes.github.io

# Śledź trasę do hosta
traceroute 185.199.111.153

# Sprawdź ustawienia proxy i DNS
env | grep -i proxy || true
cat /etc/resolv.conf

# Test MTU (jeśli pakiety są obcinane)
ping -c 4 -M do -s 1472 185.199.111.153

# Włącz agresywniejsze MTU probing (doraźnie)
sudo sysctl -w net.ipv4.tcp_mtu_probing=1

# Sprawdź lokalne reguły sieciowe/firewall
sudo iptables -L -n
sudo ufw status || true

# Uruchom helm z debugiem (więcej logów)
HELM_DEBUG=1 helm repo update

# Dodatkowo sprawdź poza WSL (PowerShell/CMD) — czy problem występuje także tam
# (uruchom helm repo update w Windowsie)





 
# kubectl get ingressclass
    NAME    CONTROLLER             PARAMETERS   AGE
    nginx   k8s.io/ingress-nginx   <none>       6h22m

usuń istniejący IngressClass nginx
# kubectl delete ingressclass nginx --kubeconfig=k3s-kubeconfig

Zainstaluj Ingress Nginx  w swoim klastrze (pamiętaj o kubeconfig)
# helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig

Objaśnienie komendy Helm:
---------------------------------------------------------------
helm    - Program CLI, menedżer pakietów (chartów) dla Kubernetesa.
install - Akcja: zainstaluj nowy release z charta do klastra.
my-ingress - Nazwa releaseʼu Helma. Po instalacji wszystkie obiekty w klastrze będą miały etykiety/nazwy zawierające tę nazwę 
             (np. my-ingress-ingress-nginx-controller).
ingress-nginx/ingress-nginx - Skąd wziąć chart:
                ingress-nginx (przed slash) – nazwa repozytorium chartów, które wcześniej dodałeś helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
                ingress-nginx (za slash) – nazwa konkretnego charta w tym repo.
                Razem: weź chart ingress-nginx z repo ingress-nginx.
--namespace ingress-nginx  - Zainstaluj ten release do przestrzeni nazw Kubernetesa ingress-nginx.
                             Wszystkie Deploymenty, Serviceʼy itd. trafią do namespace ingress-nginx.
--create-namespace  - Jeśli namespace ingress-nginx jeszcze nie istnieje, utwórz go automatycznie przed instalacją.
                      Dzięki temu nie musisz wcześniej robić kubectl create namespace ingress-nginx.
--kubeconfig=k3s-kubeconfig  - Użyj konkretnego pliku kubeconfig (k3s-kubeconfig) zamiast domyślnego ~/.kube/config.
                               Tym wskazujesz, do którego klastra Kubernetes (tu: K3s) Helm ma się podłączyć i tam zainstalować release.
----------------------------------------------------------------------------------------------------------------------------------------------------------

Helm zainstalował Ingress Nginx poprawnie – masz teraz release my-ingress w namespace ingress-nginx.
Najważniejsze następne kroki:
Sprawdź zasoby kontrolera:
# kubectl get pods -n ingress-nginx
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6766768fbc-xb4z4   1/1     Running   0          5m12s

# kubectl get svc -n ingress-nginx
    NAME                                            TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    my-ingress-ingress-nginx-controller             LoadBalancer   10.43.187.220   172.17.0.2    80:31520/TCP,443:30916/TCP   5m38s
    my-ingress-ingress-nginx-controller-admission   ClusterIP      10.43.119.172   <none>        443/TCP                      5m38s

# kubectl get ingressclass
    NAME    CONTROLLER             PARAMETERS   AGE
    nginx   k8s.io/ingress-nginx   <none>       6m6s

Obserwuj Service kontrolera (czy ma IP / NodePort):
# kubectl get service --namespace ingress-nginx my-ingress-ingress-nginx-controller --output wide --watch
    NAME                                  TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
    my-ingress-ingress-nginx-controller   LoadBalancer   10.43.187.220   172.17.0.2    80:31520/TCP,443:30916/TCP   7m    app.kubernetes.io/component=controller,app.kubernetes.io/instance=my-ingress,app.kubernetes.io/name=ingress-nginx

Używaj klasy nginx w swoich Ingressach (jak w przykładowym manifeście z komunikatu):
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example
  namespace: foo
spec:
  ingressClassName: nginx
  rules:
    - host: www.example.com
      http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: exampleService
                port:
                  number: 80
```

```Po wykonaniu tych komend, zobaczysz, że `kubectl get pods -n ingress-nginx` pokaże te same pody, 
      które zobaczysz w roli: deploy_app_using_helm_chart, ale tym razem zainstalowane i zarządzane przez Helma

# kubectl get pods -n ingress-nginx
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6766768fbc-xb4z4   1/1     Running   0          8m49s


   to jest outpuz z roli: deploy_app_using_helm_chart
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6766768fbc-l2nf2   1/1     Running   0          103s


Krótko:
nie uruchamiasz Nginx „lokalnie” jako zwykły serwer HTTP, tylko wystawiasz Ingress Nginx w klastrze K3s,
a http://localhost:8081 to tylko sposób przekierowania ruchu z Twojej maszyny do klastra.

Żeby ten finał zadziałał, muszą być spełnione wszystkie kroki „infrastrukturalne”,
które wcześniej robiłeś ręcznie:
1. Klaster K3s musi działać (w kontenerze / VM, tak jak w Twoim projekcie).
2. W tym klastrze musi być zainstalowany Ingress Nginx:
   kiedyś robiłeś to ręcznie komendą helm install ...,

teraz robi to rola installing_charts_using_helm.

3. Musi być uruchomione forwardowanie portu z Twojego hosta na Service w klastrze, np.:
# kubectl --kubeconfig=k3s-kubeconfig port-forward -n ingress-nginx svc/my-ingress-ingress-nginx-controller 8081:80

4. Dopiero wtedy wejście na http://localhost:8081 pokaże stronę Welcome to nginx!.

Rola installing_charts_using_helm (tak jak późniejsza rola: deploy_app_using_helm_chart) odpowiada tylko za krok 2 – czyli za to,
żeby w klastrze był zainstalowany release Helma z Ingress Nginx.
Samo „odpalenie Nginx lokalnie” i dostęp przez localhost:8081 wymaga jeszcze osobnego kroku z kubectl
port-forward (albo NodePort / LoadBalancer), którego teraz rola nie robi.


teraz dziala:
Finał: Otwórz przeglądarkę i wejdź na http://localhost:8081
Powinieneś zobaczyć domyślną stronę powitalną ingress-nginx:
Welcome to nginx!