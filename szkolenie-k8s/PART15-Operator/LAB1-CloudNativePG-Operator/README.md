Operators to przyszłość zarządzania złożonymi systemami
-------------------------------------------------------

# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART15-Operator/LAB1-CloudNativePG-Operator

Kubernetes Operator to najwyższy poziom wtajemniczenia w zarządzaniu aplikacjami.

Szef pyta: "Jacek, po co nam Operator, skoro mamy Helma?"

Ty odpowiadasz:
Helm jest jak instalator (np. setup.exe). 
Wrzuca pliki, uruchamia aplikację i... idzie do domu. 
Jak aplikacja padnie w nocy, Helm o tym nie wie.

Operator to inteligentny robot-administrator, który działa w klastrze 24/7.
1. instaluje aplikację.
2. Ciągle ją obserwuje.
3. Jeśli baza danych padnie -> Operator ją podnosi.
4. Jeśli trzeba zrobić backup -> Operator go robi.
5. Jeśli trzeba zaktualizować wersję -> Operator robi to bezpiecznie, krok po kroku.

Technicznie: 
Operator to program (Pod), który rozszerza API Kubernetesa o nowe "słowa" (Custom Resource Definitions - CRD).


Scenariusz Laboratorium
-----------------------
Zamiast męczyć się z ręcznym stawianiem klastra PostgreSQL (co jest trudne: replikacja, faiover, users), 
zainstalujemy `CloudNativePG Operator`.
`CloudNativePG Operator` to jest taki robot, któremu powiesz: "Chcę klaster PostgreSQL z 3 replikami", a on sam utworzy:
 - Pody
 - Serwisy
 - Sekrety
 - PVC
 - skonfiguruje replikację

Krok.1: 
-------
Instalacja Operatora (Zatrudniamy Robota)
Najpierw musimy "nauczyć" nasz klaster nowych sztuczek (wgrać `CRD`) i uruchomić samego Operatora. 
Użyjemy Helma (bo już go umiesz).

Dodaj repozytorium i zainstaluj:
# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART15-Operator/LAB1-CloudNativePG-Operator
# helm repo add cnpg https://cloudnative-pg.github.io/charts
    "cnpg" has been added to your repositories

# helm repo update
    Hang tight while we grab the latest from your chart repositories...
    ...Successfully got an update from the "cnpg" chart repository
    ...Successfully got an update from the "ingress-nginx" chart repository
    ...Successfully got an update from the "grafana" chart repository
    ...Successfully got an update from the "prometheus-community" chart repository
    Update Complete. ⎈Happy Helming!⎈

# helm upgrade --install cnpg \
   --namespace cnpg-system \
   --create-namespace \
   cnpg/cloudnative-pg

    Release "cnpg" does not exist. Installing it now.
    NAME: cnpg
    LAST DEPLOYED: Wed Dec 17 20:49:14 2025
    NAMESPACE: cnpg-system
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    CloudNativePG operator should be installed in namespace "cnpg-system".
    You can now create a PostgreSQL cluster with 3 nodes as follows:

    cat <<EOF | kubectl apply -f -
      # Example of PostgreSQL cluster
      apiVersion: postgresql.cnpg.io/v1
      kind: Cluster
      metadata:
      name: cluster-example

      spec:
      instances: 3
      storage:
      size: 1Gi
    EOF


Sprawdź, czy Robot działa:
# kubectl get pods -n cnpg-system
    NAME                                   READY   STATUS    RESTARTS   AGE
    cnpg-cloudnative-pg-586fdb5674-9kmcz   1/1     Running   0          113s
Powinieneś zobaczyć poda cnpg-controller-manager-... w stanie Running. To jest mózg operacji.

3. Sprawdź nowe "słowa" w słowniku K8s (CRD):
   Wpisz:
