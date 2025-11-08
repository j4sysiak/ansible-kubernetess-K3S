
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


# ************************** only once *****************************************
# cd /home/jacek/dev/ansible-kubernetess-K3S 
# ansible-playbook bootstrap_k3s.yml         // Bootstrap K3s container with Python
# ******************************************************************************
   
Natychmiast po tym, uruchom ponownie główny playbook (nie bootstrap, tylko ten główny):
# ansible-playbook k3s_master_destroy.yml
# ansible-playbook deploy_k3s_master.yml     //Deploy K3s Master Server to Docker

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

 