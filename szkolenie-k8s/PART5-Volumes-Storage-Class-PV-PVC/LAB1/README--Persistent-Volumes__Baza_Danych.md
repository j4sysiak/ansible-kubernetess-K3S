Trwałość Danych (stateful Storage) – bo kontenery znikają, a dane muszą zostać.
-------------------------------------------------------------------------------

Lab 8: 
Persistent Volumes (Baza Danych):  `PV`
Scenariusz: Uruchamiasz bazę MySQL. 
Jeśli Pod się zrestartuje (co się zdarza), baza wstanie pusta. Musimy podpiąć "zewnętrzny dysk".
W Kubernetesie robimy to w dwóch krokach:
`PVC` (PersistentVolumeClaim): "Zlecenie" na dysk (np. "Poproszę 1GB miejsca").
`VolumeMount`: Podpięcie tego dysku do kontenera.
1. Stwórz `PVC` --> mysql-storage--pvc.yaml   
2. Stwórz --> mysql-deployment.yaml

3. Zadanie dla Ciebie (Test Trwałości):

Wdróż Persistent Volume Claim `PVC`:
# kubectl apply -f mysql-storage--pvc.yaml
    persistentvolumeclaim/mysql-pv-claim created

Wdróż Deployment:
# kubectl apply -f mysql-deployment.yaml
    deployment.apps/mysql created

Sprawdź Deployment (czy wszystko OK):
# kubectl get deployment mysql
    NAME    READY   UP-TO-DATE   AVAILABLE   AGE
    mysql   1/1     1            1           99s

Sprawdź Pody (czy Deployment działa):
# kubectl get pods -o wide
    NAME                               READY   STATUS    RESTARTS      AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0             30h     10.42.0.23   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0             30h     10.42.0.24   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0             30h     10.42.0.25   k3s-master   <none>           <none>
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0             27h     10.42.0.28   k3s-master   <none>           <none>
    mysql-c7d44f448-jw4xd              1/1     Running   0             3m56s   10.42.0.35   k3s-master   <none>           <none>
    secure-pod                         1/1     Running   1 (30m ago)   25h     10.42.0.31   k3s-master   <none>           <none>
    zombie-app-6db6d4d847-brtt9        1/1     Running   0             25h     10.42.0.33   k3s-master   <none>           <none>


Wejdź do poda: 
# kubectl exec -it mysql-c7d44f448-jw4xd -- mysql -p12345

Stwórz bazę: 
# CREATE DATABASE wazne_dane; 
i wyjdź (exit).

Zabij poda! 
# kubectl delete pod mysql-c7d44f448-jw4xd
    pod "mysql-c7d44f448-jw4xd" deleted from default namespace

Poczekaj, aż wstanie nowy (get pods).
# kubectl get pods -o wide
    NAME                               READY   STATUS    RESTARTS      AGE   IP           NODE         NOMINATED NODE   READINESS GATES
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0             30h   10.42.0.23   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0             30h   10.42.0.24   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0             30h   10.42.0.25   k3s-master   <none>           <none>
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0             27h   10.42.0.28   k3s-master   <none>           <none>
    mysql-c7d44f448-rcvrp              1/1     Running   0             39s   10.42.0.36   k3s-master   <none>           <none>
    secure-pod                         1/1     Running   1 (32m ago)   25h   10.42.0.31   k3s-master   <none>           <none>
    zombie-app-6db6d4d847-brtt9        1/1     Running   0             25h   10.42.0.33   k3s-master   <none>           <none>

  UWAGA: Nowy Pod ma inną nazwę (tu mysql-c7d44f448-rcvrp).
  wstal nowy Pod mysql-c7d44f448-rcvrp
  szok! ale nazwa jest inna!

Wejdź do nowego poda i sprawdź: 
# kubectl exec -it mysql-c7d44f448-rcvrp -- mysql -p12345

Warning: Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 1
Server version: 5.6.51 MySQL Community Server (GPL)

Copyright (c) 2000, 2021, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| wazne_dane         |   <--------------- Tutaj jest nasza baza! Hurra!
+--------------------+
4 rows in set (0.00 sec)

mysql>exit

