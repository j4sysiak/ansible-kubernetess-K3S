
Zadanie "Bojowe" na koniec (dla Szefa)
Szef prosi o kompletne środowisko. Połącz wiedzę z wszystkich Labów:
Stwórz Deployment Nginx (3 repliki).
Podepnij mu ConfigMap, który zmienia index.html na "To jest produkcja".
Ustaw Limits na 64Mi RAM.
Wystaw to przez Ingress pod ścieżką /produkcja.
Jeśli to zrobisz i otworzysz http://localhost/produkcja widząc swój tekst – jesteś gotowy do pracy z Kubernetesem. Powodzenia!

-----------------------------------


To jest doskonałe zadanie podsumowujące. Sprawdza wiedzę o wolumenach, konfiguracji, zasobach i sieci naraz.
Podejdźmy do tego profesjonalnie. Zamiast tworzyć 4 osobne pliki, stworzymy jeden plik zadanie-bojowe.yaml, który zawiera wszystko ("All-in-One"). W pracy często tak się grupuje powiązane zasoby.
Oto kompletne rozwiązanie krok po kroku.

1. Stwórz plik zadanie-bojowe.yaml
Zwróć uwagę na komentarze – wyjaśniają, gdzie realizujemy poszczególne punkty zamówienia Szefa.


2. Wdrożenie
# kubectl apply -f zadanie-bojowe.yaml
    configmap/produkcja-config created
    deployment.apps/produkcja-app created
    service/produkcja-service created
    ingress.networking.k8s.io/produkcja-ingress created

3. Weryfikacja (Zanim zawołasz Szefa)
Sprawdź, czy wszystko "wstało":

# kubectl get all
$ kubectl get all
NAME                                   READY   STATUS             RESTARTS        AGE
pod/apple-754df5984f-bkqzq             1/1     Running            0               101m
pod/banana-5b95d46c88-fkfn2            1/1     Running            0               100m
pod/memory-demo                        0/1     CrashLoopBackOff   6 (4m28s ago)   10m
pod/my-webapp-5f56d9f4dd-6c8pt         1/1     Running            0               32h
pod/my-webapp-5f56d9f4dd-sf7p7         1/1     Running            0               32h
pod/my-webapp-5f56d9f4dd-vfm6b         1/1     Running            0               32h
pod/my-webapp-custom-c6c5f6f44-78cs5   1/1     Running            0               29h
pod/mysql-c7d44f448-rcvrp              1/1     Running            0               124m
pod/produkcja-app-6f54ff85dd-28m7x     1/1     Running            0               111s
pod/produkcja-app-6f54ff85dd-85t95     1/1     Running            0               111s
pod/produkcja-app-6f54ff85dd-hj9j5     1/1     Running            0               111s
pod/secure-pod                         1/1     Running            3 (45m ago)     27h
pod/zombie-app-6db6d4d847-brtt9        1/1     Running            0               27h

NAME                                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/apple                            ClusterIP   10.43.88.0     <none>        5678/TCP       97m
service/banana                           ClusterIP   10.43.145.85   <none>        5678/TCP       97m
service/kubernetes                       ClusterIP   10.43.0.1      <none>        443/TCP        2d1h
service/my-internal-service              ClusterIP   10.43.3.73     <none>        80/TCP         32h
service/my-internal-service-custom       ClusterIP   10.43.117.2    <none>        80/TCP         28h
service/my-nodeport-service              NodePort    10.43.165.45   <none>        80:30007/TCP   32h
service/my-nodeport-service-custom-app   NodePort    10.43.203.42   <none>        80:30008/TCP   28h
service/produkcja-service                ClusterIP   10.43.84.153   <none>        80/TCP         111s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/apple              1/1     1            1           101m
deployment.apps/banana             1/1     1            1           100m
deployment.apps/my-webapp          3/3     3            3           32h
deployment.apps/my-webapp-custom   1/1     1            1           29h
deployment.apps/mysql              1/1     1            1           130m
deployment.apps/produkcja-app      3/3     3            3           111s
deployment.apps/zombie-app         1/1     1            1           27h

NAME                                         DESIRED   CURRENT   READY   AGE
replicaset.apps/apple-754df5984f             1         1         1       101m
replicaset.apps/banana-5b95d46c88            1         1         1       100m
replicaset.apps/my-webapp-5f56d9f4dd         3         3         3       32h
replicaset.apps/my-webapp-custom-c6c5f6f44   1         1         1       29h
replicaset.apps/mysql-c7d44f448              1         1         1       130m
replicaset.apps/produkcja-app-6f54ff85dd     3         3         3       111s
replicaset.apps/zombie-app-6db6d4d847        1         1         1       27h
replicaset.apps/zombie-app-8b49b75fc         0         0         0       27h

Czy są 3 pody?
# kubectl get pods -l app=produkcja
    NAME                             READY   STATUS    RESTARTS   AGE
    produkcja-app-6f54ff85dd-28m7x   1/1     Running   0          2m37s
    produkcja-app-6f54ff85dd-85t95   1/1     Running   0          2m37s
    produkcja-app-6f54ff85dd-hj9j5   1/1     Running   0          2m37s


Czy Ingress widzi nasz adres IP?
# kubectl get ingress produkcja-ingress
    NAME                CLASS   HOSTS   ADDRESS      PORTS   AGE
    produkcja-ingress   nginx   *       172.17.0.2   80      3m15s


4. Wielki Finał
Otwórz przeglądarkę w Windowsie i wejdź na:
👉 http://localhost/produkcja/

działa!
----------- napis w przeglądarce ---------------------
To jest produkcja
Wdrozenie zakonczone sukcesem!
------------------------------------------------------

To, co widzisz w przeglądarce, to dowód na to, że właśnie samodzielnie zbudowałeś kompletne, produkcyjne mikro-środowisko.
Podsumujmy, co potrafisz (możesz to śmiało mówić na rozmowie o pracę):
1. Deploymenty: Wiesz, jak zarządzać skalowaniem aplikacji (3 repliki).
2. Storage & Config: Potrafisz oddzielić kod (obraz Nginx) od konfiguracji (ConfigMap z HTML). To kluczowa zasada "12 Factor App".
3. Resource Management: Potrafisz zabezpieczyć klaster przed "wyciekami pamięci" ustawiając Limity.
4. Networking & Ingress: Rozumiesz, jak wystawić aplikację na świat pod konkretną ścieżką URL, omijając skomplikowane numery portów.