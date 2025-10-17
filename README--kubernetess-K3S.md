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


*****************************************************************************
*******************  wykorzystanie  *************************************
*****************************************************************************
Krótko i na temat:
Co robimy tutaj (1) Uruchamiasz lekki klaster Kubernetes (k3s) lokalnie.
(2) Instalujesz kontroler Ingress (ingress-nginx) — to komponent, który przyjmuje ruch HTTP/HTTPS z zewnątrz i przekierowuje go do odpowiednich usług w klastrze na podstawie nagłówka Host i ścieżki.
(3) Używasz kubeconfig (k3s\-kubeconfig) żeby narzędzia (kubectl, helm) łączyły się z właściwym klastrem.
Rola Ingress i kontrolera (1) Ingress = reguły L7: mapowanie host/ścieżka -> Service (port wewnątrz klastra).
(2) Kontroler (ingress-nginx) = implementacja tych reguł; potrzebuje serwisu (zwykle LoadBalancer lub NodePort) żeby udostępnić punkt wejścia.
(3) TLS: certyfikat wrzucasz do Secret typu kubernetes.io/tls, a Ingress odwołuje się do niego w sekcji tls.
Co widzisz w swoim środowisku i konsekwencje (1) Serwis kontrolera ma EXTERNAL\-IP = 172.17.0.2 — to adres mostka Dockera, czyli kontroler jest dostępny tylko z hosta (albo innych kontenerów).
(2) Na bare-metal potrzebny MetalLB, żeby otrzymać realny publiczny adres LoadBalancer. Bez tego używasz: wpisu w \/etc/hosts`, port-forwardalboNodePort. (3) Helm/kubectlmuszą używać--kubeconfig=k3s-kubeconfigalbo zmiennej środowiskowejKUBECONFIG`, jeśli polecenia mają działać przeciwko twojemu k3s.
Szybkie praktyczne testy (wykonaj z hosta)

# zainstaluj (przykład)
helm --kubeconfig=k3s-kubeconfig install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

# sprawdź serwis i pod
kubectl --kubeconfig=k3s-kubeconfig get svc -n ingress-nginx my-ingress-ingress-nginx-controller -o wide
kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx

# przetestuj Ingress bez zmiany DNS (port-forward)
kubectl --kubeconfig=k3s-kubeconfig -n ingress-nginx port-forward svc/my-ingress-ingress-nginx-controller 8080:80
curl -v -H "Host: www.example.com" http://127.0.0.1:8080

# albo tymczasowo dopisz host do /etc/hosts
echo "172.17.0.2 www.example.com" | sudo tee -a /etc/hosts
curl -v -H "Host: www.example.com" http://172.17.0.2

Najważniejsza idea do zapamiętania Ingress to warstwa HTTP, 
która pozwala wystawiać wiele usług pod jednym IP/portem używając reguł host/ścieżka i opcjonalnie TLS. 
Kontroler Ingress realizuje te reguły i musi mieć sposób na przyjmowanie ruchu 
z zewnątrz (LoadBalancer/NodePort/port-forward/MetalLB).


