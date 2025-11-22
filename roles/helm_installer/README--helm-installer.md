ingress-nginx is an Ingress controller for Kubernetes using NGINX as a reverse proxy and load balancer.

Helm nie jest częścią ingress-nginx.
Helm to niezależne narzędzie (package manager dla Kubernetesa). ingress-nginx to kontroler Ingress (zestaw manifestów/zasobów), który możesz zainstalować
np. przy pomocy Helma (chart ingress-nginx) lub bezpośrednio przez manifesty.

Przykład instalacji przez Helm (bash):

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig

Sprawdź wersję helma: (na lokalnym hoscie, nie w kontenerze):
$ helm version
version.BuildInfo{Version:"v3.19.2", GitCommit:"8766e718a0119851f10ddbe4577593a45fadf544", GitTreeState:"clean", GoVersion:"go1.24.9"}

 
---------------------------------------------------------------
# ansible-playbook -i inventory/hosts.ini destroy_helm_installer.yml --ask-become-pass    (jacek)
# ansible-playbook -i inventory/hosts.ini deploy_helm_installer.yml --ask-become-pass    (jacek)

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
# ansible-playbook -i inventory/hosts.ini destroy_helm_installer.yml
# ansible-playbook -i inventory/hosts.ini deploy_helm_installer.yml

**********************************************************************

Dodaj bramkarza (Ingress Nginx) z repozytorium GitHuba/ingress-nginx
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

Zaktualizuj listę dostępnych chartów
# helm repo update

```"ingress-nginx" already exists with the same configuration, skipping
(ansible-venv) jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Unable to get an update from the "prometheus-community" chart repository (https://prometheus-community.github.io/helm-charts):
        Get "https://prometheus-community.github.io/helm-charts/index.yaml": read tcp 172.22.156.245:36392->185.199.110.153:443: read: connection reset by peer
...Unable to get an update from the "ingress-nginx" chart repository (https://kubernetes.github.io/ingress-nginx):
        Get "https://kubernetes.github.io/ingress-nginx/index.yaml": read tcp 172.22.156.245:56918->185.199.109.153:443: read: connection reset by peer
...Unable to get an update from the "grafana" chart repository (https://grafana.github.io/helm-charts):
        Get "https://grafana.github.io/helm-charts/index.yaml": read tcp 172.22.156.245:36386->185.199.110.153:443: read: connection reset by peer
Update Complete. ⎈Happy Helming!⎈
```
-----------------------   diagnostyka błędu:

Wymuszenie IPv4 i sprawdzenie odpowiedzi
# curl -v -4 https://kubernetes.github.io/ingress-nginx/index.yaml

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




 

Zainstaluj bramkarza (Ingress Nginx) w swoim klastrze (pamiętaj o kubeconfig)
# helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig

```Po wykonaniu tych komend, zobaczysz, że `kubectl get pods -n ingress-nginx` pokaże te same pody, 
      które widziałeś wcześniej, ale tym razem zainstalowane i zarządzane przez Helma

# kubectl get pods -n ingress-nginx
    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6b974db7d5-gblnf   1/1     Running   0          29m