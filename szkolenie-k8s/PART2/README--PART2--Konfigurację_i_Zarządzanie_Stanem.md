W pracy rzadko wdraża się "czyste" obrazy (jak nasz Nginx w PART1--Networking-Services). 
Zazwyczaj aplikacja potrzebuje:
Plików konfiguracyjnych (np. własny index.html lub nginx.conf).
Haseł i kluczy (których nie wolno trzymać w kodzie).
Samoleczenia (K8s musi wiedzieć, kiedy aplikacja się zawiesiła).

1. Lab 5: ConfigMaps (Wstrzykiwanie Konfiguracji)
   Scenariusz: Twój szef mówi: "Ten Nginx wyświetla domyślną stronę. 
   Chcę, żeby wyświetlał naszą firmową stronę powitalną, ale NIE chcę budować nowego obrazu Dockera."
   
   Rozwiązanie: Użyjemy ConfigMap. 
   To obiekt K8s, który przechowuje dane (pliki, zmienne) i pozwala "wstrzyknąć" je do kontenera.

   
 - Stwórz plik custom-website.yaml
 - Zmodyfikuj plik Deploymentu, aby używał tej mapy: nginx-deployment-custom.yaml

2. Zadanie dla Ciebie:

Odpal ConfigMap z własną stroną:
# kubectl apply -f custom-website.yaml
    configmap/my-website-config created

Odpal deployment z konfiguracja ConfigMap:
# kubectl apply -f nginx-deployment-custom.yaml
    deployment.apps/my-webapp-custom created

Sprawdź Deployment (czy wszystko OK):
# kubectl get deployment my-webapp-custom
    NAME               READY   UP-TO-DATE   AVAILABLE   AGE
    my-webapp-custom   1/1     1            1           53s

Sprawdź Pody (czy Deployment działa):
# kubectl get pods -o wide
    NAME                               READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0          3h32m   10.42.0.23   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0          3h32m   10.42.0.24   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0          3h32m   10.42.0.25   k3s-master   <none>           <none>
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0          80s     10.42.0.28   k3s-master   <none>           <none>


   Wystaw to na zewnątrz (używając kubectl port-forward lub tworząc Serwis LoadBalancer dla app: custom-app).
   Wejdź na stronę. Powinieneś zobaczyć "Witaj Szefie!" zamiast "Welcome to nginx!".

Wystaw to na zewnątrz (używając kubectl port-forward lub tworząc Serwis LoadBalancer dla app: custom-app).

3. Utworzenie servisu ClusterIP dla aplikacji custom-app (opcjonalne):
   Stwórz plik: service-clusterip-custom-app.yaml

# kubectl apply -f service-clusterip-custom-app.yaml
    service/my-internal-service-custom created

Sprawdź, czy powstał servis typu ClusterIP:
# kubectl get svc
        NAME                         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
        kubernetes                   ClusterIP      10.43.0.1      <none>        443/TCP        20h
        my-internal-service          ClusterIP      10.43.3.73     <none>        80/TCP         3h35m
    --> my-internal-service-custom   ClusterIP      10.43.117.2    <none>        80/TCP         17s
        my-lb-service                LoadBalancer   10.43.143.7    172.17.0.2    80:30940/TCP   3h5m
        my-nodeport-service          NodePort       10.43.165.45   <none>        80:30007/TCP   3h25m

Ponieważ jest to serwis wewnętrzny, nie wejdziesz na niego z przeglądarki ani z WSL.
Musimy wejść "do środka" klastra, żeby go sprawdzić.

Uruchom ten jednorazowy "pod testowy", który da Ci terminal w środku klastra:
# kubectl run curl-test --image=curlimages/curl -i --tty --rm -- sh
    $ curl http://my-internal-service-custom
        <html>
        <head><title>Strona Firmowa</title></head>
            <body>
                <h1>Witaj Szefie!</h1>
                <p>To jest strona wstrzyknieta przez ConfigMap.</p>
            </body>
        </html>
        [...]



