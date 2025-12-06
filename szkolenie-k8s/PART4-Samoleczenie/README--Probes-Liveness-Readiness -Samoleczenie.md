Lab 7: Probes (Liveness & Readiness - Samoleczenie)
Scenariusz: Aplikacja czasem się zawiesza (działa proces, ale nie odpowiada na HTTP). 
Kubernetes myśli, że wszystko jest OK, ale użytkownicy widzą błędy.

Rozwiązanie:
Liveness Probe:  "Czy żyjesz?" Jeśli nie -> Restart Poda.
Readiness Probe: "Czy jesteś gotowy do pracy?" Jeśli nie -> Odłącz od Serwisu (nie kieruj ruchu).

1. Stwórz plik: self-healing.yaml

2. Zadanie dla Ciebie (Symulacja Awarii):
   Wdróż to: 
# kubectl apply -f self-healing.yaml
    deployment.apps/zombie-app created

Sprawdź status: 
# kubectl get pods -w
    NAME                               READY   STATUS    RESTARTS     AGE
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0            5h5m
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0            5h5m
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0            5h5m
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0            94m
    secure-pod                         1/1     Running   0            13m
    zombie-app-8b49b75fc-jps8p         1/1     Running   3 (4s ago)   49s

 Ups! Zobaczysz Restarts: 1, 2, 3.... Dlaczego? 
 Bo plik /tmp/healthy nie istnieje w obrazie nginx, 
 więc Kubernetes ciągle zabija i restartuje kontener. To dowód, że Liveness Probe działa!


3. Naprawa (Ćwiczenie):
   Edytuj plik YAML. Zmień livenessProbe na sprawdzenie HTTP (bo Nginx zawsze odpowiada na porcie 80):

```
livenessProbe:
    httpGet:
        path: /
        port: 80
    initialDelaySeconds: 5
    periodSeconds: 5
```

# kubectl apply -f self-healing.yaml
    deployment.apps/zombie-app created

Sprawdź status:
# kubectl get pods -w
    NAME                               READY   STATUS      RESTARTS   AGE
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running     0          5h9m
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running     0          5h9m
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running     0          5h9m
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running     0          97m
    secure-pod                         1/1     Running     0          17m
    zombie-app-6db6d4d847-brtt9        1/1     Running     0          2s
    zombie-app-8b49b75fc-jps8p         0/1     Completed   6          4m39s
    zombie-app-8b49b75fc-jps8p         0/1     Completed   6          4m39s

