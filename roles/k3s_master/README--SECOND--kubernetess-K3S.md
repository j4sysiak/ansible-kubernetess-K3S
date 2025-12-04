
Musimy zainstalować w Dockerze serwer SSH, aby Ansible mógł się połączyć.


1. **Wejdź do kontenera i zainstaluj SSH:**

# docker exec -it k3s-master bash

# Wewnątrz kontenera wykonaj:
   
    root@k3s-master:/# apt-get update && apt-get install -y openssh-server sudo
    root@k3s-master:/# sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    root@k3s-master:/# service ssh start
    root@k3s-master:/# service ssh status
    
    ustaw haslo na roota:
    root@k3s-master:/# passwd root    (ustaw haslo na "test")
    root@k3s-master:/# exit
 
3.  **Zaktualizuj `inventory/hosts.ini`**, aby używał SSH (tak jak robiliśmy to z Icinga):
    ```ini
    [k3s_master]
    k3s-container ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root ansible_ssh_pass=test ansible_become=false
    ```
wykonaj na lokal hoście:
# ssh-keygen -f ~/.ssh/known_hosts -R '[127.0.0.1]:2222'
# ssh root@127.0.0.1 -p 2222             (wpisz hasło: test)
    wyjdź z kontenera
    root@k3s-master:/# exit


zatrzymaj kontener:
# docker stop k3s-master     (lub   docker restart k3s-master)

uruchom ponownie kontener i sprawdź status SSH:
# docker start k3s-master   

start usługi ssh i sprawdź jej status:
***** UWAGA: Za każdym razem, gdy restartujesz Dockera, musisz ręcznie uruchomić usługę SSH w tym kontenerze!
# docker exec -it k3s-master bash

    root@k3s-master:/# service ssh status
    * sshd is running
    root@k3s-master:/# service ssh restart
    * Restarting OpenBSD Secure Shell server sshd                                                                                                       [ OK ]
    root@k3s-master:/# service ssh status
    * sshd is running

-i inventory.ini
# ************************** only once ********************************************************************
# cd /home/jacek/dev/ansible-kubernetess-K3S 
# ansible-playbook -i inventory/hosts.ini bootstrap_k3s.yml         // Bootstrap K3s container with Python
# *********************************************************************************************************
   
Natychmiast po tym, uruchom ponownie główny playbook (nie bootstrap, tylko ten główny):
# ansible-playbook -i inventory/hosts.ini k3s_master_destroy.yml
# ansible-playbook -i inventory/hosts.ini deploy_k3s_master.yml     //Deploy K3s Master Server to Docker

Sprawdź status SSH w kontenerze
# docker exec -it k3s-master bash -c 'service ssh status'
    sshd is running

# Jeśli SSH nie działa - uruchom
docker exec -it k3s-master bash -c 'service ssh start && service ssh status'

Sprawdź Python3
# docker exec -it k3s-master bash -c 'which python3 && python3 --version'
    /usr/bin/python3
    Python 3.10.12

Tym razem Ansible powinien pomyślnie połączyć się z serwerem SSH, który właśnie ręcznie uruchomiłeś.
Na przyszłość: 
Za każdym razem, gdy restartujesz Dockera, będziesz musiał ręcznie uruchamiać usługę SSH w tym kontenerze, 
zanim zaczniesz pracę z Ansible. 
To jest kompromis, na który poszliśmy, wybierając tę niezawodną metodę utrzymywania kontenera przy życiu.


*****************************************************************************
***********************  wykorzystanie  *************************************
*****************************************************************************

Krótko i na temat:
Co robimy tutaj (1) Uruchamiasz lekki klaster Kubernetes (k3s) lokalnie.

(2) Instalujesz kontroler Ingress (ingress-nginx) — to komponent, 
        który przyjmuje ruch HTTP/HTTPS z zewnątrz i przekierowuje go do odpowiednich usług w klastrze 
                na podstawie nagłówka Host i ścieżki.

(3) Używasz kubeconfig (k3s\-kubeconfig) żeby narzędzia (kubectl, helm) łączyły się z właściwym klastrem.

Rola Ingress i kontrolera (1) Ingress = reguły L7: mapowanie host/ścieżka -> Service (port wewnątrz klastra).

(2) Kontroler (ingress-nginx) = implementacja tych reguł; potrzebuje serwisu (zwykle LoadBalancer lub NodePort) 
                           żeby udostępnić punkt wejścia.

(3) TLS: certyfikat wrzucasz do Secret typu kubernetes.io/tls, a Ingress odwołuje się do niego w sekcji tls.

Co widzisz w swoim środowisku i konsekwencje (1) Serwis kontrolera ma EXTERNAL\-IP = 172.17.0.2 — to adres mostka Dockera, 
                 czyli kontroler jest dostępny tylko z hosta (albo innych kontenerów).

