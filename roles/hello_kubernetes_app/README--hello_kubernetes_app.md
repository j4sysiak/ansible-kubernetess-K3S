Wykorzystamy całą infrastrukturę, którą zbudowaliśmy (k3s + ingress-nginx), aby wdrożyć i publicznie udostępnić 
prostą aplikację.

Nasz Plan: Wdrożenie i Udostępnienie Aplikacji "Hello Kubernetes" 
       - to jest taka stronka, ktora bedzie dostepna pod urlem: http://localhost:8081

Zrobimy to w dwóch etapach, używając Ansible do zarządzania wszystkim:

# Etap 1: Wdrożenie Aplikacji w Klastrze
Utworzenie roli: hello_kubernetes_app
Celem tej roli będzie wdrożenie aplikacji "Hello Kubernetes" i udostępnienie jej za pomocą zasobu Ingress 
                               (Udostępnienie Aplikacji na Zewnątrz).
 
# Etap 2: Udostępnienie Aplikacji na Zewnątrz
Przygotuj Manifesty Aplikacji
Utworzymy proste plik manifestu YAML dla aplikacji "Hello Kubernetes".
Wszystkie pliki konfiguracyjne naszej aplikacji umieścimy wewnątrz nowej roli.
 - roles/hello_kubernetes_app/files/deployment.yaml   (plik manifestu, dla zasobów: Service + Deployment)
 - roles/hello_kubernetes_app/files/ingress.yaml      (plik manifestu, tym razem dla zasobu: Ingress)


# Etap 3: Implementacja Zadań w tasks/main.yml
Zadania w nowej roli będą bardzo proste: zastosuj oba pliki manifestu.
 - roles/hello_kubernetes_app/tasks/main.yml 
 

# Etap 4: Stwórz Playbook do Wdrożenia Aplikacji
Upewnij się, że Twój klaster K3s i ingress-nginx działają.
Uruchamiamy playbooka, który wywoła naszą nową rolę:
# ansible-playbook -i inventory/hosts.ini destroy_hello_kubernetes_app.yml
# ansible-playbook -i inventory/hosts.ini hello_kubernetes_app.yml

# Etap 5: Weryfikacja:
Sprawdź istniejące namespace'y i zasoby

pokaż namespace'y
# kubectl --kubeconfig=./k3s-kubeconfig get namespaces
    NAME              STATUS   AGE
    default           Active   131m
    hello-namespace   Active   90s
    hello-world       Active   29m
    ingress-nginx     Active   131m
    kube-node-lease   Active   131m
    kube-public       Active   131m
    kube-system       Active   131m

# kubectl --kubeconfig=./k3s-kubeconfig get pods --all-namespaces
    NAMESPACE         NAME                                       READY   STATUS    RESTARTS   AGE
    hello-namespace   hello-kubernetes-bd87d88d7-6wh9l           1/1     Running   0          2m13s
    hello-namespace   hello-kubernetes-bd87d88d7-vzvhp           1/1     Running   0          2m13s
    hello-namespace   hello-kubernetes-bd87d88d7-zmnzd           1/1     Running   0          2m13s
    hello-world       hello-world-7f86d974d5-wxc6f               1/1     Running   0          30m
    ingress-nginx     ingress-nginx-controller-565c7596d-ccm8b   1/1     Running   0          131m
    kube-system       coredns-7896679cc-lsvwt                    1/1     Running   0          131m
    kube-system       local-path-provisioner-578895bd58-csnjt    1/1     Running   0          131m
    kube-system       metrics-server-7b9c9c4b9c-2bjxw            1/1     Running   0          131m

pokaż wszystkie pody we wszystkich namespace'ach
# kubectl --kubeconfig=./k3s-kubeconfig get deployments --all-namespaces
    NAMESPACE         NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
    hello-namespace   hello-kubernetes           3/3     3            3           2m54s
    hello-world       hello-world                1/1     1            1           30m
    ingress-nginx     ingress-nginx-controller   1/1     1            1           132m
    kube-system       coredns                    1/1     1            1           132m
    kube-system       local-path-provisioner     1/1     1            1           132m
    kube-system       metrics-server             1/1     1            1           132m

# kubectl --kubeconfig=./k3s-kubeconfig get ingress --all-namespaces
    NAMESPACE         NAME                       CLASS   HOSTS       ADDRESS      PORTS   AGE
    hello-namespace   hello-kubernetes-ingress   nginx   localhost   172.17.0.2   80      3m33s

Jeśli brakuje namespace'u, utwórz go (jeśli masz plik)
# kubectl --kubeconfig=./k3s-kubeconfig apply -f roles/hello_kubernetes_app/files/namespace.yaml

Albo utwórz namespace ręcznie
# kubectl --kubeconfig=./k3s-kubeconfig create namespace hello-namespace