Poniżej kilka przydatnych poleceń:
# Sprawdź wszystkie pody
kubectl --kubeconfig=k3s-kubeconfig get pods -A
# Opisz pody, które mają problemy (przykład)
kubectl --kubeconfig=k3s-kubeconfig describe pod <POD_NAME> -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig logs <POD_NAME> -n <NAMESPACE> --all-containers
# Sprawdź serwisy
kubectl --kubeconfig=k3s-kubeconfig get svc -A
# Sprawdź Ingressy
kubectl --kubeconfig=k3s-kubeconfig get ingress -A
# Sprawdź węzły
kubectl --kubeconfig=k3s-kubeconfig get nodes -o wide
# Sprawdź zasoby klastra
kubectl --kubeconfig=k3s-kubeconfig top nodes
kubectl --kubeconfig=k3s-kubeconfig top pods -A
# Sprawdź zasoby namespace
kubectl --kubeconfig=k3s-kubeconfig get all -n <NAMESPACE>
# Sprawdź zdarzenia klastra
kubectl --kubeconfig=k3s-kubeconfig get events -A --sort-by='.metadata.creationTimestamp'
# Sprawdź zasoby w formacie YAML/JSON
kubectl --kubeconfig=k3s-kubeconfig get <RESOURCE_TYPE> <RESOURCE_NAME> -n <NAMESPACE> -o yaml
kubectl --kubeconfig=k3s-kubeconfig get <RESOURCE_TYPE> <RESOURCE_NAME> -n <NAMESPACE> -o json
# Użyj port-forward do testowania usług lokalnie
kubectl --kubeconfig=k3s-kubeconfig -n <NAMESPACE> port-forward svc/<SERVICE_NAME> <LOCAL_PORT>:<SERVICE_PORT>
# Sprawdź konfigurację kubeconfig
kubectl --kubeconfig=k3s-kubeconfig config view     
# Ustaw kontekst kubeconfig
kubectl --kubeconfig=k3s-kubeconfig config use-context <CONTEXT_NAME>
# Sprawdź zasoby Helm
helm --kubeconfig=k3s-kubeconfig list -A
helm --kubeconfig=k3s-kubeconfig status <RELEASE_NAME> -n <NAMESPACE>
# Zainstaluj/aktualizuj wykres Helm
helm --kubeconfig=k3s-kubeconfig install <RELEASE_NAME> <CHART> -n <NAMESPACE> --create-namespace
helm --kubeconfig=k3s-kubeconfig upgrade <RELEASE_NAME> <CHART> -n <NAMESPACE>  
# Usuń wykres Helm
helm --kubeconfig=k3s-kubeconfig uninstall <RELEASE_NAME> -n <NAMESPACE>
# Sprawdź zasoby StorageClass
kubectl --kubeconfig=k3s-kubeconfig get storageclass
# Sprawdź zasoby PersistentVolume i PersistentVolumeClaim
kubectl --kubeconfig=k3s-kubeconfig get pv
kubectl --kubeconfig=k3s-kubeconfig get pvc -A
# Sprawdź zasoby Namespace
kubectl --kubeconfig=k3s-kubeconfig get namespaces
# Sprawdź zasoby ConfigMap i Secret
kubectl --kubeconfig=k3s-kubeconfig get configmap -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get secret -n <NAMESPACE>
# Sprawdź zasoby DaemonSet, Deployment, StatefulSet
kubectl --kubeconfig=k3s-kubeconfig get daemonset -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get deployment -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get statefulset -n <NAMESPACE>
# Sprawdź zasoby ServiceAccount, Role, RoleBinding, ClusterRole
kubectl --kubeconfig=k3s-kubeconfig get serviceaccount -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get role -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get rolebinding -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get clusterrole
kubectl --kubeconfig=k3s-kubeconfig get clusterrolebinding  
# Sprawdź zasoby PodDisruptionBudget
kubectl --kubeconfig=k3s-kubeconfig get poddisruptionbudget -n <NAMESPACE>
# Sprawdź zasoby NetworkPolicy
kubectl --kubeconfig=k3s-kubeconfig get networkpolicy -n <NAMESPACE>
# Sprawdź zasoby IngressClass
kubectl --kubeconfig=k3s-kubeconfig get ingressclass
# Sprawdź zasoby CustomResourceDefinition
kubectl --kubeconfig=k3s-kubeconfig get crd
# Sprawdź zasoby APIService
kubectl --kubeconfig=k3s-kubeconfig get apiservice
# Sprawdź zasoby EndpointSlice
kubectl --kubeconfig=k3s-kubeconfig get endpointslice -n <NAMESPACE>
# Sprawdź zasoby HorizontalPodAutoscaler
kubectl --kubeconfig=k3s-kubeconfig get hpa -n <NAMESPACE>
# Sprawdź zasoby VolumeSnapshot (jeśli używasz snapshotów)
kubectl --kubeconfig=k3s-kubeconfig get volumesnapshot -n <NAMESPACE>
kubectl --kubeconfig=k3s-kubeconfig get volumesnapshotclass
kubectl --kubeconfig=k3s-kubeconfig get volumesnapshotcontent
# Sprawdź zasoby CronJob
kubectl --kubeconfig=k3s-kubeconfig get cronjob -n <NAMESPACE>
# Sprawdź zasoby Job
kubectl --kubeconfig=k3s-kubeconfig get job -n <NAMESPACE>
# Sprawdź zasoby Endpoint
kubectl --kubeconfig=k3s-kubeconfig get endpoints -n <NAMESPACE>
# Sprawdź zasoby ResourceQuota
kubectl --kubeconfig=k3s-kubeconfig get resourcequota -n <NAMESPACE>
# Sprawdź zasoby LimitRange
kubectl --kubeconfig=k3s-kubeconfig get limitrange -n <NAMESPACE>
# Sprawdź zasoby PodSecurityPolicy (jeśli używasz PSP)
kubectl --kubeconfig=k3s-kubeconfig get psp
# Sprawdź zasoby Event
kubectl --kubeconfig=k3s-kubeconfig get events -n <NAMESPACE> --sort-by='.metadata.creationTimestamp'
# Sprawdź zasoby APIGroup
kubectl --kubeconfig=k3s-kubeconfig api-resources
# Sprawdź zasoby APIVersion
kubectl --kubeconfig=k3s-kubeconfig api-versions
# Sprawdź zasoby NodeSelector i Taints na węzłach
kubectl --kubeconfig=k3s-kubeconfig get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{.spec.taints}{"\n"}{.spec.nodeSelector}{"\n\n"}{end}'
# Sprawdź zasoby PodTemplate
kubectl --kubeconfig=k3s-kubeconfig get podtemplate -n <NAMESPACE>
# Sprawdź zasoby EndpointSlices
kubectl --kubeconfig=k3s-kubeconfig get endpointslice -n <NAMESPACE>
# Sprawdź zasoby StorageClass
kubectl --kubeconfig=k3s-kubeconfig get storageclass
# Sprawdź zasoby PersistentVolume
kubectl --kubeconfig=k3s-kubeconfig get pv
# Sprawdź zasoby PersistentVolumeClaim
kubectl --kubeconfig=k3s-kubeconfig get pvc -n <NAMESPACE>
# Sprawdź zasoby VolumeAttachment
kubectl --kubeconfig=k3s-kubeconfig get volumeattachment
# Sprawdź zasoby CSINode
kubectl --kubeconfig=k3s-kubeconfig get csinode
# Sprawdź zasoby CSIDriver
kubectl --kubeconfig=k3s-kubeconfig get csidriver
# Sprawdź zasoby PodSecurityAdmission
kubectl --kubeconfig=k3s-kubeconfig get podsecurityadmission -n <NAMESPACE>
# Sprawdź zasoby RuntimeClass
kubectl --kubeconfig=k3s-kubeconfig get runtimeclass
# Sprawdź zasoby PriorityClass
kubectl --kubeconfig=k3s-kubeconfig get priorityclass
# Sprawdź zasoby FlowSchema (jeśli używasz Kube API Priority and Fairness)
kubectl --kubeconfig=k3s-kubeconfig get flowschema
# Sprawdź zasoby PriorityLevelConfiguration (jeśli używasz Kube API Priority and Fairness)
kubectl --kubeconfig=k3s-kubeconfig get prioritylevelconfiguration  