# kubectl api-resources | grep postgres
    backups                                          postgresql.cnpg.io/v1             true         Backup
    clusterimagecatalogs                             postgresql.cnpg.io/v1             false        ClusterImageCatalog
    clusters                                         postgresql.cnpg.io/v1             true         Cluster
    databases                                        postgresql.cnpg.io/v1             true         Database
    failoverquorums                                  postgresql.cnpg.io/v1             true         FailoverQuorum
    imagecatalogs                                    postgresql.cnpg.io/v1             true         ImageCatalog
    poolers                                          postgresql.cnpg.io/v1             true         Pooler
    publications                                     postgresql.cnpg.io/v1             true         Publication
    scheduledbackups                                 postgresql.cnpg.io/v1             true         ScheduledBackup
    subscriptions                                    postgresql.cnpg.io/v1             true         Subscription

Zobaczysz nowe typy obiektów, np. clusters, backups, scheduledbackups. 
Wcześniej ich nie było! 
Teraz Twój Kubernetes "rozumie", czym jest Klaster Bazy Danych.

KROK.2:
-------

Tworzenie Klastra DB (Magia `CRD`)
Teraz, zamiast pisać 500 linii YAML z Deploymentami i Serwisami, napiszemy krótki plik, używając nowego obiektu Cluster.

Stwórz plik: database.yaml 


Wdróż to:
# kubectl apply -f database.yaml
    cluster.postgresql.cnpg.io/moja-baza-szefa created

Obserwuj magię (To robi wrażenie!):
Nie patrz tylko na koniec, obserwuj proces tworzenia. 
Operator najpierw stworzy instancję nr 1, poczeka aż wstanie, potem nr 2 i nr 3.
# watch kubectl get pods
         Every 2.0s: kubectl get pods: Friedrichshafen: Wed Dec 17 20:58:24 2025
         NAME                                READY   STATUS             RESTARTS          AGE
         [...]
    ---> moja-baza-szefa-1-initdb-lpf97      0/1     PodInitializing    0                 108s
         [...]

po kilku minutach:
# watch kubectl get pods

         NAME                                READY   STATUS             RESTARTS          AGE
         [...]
    ---> moja-baza-szefa-1                   1/1     Running            0                 2m27s
    ---> moja-baza-szefa-2                   1/1     Running            0                 2m4s
    ---> moja-baza-szefa-3                   1/1     Running            0                 101s
         [...]
 
 

Co Operator stworzył "pod maską"?
   Wpisz:
# kubectl get all -l cnpg.io/cluster=moja-baza-szefa
    NAME                                 READY   STATUS            RESTARTS   AGE
    pod/moja-baza-szefa-1   1/1     Running   0          4m31s
    pod/moja-baza-szefa-2   1/1     Running   0          4m8s
    pod/moja-baza-szefa-3   1/1     Running   0          3m45s

    NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    service/moja-baza-szefa-r    ClusterIP   10.43.113.25    <none>        5432/TCP   9m57s
    service/moja-baza-szefa-ro   ClusterIP   10.43.20.236    <none>        5432/TCP   9m57s
    service/moja-baza-szefa-rw   ClusterIP   10.43.246.237   <none>        5432/TCP   9m57s

    NAME                                 STATUS    COMPLETIONS   DURATION   AGE
    job.batch/moja-baza-szefa-1-initdb   Running   0/1           4m40s      4m40s

 
Zobaczysz, że Operator automatycznie stworzył:
1. Pody
2. Serwisy (Read-Write dla zapisu, Read-Only dla odczytu!)
3. Sekrety z hasłami
4. `PVC` (dyski)



KROK.3:
-------
Test "Day 2" - Automatyczny Failover (Awaria)
To jest ten moment, za który płaci się DevOpsom. 
Symulujemy awarię.

1. Sprawdź, kto jest szefem (Primary):
`Operator CloudNativePG` ma plugin do kubectl, ale my sprawdzimy to "na piechotę". 
Zazwyczaj pod z końcówką -1 jest pierwszy, ale sprawdźmy status klastra (to jest komenda customowa operatora!):
# kubectl get cluster moja-baza-szefa
    NAME              AGE   INSTANCES   READY   STATUS                     PRIMARY
    moja-baza-szefa   13m   3           3       Cluster in healthy state   moja-baza-szefa-1
W kolumnie STATUS powinno być Cluster in healthy state, a w PRIMARY nazwa poda (np. moja-baza-szefa-1).

Zabijamy Szefa! (Symulacja awarii serwera)
Skasuj poda, który jest aktualnie Primary.
# kubectl delete pod moja-baza-szefa-1
    pod "moja-baza-szefa-1" deleted from default namespace