Zastosuj manifesty aplikacji w właściwym namespace
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-namespace apply -f roles/hello_kubernetes_app/files/deployment.yaml
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-namespace apply -f roles/hello_kubernetes_app/files/ingress.yaml

 
pokaż pody w konkretnym namespace
# kubectl --kubeconfig=./k3s-kubeconfig get pods -n hello-namespace
    NAME                               READY   STATUS    RESTARTS   AGE
    hello-kubernetes-bd87d88d7-6wh9l   1/1     Running   0          4m46s
    hello-kubernetes-bd87d88d7-vzvhp   1/1     Running   0          4m46s
    hello-kubernetes-bd87d88d7-zmnzd   1/1     Running   0          4m46s

 


Sprawdź, czy pody działają:
# kubectl --kubeconfig=./k3s-kubeconfig get pods
    No resources found in default namespace.
Ponieważ domyślny namespace to default, a twoje pody są w hello-namespace. 
Dlatego kubectl --kubeconfig=./k3s-kubeconfig get pods zwraca „No resources found in default namespace”. 
Użyj jednej z poniższych komend.

ustaw domyślny namespace dla bieżącego kontekstu (opcjonalnie)
# kubectl --kubeconfig=./k3s-kubeconfig config set-context --current --namespace=hello-namespace

sprawdź po ustawieniu domyślnego namespace
# kubectl --kubeconfig=./k3s-kubeconfig get pods


Sprawdź, czy zasób Ingress został stworzony:
# kubectl --kubeconfig=k3s-kubeconfig get ingress
    NAME                       CLASS    HOSTS   ADDRESS   PORTS   AGE
    hello-kubernetes-ingress   <none>   *                 80      33s

Finał: Otwórz przeglądarkę i wejdź na adres http://localhost:8081
        Ta strona nie działa / Ta witryna jest nieosiągalna

Problem: Ingress jest wdrożony w klastrze, ale nie jest automatycznie dostępny na localhost:8081. 
Trzeba albo zrobić port-forward, albo udostępnić usługę ingress-nginx jako NodePort / użyć hostNetwork. 
Poniżej krótkie kroki diagnostyczne i szybkie rozwiązanie.

1. Sprawdź szczegóły Ingress (hosty, adresy)
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-namespace get ingress hello-kubernetes-ingress -o wide
    NAME                       CLASS   HOSTS       ADDRESS      PORTS   AGE
    hello-kubernetes-ingress   nginx   localhost   172.17.0.2   80      16m

2. Sprawdź usługę kontrolera ingress (czy jest svc/ingress-nginx-controller)
# kubectl --kubeconfig=./k3s-kubeconfig -n ingress-nginx get svc
    NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller             NodePort    10.43.161.247   <none>        80:30960/TCP,443:32160/TCP   146m
    ingress-nginx-controller-admission   ClusterIP   10.43.17.53     <none>        443/TCP                      146m


3) Szybkie tymczasowe udostępnienie na localhost:8081 (uruchom w osobnym terminalu)
Utwórz tunel portów z localhost:8081 do usługi ingress-nginx
# kubectl --kubeconfig=./k3s-kubeconfig -n ingress-nginx port-forward svc/ingress-nginx-controller 8081:80
    ntroller 8081:80
    Forwarding from 127.0.0.1:8081 -> 80
    Forwarding from [::1]:8081 -> 80
    Handling connection for 8081
    Handling connection for 8081

     (UWAGA: to polecenie będzie działać w tym terminalu do momentu jego przerwania - Ctrl+C)


!!! Teraz dziala w przeglądarce i curl !!!

w nowym terminalu uruchom:
# curl -v http://localhost:8081/
* Host localhost:8081 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8081...
* Connected to localhost (::1) port 8081
> GET / HTTP/1.1
> Host: localhost:8081
> User-Agent: curl/8.5.0
> Accept: */*
>
< HTTP/1.1 200 OK


-------------------------  web browser: http://localhost:8081 ----------
                        
Hello world!
namespace:	-
pod:	hello-kubernetes-bd87d88d7-6wh9l
node:	- (Linux 6.6.87.2-microsoft-standard-WSL2)
------------------------------------------------------------------------


 

# 5) Jeżeli port-forward nie działa — sprawdź logi kontrolera
kubectl --kubeconfig=./k3s-kubeconfig -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200

# 6) Opcjonalnie: wystaw svc jako NodePort (trwała zmiana)
kubectl --kubeconfig=./k3s-kubeconfig -n ingress-nginx patch svc ingress-nginx-controller -p '{"spec":{"type":"NodePort"}}'
kubectl --kubeconfig=./k3s-kubeconfig -n ingress-nginx get svc ingress-nginx-controller -o wide








