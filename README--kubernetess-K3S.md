docker run \
-d \
--name k3s-master \
--hostname k3s-master \
--privileged  -v /dev:/dev \
--cgroupns=host \
-p 6443:6443 \
-p 8081:80 \
-p 2222:22 \
ubuntu:22.04 \
sleep infinity

 


# docker ps
# docker inspect k3s-master

Musimy zainstalować w nim serwer SSH, aby Ansible mógł się połączyć.


1. **Wejdź do kontenera i zainstaluj SSH:**
    ```bash
    docker exec -it k3s-master bash
    # Wewnątrz kontenera:
    apt-get update && apt-get install -y openssh-server sudo
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    service ssh start
    exit
    ```


ustaw haslo na roota:
# docker exec -it k3s-master bash
# passwd root
      ustaw haslo na "test"
 

3.  **Zaktualizuj `inventory/hosts.ini`**, aby używał SSH (tak jak robiliśmy to z Icinga):
    ```ini
    [k3s_master]
    k3s-container ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root ansible_ssh_pass=test ansible_become=false
    ```
wykonaj na lokal hoście:
# ssh-keygen -f ~/.ssh/known_hosts -R '[127.0.0.1]:2222'
# ssh root@127.0.0.1 -p 2222
# wyjdź z kontenera
# exit


zatrzymaj kontener:
# docker stop k3s-master

uruchom ponownie kontener i sprawdź status SSH:
# docker start k3s-master

start usługi ssh i sprawdź jej status:
***** UWAGA: Za każdym razem, gdy restartujesz Dockera, musisz ręcznie uruchomić usługę SSH w tym kontenerze!
# docker exec -it k3s-master bash
# service ssh start
# service ssh status

# ************************** only once *****************************************
# ansible-playbook  bootstrap_k3s.yml
# ******************************************************************************
   
Wykonaj powyższe kroki, aby wejść do kontenera i uruchomić usługę SSH.
Natychmiast po tym, uruchom ponownie główny playbook (nie bootstrap, tylko ten główny):

# ansible-playbook k3s_master_destroy.yml
# ansible-playbook deploy_k3s_master.yml

Tym razem Ansible powinien pomyślnie połączyć się z serwerem SSH, który właśnie ręcznie uruchomiłeś.
Na przyszłość: Za każdym razem, gdy restartujesz Dockera, będziesz musiał ręcznie uruchamiać usługę SSH w tym kontenerze, 
zanim zaczniesz pracę z Ansible. To jest kompromis, na który poszliśmy, 
wybierając tę niezawodną metodę utrzymywania kontenera przy życiu.