Patrz co się dzieje (Szybko!):
# watch kubectl get pods
         NAME                                READY   STATUS             RESTARTS          AGE
         [...]
    ---->moja-baza-szefa-1                   1/1     Running            0                 108s <---  zrestartowal sie primary-1
         moja-baza-szefa-2                   1/1     Running            0                 10m
         moja-baza-szefa-3                   1/1     Running            0                 10m

oraz:
# watch kubectl get cluster moja-baza-szefa
    Every 2.0s: kubectl get cluster moja-baza-szefa                                                                    Friedrichshafen: Wed Dec 17 21:12:12 2025

    NAME              AGE   INSTANCES   READY   STATUS                     PRIMARY
    moja-baza-szefa   15m   3           3       Cluster in healthy state   moja-baza-szefa-2  <---nowy POD primary

Co zrobi Operator (Robot):
Zauważy, że Primary zniknął.
Natychmiast awansuje jednego z pozostałych podów (np. -2) na nowego Primary.
Zaktualizuje Serwisy, żeby aplikacje pisały do nowego lidera.
Stary pod (-1) wstanie ponownie, ale Operator skonfiguruje go już jako Standby (Replika), a nie Primary.
To jest Automatyczny Failover.
Bez Operatora musiałbyś budzić się w nocy i ręcznie rekonfigurować pliki konfiguracyjne PostgreS.

# kubectl get all -l cnpg.io/cluster=moja-baza-szefa
    NAME                    READY   STATUS    RESTARTS   AGE
    pod/moja-baza-szefa-1   1/1     Running   0          4m16s  <----------  new pod
    pod/moja-baza-szefa-2   1/1     Running   0          13m
    pod/moja-baza-szefa-3   1/1     Running   0          12m

    NAME                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    service/moja-baza-szefa-r    ClusterIP   10.43.113.25    <none>        5432/TCP   18m
    service/moja-baza-szefa-ro   ClusterIP   10.43.20.236    <none>        5432/TCP   18m
    service/moja-baza-szefa-rw   ClusterIP   10.43.246.237   <none>        5432/TCP   18m

KROK.4:
-------

Połączenie z Bazą (Jak tego użyć?)
Szef zapyta: 
"No dobra, baza stoi i się sama naprawia. Ale jak aplikacja ma się z nią połączyć?"

Operator stworzył Sekrety z hasłami.
Wyciągnij hasło:
# kubectl get secret moja-baza-szefa-app -o jsonpath='{.data.password}' | base64 -d
    iXY5twui4KxLX9AzxGGmtr146wnWjTTxVR3OnqzpaoB2gDGCVk9yznk0RpJpmECc

(Skopiuj to hasło).
Uruchom klienta (tymczasowy pod):
   Połączymy się z serwerem. Operator stworzył serwis o nazwie moja-baza-szefa-rw (Read-Write).
 # kubectl run pg-client --image=postgres:15 -i --tty --rm -- psql -h moja-baza-szefa-rw -U appuser -d appdb
   (Gdy zapyta o hasło, wklej to z punktu 1).
   Jeśli zobaczysz:
   appdb=>
   To znaczy, że jesteś w środku. Twoja baza działa, jest zreplikowana i odporna na awarie.


    All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
    If you don't see a command prompt, try pressing enter.
    --> tu wklej haslo
    psql (15.15 (Debian 15.15-1.pgdg13+1), server 18.1 (Debian 18.1-1.pgdg13+2))
    WARNING: psql major version 15, server major version 18.
    Some psql features might not work.
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
    Type "help" for help.
    appdb=>

SUKCES!

Podsumowanie dla Szefa:
-----------------------
1. Operator to Wiedza: 
   To nie tylko skrypt instalacyjny. 
   To "wiedza eksperta PostgreSQL" zaklęta w kodzie, który działa w naszym klastrze.

2. Automatyzacja: 
   Operator sam zarządza backupami, aktualizacjami i awariami.

3. Standard: 
   Używamy kind: Cluster zamiast skomplikowanych Deploymentów. 
   To upraszcza nasze pliki YAML.
 







