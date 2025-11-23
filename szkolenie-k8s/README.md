# Szkolenie Kubernetes - Podstawy
---------------------------------    

1. Sprawdź nodes  (czy Kubernetes działa):
# kubectl get nodes 
    NAME         STATUS   ROLES           AGE   VERSION
    k3s-master   Ready    control-plane   16h   v1.34.1+k3s1

2. Uruchom Deployment (uzywając pliku nginx-deployment.yaml):
# kubectl apply -f nginx-deployment.yaml

3. Sprawdź Deployment (czy wszystko OK):
# kubectl get deployment my-webapp
    NAME        READY   UP-TO-DATE   AVAILABLE   AGE
    my-webapp   3/3     3            3           11m

4. Sprawdź Pody (czy Deployment działa):
# kubectl get pods -o wide
    NAME                         READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
    my-webapp-5f56d9f4dd-6c8pt   1/1     Running   0          56s   10.42.0.23   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-sf7p7   1/1     Running   0          56s   10.42.0.24   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-vfm6b   1/1     Running   0          56s   10.42.0.25   k3s-master   <none>           <none>

Masz teraz 3 działające aplikacje (Pody), każda z własnym adresem IP (10.42.0.23, .24, .25)

Problem: 
Te adresy IP są tymczasowe. 
Jak skasujemy Poda i powstanie nowy, dostanie nowy adres. 
Nie możemy konfigurować innych aplikacji, podając im te zmienne adresy.
Rozwiązanie: 
Używamy zasobu Kubernetes o nazwie Service, który tworzy stały punkt dostępu (stały adres IP i/lub nazwę DNS) do grupy Podów.




5. Rozwiązaniem jest Lab 2: ClusterIP. Stworzymy jeden, stały punkt wejścia.
   Lab 2: ClusterIP (Wewnętrzny, Stały Adres)
   Stworzymy Serwis, który zepnie te 3 pody w jedną całość.
   Stwórz plik service-clusterip.yaml

# kubectl apply -f service-clusterip.yaml
    service/my-internal-service created

   Sprawdź, czy powstał:
# kubectl get svc
    NAME                  TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes            ClusterIP   10.43.0.1    <none>        443/TCP   16h
    my-internal-service   ClusterIP   10.43.3.73   <none>        80/TCP    50s

Powinieneś zobaczyć my-internal-service z typem ClusterIP i stałym adresem IP (CLUSTER-IP), np. 10.43.x.x.

Testujemy (Ważne!)
Ponieważ jest to serwis wewnętrzny, nie wejdziesz na niego z przeglądarki ani z WSL. 
Musimy wejść "do środka" klastra, żeby go sprawdzić.

  Uruchom ten jednorazowy "pod testowy", który da Ci terminal w środku klastra:
# kubectl run curl-test --image=curlimages/curl -i --tty --rm -- sh
    All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
    If you don't see a command prompt, try pressing enter.
        ~ $ curl http://my-internal-service
        <!DOCTYPE html>
        <html>
            <head>
                <title>Welcome to nginx!</title>
        [...]


Co się właśnie stało:
Byłeś wewnątrz tymczasowego poda (curl-test).
Uderzyłeś w wirtualną nazwę my-internal-service.
Kubernetes DNS zamienił nazwę na wirtualne IP.
Serwis odebrał ruch i przekazał go do jednego z trzech podów my-webapp.
Wniosek: Komunikacja wewnątrz klastra działa idealnie.




6. Teraz przechodzimy do Lab 3: NodePort - (Otwieramy drzwi na zewnątrz).
   Szef mówi: "Dobra robota, ale ja chcę sprawdzić tę stronę z sieci firmowej (czyli z zewnątrz klastra), 
                   a nie wchodzić do jakiegoś poda."
   Ten typ serwisu otwiera "dziurę" (port) bezpośrednio na maszynie (Węźle/Node), na której działa Kubernetes. 
   W naszym przypadku tą "maszyną" jest kontener Dockera k3s-master.

   Wdróż serwis:
# kubectl apply -f service-nodeport.yaml
    service/my-nodeport-service created

   Sprawdź status:
# kubectl get svc
    NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    kubernetes            ClusterIP   10.43.0.1      <none>        443/TCP        17h
    my-internal-service   ClusterIP   10.43.3.73     <none>        80/TCP         11m
    my-nodeport-service   NodePort    10.43.165.45   <none>        80:30007/TCP   55s

_Powinieneś zobaczyć my-nodeport-service typu NodePort, a w portach: 80:30007/TCP._