Co się właśnie stało:
Stworzyłeś ConfigMap z własnym plikiem index.html.
Zmodyfikowałeś Deployment, aby zamontować ten plik do kontenera Nginx, nadpisując domyślny plik.
Uruchomiłeś nowy Pod z tą konfiguracją.
Wejście na stronę pokazuje teraz Twoją własną stronę powitalną.
Gratulacje! Właśnie nauczyłeś się, jak zarządzać konfiguracją aplikacji w Kubernetes za pomocą ConfigMaps.




4. Utworzenie servisu NodePort dla aplikacji custom-app (opcjonalne):
   Stwórz plik: service-nodeport-custom-app.yaml
   Wdróż serwis:
# kubectl apply -f service-nodeport-custom-app.yaml
    service/my-nodeport-service-custom-app created

Sprawdź status:
# kubectl get svc
    NAME                             TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    kubernetes                       ClusterIP      10.43.0.1      <none>        443/TCP        20h
    my-internal-service              ClusterIP      10.43.3.73     <none>        80/TCP         3h54m
    my-internal-service-custom       ClusterIP      10.43.117.2    <none>        80/TCP         18m
    my-lb-service                    LoadBalancer   10.43.143.7    172.17.0.2    80:30940/TCP   3h24m
    my-nodeport-service              NodePort       10.43.165.45   <none>        80:30007/TCP   3h43m
    my-nodeport-service-custom-app   NodePort       10.43.203.42   <none>        80:30008/TCP   7m14s

_Powinieneś zobaczyć my-nodeport-service typu NodePort, a w portach: 80:30008/TCP._

Testujemy z WSL (Zewnątrz klastra!)
Teraz nie musisz wchodzić do środka klastra.
Jesteś w swoim terminalu WSL.
Użyj adresu IP swojego kontenera (prawdopodobnie 172.17.0.2), który wcześniej naprawiliśmy.
znajdź IP kontenera (użyj tego IP w kubeconfig)
# docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master
    172.17.0.2
Teraz użyj tego IP i portu 30007, żeby wejść na serwis NodePort z WSL:
Wpisz w terminalu WSL:
# curl http://172.17.0.2:30008
    curl: (7) Failed to connect to 172.17.0.2 port 30008 after 3058 ms: Couldn't connect to server

Technika Ratunkowa: kubectl port-forward
 
# kubectl port-forward service/my-nodeport-service-custom-app 8889:80
 
# curl localhost:8889
    <html>
    <head><title>Strona Firmowa</title></head>
        <body>
            <h1>Witaj Szefie!</h1>
            <p>To jest strona wstrzyknieta przez ConfigMap.</p>
        </body>
    </html>
    [...]

5. Lab 4: LoadBalancer (To co w chmurze)

Stwórz plik: service-lb-custom-app.yaml

Usuń stary LB   my-lb-service  (bo zajmuje port 80):
# kubectl delete svc my-lb-service
    service "my-lb-service" deleted from default namespace
 

Wdróż:
# kubectl apply -f service-lb-custom-app.yaml
    service/my-lb-service-custom-app created

Sprawdź status:
# kubectl get svc
        NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
        kubernetes                       ClusterIP      10.43.0.1       <none>        443/TCP        21h
        my-internal-service              ClusterIP      10.43.3.73      <none>        80/TCP         4h13m
        my-internal-service-custom       ClusterIP      10.43.117.2     <none>        80/TCP         37m
    --> my-lb-service-custom-app         LoadBalancer   10.43.136.176   172.17.0.2    80:30603/TCP   15m
        my-nodeport-service              NodePort       10.43.165.45    <none>        80:30007/TCP   4h3m
        my-nodeport-service-custom-app   NodePort       10.43.203.42    <none>        80:30008/TCP   26m

lub krócej:
# kubectl get svc my-lb-service-custom-app
    NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
    my-lb-service-custom-app         LoadBalancer   10.43.136.176   172.17.0.2    80:30603/TCP   15m

Powinieneś zobaczyć w kolumnie EXTERNAL-IP adres Twojego kontenera (np. 172.17.0.2).
K3s jest sprytny i używa IP hosta jako LoadBalancera.
# http://localhost
Działa od razu! Gratulacje!

# curl http://localhost
<html>
<head><title>Strona Firmowa</title></head>
<body>
  <h1>Witaj Szefie!</h1>
  <p>To jest strona wstrzyknieta przez ConfigMap.</p>
</body>
</html>