(2) Na bare-metal potrzebny MetalLB, żeby otrzymać realny publiczny adres LoadBalancer. 
Bez tego używasz: wpisu w \/etc/hosts`, port-forward albo NodePort. (3) Helm/kubectl muszą używać--kubeconfig=k3s-kubeconfig albo zmiennej środowiskowej KUBECONFIG`, 
         jeśli polecenia mają działać przeciwko twojemu k3s.


//////////////////////////   lepsze wyjaśnienie  //////////////////////////////////

1. Uruchomienie klastra k3s lokalnie
   Stworzyłeś kontener Docker (k3s-master) z k3s — lekką dystrybucją Kubernetes.
   k3s działa w izolowanym środowisku, ale jest dostępny przez SSH (port 2222) i API Kubernetes.
   Otrzymałeś plik konfiguracyjny k3s-kubeconfig, który pozwala narzędziom (kubectl, helm) łączyć się z klastrem.
   Czemu to ważne? Masz teraz działający klaster Kubernetes bez potrzeby instalowania go bezpośrednio na hoście.
 

2. Instalacja kontrolera Ingress (ingress-nginx)
   Zainstalowałeś kontroler Ingress (ingress-nginx) za pomocą Helm.
   Kontroler Ingress to komponent, który zarządza ruchem HTTP/HTTPS przychodzącym do klastra.
   Umożliwia on definiowanie reguł (Ingress resources), które kierują ruch do odpowiednich usług w klastrze na podstawie nagłówków Host i ścieżek URL.
   Przykład: Ruch na http://example.com/app trafi do Service app-service na porcie 80.
   Czemu to ważne? Pozwala to na łatwe zarządzanie dostępem do aplikacji działających w klastrze Kubernetes.
 
   
3. Konfiguracja kubeconfig
   Plik k3s-kubeconfig zawiera dane uwierzytelniające do API klastra.
   Polecenia kubectl i helm muszą używać tego pliku:
   # kubectl --kubeconfig=k3s-kubeconfig get pods
   albo
   # export KUBECONFIG=$PWD/k3s-kubeconfig
   # kubectl get pods -A

   Czemu to ważne? Bez tego kubectl łączy się z innym klastrem (np. domyślnym) albo wyświetla błąd.

4. Rola Ingress i Kontrolera

      a)
      Ingress to zasób Kubernetes, który definiuje reguły routingu ruchu HTTP/HTTPS.
      To reguły warstwy 7 (L7 — HTTP/HTTPS).
      Przykład: Host: example.com + ścieżka /api → Service backend port 8080.

      b)
      Kontroler Ingress (ingress-nginx) implementuje te reguły i wymaga serwisu (LoadBalancer lub NodePort) do udostępnienia punktu wejścia
                   , żeby ruch z zewnątrz dotarł do klastra.
      Działa jako reverse proxy (NGINX).
      Dla TLS, certyfikat jest przechowywany w Secret typu kubernetes.io/tls, a Ingress odwołuje się do niego w sekcji tls.
      Czemu to ważne? Umożliwia to bezpieczne i elastyczne zarządzanie ruchem do aplikacji w klastrze.

      c) 
      TLS (certyfikaty SSL)
      Certyfikat (plik .crt + .key) wrzucasz do Secret typu kubernetes.io/tls, a Ingress odwołuje się do niego w sekcji tls.
      Kontroler automatycznie obsługuje HTTPS.
 

5.  Co działa:
    Kontroler Ingress ma adres EXTERNAL-IP = 172.17.0.2 — to adres mostka Docker (docker0).
    Możesz testować z hosta WSL:


6. Podsumowanie kroków, które wykonaliśmy
 
   1
   Zbudowaliśmy obraz Docker + uruchomiliśmy kontener z k3s
   Mamy działający klaster Kubernetes
   
   2
   Zainstalowaliśmy SSH w kontenerze
   Ansible może się połączyć i zarządzać konfiguracją
   
   3
   Wgraliśmy klucz SSH (bezhasłowe logowanie)
   Bezpieczniejsze + wygodniejsze niż hasło
   
   4
   Zainstalowaliśmy Python3 w kontenerze
   Ansible wymaga Pythona na zdalnym hoście
   
   5
   Uruchomiliśmy playbook bootstrap_k3s.yml
   Przygotowanie środowiska (pakiety, narzędzia)
   
   6
   Uruchomiliśmy deploy_k3s_master.yml
   Instalacja i konfiguracja k3s + ingress-nginx
   
   7
   Pobraliśmy k3s-kubeconfig
   kubectl/helm mogą łączyć się z klastrem
   
   8
   Sprawdziliśmy status kontrolera Ingress
   Upewniliśmy się, że NGINX działa i ma IP
 