Testujemy z WSL (Zewnątrz klastra!)
Teraz nie musisz wchodzić do środka klastra. 
Jesteś w swoim terminalu WSL. 
Użyj adresu IP swojego kontenera (prawdopodobnie 172.17.0.2), który wcześniej naprawiliśmy.
znajdź IP kontenera (użyj tego IP w kubeconfig)
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master
    172.17.0.2
Teraz użyj tego IP i portu 30007, żeby wejść na serwis NodePort z WSL:
Wpisz w terminalu WSL:
# curl http://172.17.0.2:30007
    curl: (7) Failed to connect to 172.17.0.2 port 30007 after 2955 ms: Couldn't connect to server

--------- diagnostyka w razie problemów ----------
Sprawdźmy, czy aplikacja jest dostępna wewnątrz samego kontenera k3s-master. 
To wykluczy problemy z firewallem Windowsa.
# docker exec -it k3s-master curl http://localhost:30007
        <!DOCTYPE html>
        <html>
            <head>
                <title>Welcome to nginx!</title>
        [...]

# kubectl get svc my-nodeport-service
    NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    my-nodeport-service   NodePort   10.43.165.45   <none>        80:30007/TCP   6m10s

Sprawdź, czy port jest fizycznie otwarty
Zajrzyjmy głęboko w system sieciowy kontenera.
# docker exec -it k3s-master netstat -tulpn | grep 30007
    nic nie zwrociło - ale to jest OK.

Technika Ratunkowa: kubectl port-forward
Kiedy sieć zawodzi, a Ty musisz dostać się do serwisu "na szybko", używasz port-forward. 
To polecenie tworzy szyfrowany tunel bezpośrednio z Twojego terminala do serwisu w klastrze, ignorując firewalle i routing.

# kubectl port-forward service/my-nodeport-service 8888:80
(To mówi: "Przekieruj mój lokalny port 8888 na port 80 tego serwisu").
Terminal się "zablokuje" i wyświetli: Forwarding from 127.0.0.1:8888 -> 80. Nie zamykaj go!
Otwórz nowe okno terminala WSL (lub kartę) i wpisz:
# curl localhost:8888

```
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

For online documentation and support please refer to nginx.org.
Commercial support is available at nginx.com.

Thank you for using nginx.
```

 Gratulacje! Udało się!


7.  Lab 4: LoadBalancer (To co w chmurze)
    Lab 4, który jest znacznie ciekawszy, bo zadziała "automatycznie" dzięki temu, jak uruchomiliśmy kontener.

Stwórz plik service-lb.yaml

Wdróż:
# kubectl apply -f service-lb.yaml
    service/my-lb-service created

Sprawdź status:
# kubectl get svc my-lb-service
    NAME            TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
    my-lb-service   LoadBalancer   10.43.143.7   172.17.0.2    80:30940/TCP   30s

Powinieneś zobaczyć w kolumnie EXTERNAL-IP adres Twojego kontenera (np. 172.17.0.2). 
K3s jest sprytny i używa IP hosta jako LoadBalancera.

Wielki Test (bez kombinowania)
Skoro serwis nasłuchuje na porcie 80 w kontenerze, a Docker przekierowuje port 80 na 80...  (-p 80:80 \)
Otwórz przeglądarkę w Windowsie i wejdź na:
http://localhost
Działa od razu! Gratulacje!

taka jest moja konfiguracja uruchomienia kontenera k3s-master:
widać, że port 80 kontenera jest przekierowany na port 80 hosta Windowsa
wiec wejście na http://localhost trafi do serwisu LoadBalancer w klastrze K3s
```
docker run -d \
--name k3s-master \
--hostname k3s-master \
--privileged -v /dev:/dev \
--cgroupns=host \
  -p 2222:22 \
  -p 80:80 \
  -p 443:443 \
  -p 6443:6443 \
k3s-master-image
```

mozna zmienic -p 80:80 \ na inny port, np. -p 8080:80 \
wtedy w przeglądarce trzeba wejść na http://localhost:8080  
```
docker run -d \
--name k3s-master \
--hostname k3s-master \
--privileged -v /dev:/dev \
--cgroupns=host \
  -p 2222:22 \
  -p 8080:80 \
  -p 443:443 \
  -p 6443:6443 \
k3s-master-image
```

8. Podsumowanie
   Teraz wiesz, jak działają różne typy serwisów w Kubernetes:
   ClusterIP - wewnętrzny, stały adres IP dla podów
   NodePort - otwiera port na węźle (maszynie) dla dostępu z zewnątrz
   LoadBalancer - integruje się z chmurą, ale w K3s używa IP hosta jako punktu wejścia

   Każdy typ serwisu ma swoje zastosowania i ograniczenia.
   Wybór odpowiedniego typu zależy od potrzeb Twojej aplikacji i środowiska, w którym działa klaster Kubernetes.








