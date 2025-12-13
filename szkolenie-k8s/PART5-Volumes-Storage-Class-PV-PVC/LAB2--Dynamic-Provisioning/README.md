Volumes-Storage-PV-PVC
----------------------
`Dynamic Provisioning` (Lab 2):
-------------------------------

# cd /home/jacek/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART5-Volumes-Storage-PV-PVC/LAB2


To jest jeden z najtrudniejszych, ale absolutnie niezbędnych tematów w Kubernetesie. 
Bez zrozumienia wolumenów (Volumes) nie da się uruchomić żadnej bazy danych ani poważnej aplikacji `stateful`.
Szef ma rację – musisz rozumieć różnicę między tymi trzema pojęciami, bo na początku wydają się one masłem maślanym.
Przygotowałem dla Ciebie "Volume Masterclass" w Twoim środowisku K3s.

Teoria dla Szefa (Analogia: Budowa Domu)
Zanim wpiszemy kod, musisz "czuć" różnicę. Wyobraź sobie, że budujesz dom `POD`.
 - `StorageClass` (SC) = "Deweloper / Wykonawca":
    Mówisz: "Chcę dysk typu 'Szybki SSD'" albo "Chcę tani dysk sieciowy". 
    `StorageClass` to definicja RODZAJU dysku.

W K3s masz domyślnego "wykonawcę, czyli Storage Class" o nazwie `local-path` (tworzy foldery na dysku kontenera).

`PersistentVolumeClaim` (PVC) = "Kupon / Zlecenie":
To jest Twój dokument żądania. 
Podpisujesz: "Poproszę 1GB z klasy 'Szybki SSD' z dostępem tylko dla mnie".
Ty (jako programista) tworzysz tylko PVC. Nie obchodzi Cię, skąd ten dysk się weźmie.

`PersistentVolume` (PV) = "Fizyczna Działka / Dysk":
To jest konkretny kawałek zasobu (np. fizyczny folder, dysk w chmurze AWS EBS).
`PV` jest "spinany" (Bound) z Twoim kuponem `PVC`.
W skrócie: 
Ty tworzysz `PVC` (Zlecenie), a `StorageClass` (Automat / Wykonawca) tworzy dla Ciebie `PV` (Dysk).

LAB2: 
-----
Dynamic Provisioning (Magia Automatyzacji)
To jest sposób, w jaki pracuje się w 99% przypadków w chmurze. 
Ty prosisz o dysk `PVC`, a klaster sam go tworzy.

Krok 1.
-------
Sprawdź, jakiego mamy "Wykonawcę" `StorageClass`:
# kubectl get sc
    NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  18d
(Powinieneś zobaczyć local-path (default)).

Krok 2.
-------
Stwórz Zlecenie (PVC) - 1-pvc-dynamic.yaml:
   Prosimy o 100 Megabajtów miejsca.

Wdróż to: 
# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART5-Volumes-Storage-PV-PVC/LAB2
# kubectl apply -f 1-pvc-dynamic.yaml
    persistentvolumeclaim/moje-zlecenie-pvc created

Krok 3.
-------
Obserwuj magię:
   Sprawdź PVC:
# kubectl get pvc
          NAME                STATUS    VOLUME  CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
    ----> moje-zlecenie-pvc   Pending                                     local-path     <unset>                 77s
 
 
Twoje `PVC` wisi w stanie `Pending`, ponieważ domyślna klasa pamięci w K3s (local-path) ma ustawiony tryb: `WaitForFirstConsumer`.
Co to znaczy "WaitForFirstConsumer"?
Wróćmy do analogii budowlanej:
Złożyłeś Zlecenie `PVC` u Wykonawcy.
Wykonawca mówi:
"Dobra, widzę zlecenie. 
Ale nie będę kopał dziury w ziemi (tworzył PV), dopóki nie powiesz mi, GDZIE stanie dom (Pod)."
K3s jest sprytny. 
Nie tworzy wolumenu od razu, bo w klastrach wielowęzłowych musi wiedzieć, 
             na którym konkretnie serwerze uruchomi się Pod, żeby tam stworzyć pliki.
Rozwiązanie:
Musisz stworzyć Poda
Dopóki nie uruchomisz Poda, który używa tego `PVC`, status będzie Pending.



Sprawdź `PV` (którego NIE tworzyłeś ręcznie!):
# kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                                                                               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    pvc-1be55cf7-d6c3-4c65-a9ae-2ed6470ba793   1Gi        RWO            Delete           Bound    monitoring/prometheus-prometheus-stack-kube-prom-prometheus-db-prometheus-prometheus-stack-kube-prom-prometheus-0   local-path     <unset>                          18d
    pvc-b1045c45-c2f3-4fa7-bffa-9ea991bfe3d2   1Gi        RWO            Delete           Bound    default/vaultwarden-pvc                                                                                             local-path     <unset>                          3d3h
    pvc-c24ea79f-d0b4-40a5-b81a-4687143fc2c3   1Gi        RWO            Delete           Bound    default/mysql-pv-claim                                                                                              local-path     <unset>                          16d


Na liście `kubectl get pv` na razie nie ma wolumenu przypisanego do `default/moje-zlecenie-pvc`, to znaczy, 
            że StorageClass (Twój "Wykonawca") jeszcze nie przystąpił do pracy.
Dlaczego? Bo wciąż czeka na `Krok 4`, czyli uruchomienie Poda.
Łańcuch wydarzeń (Co musi się stać):
1. Ty: Tworzysz `PVC` (Zlecenie). -> Status: `Pending`.
2. `StorageClass`: Widzi zlecenie, ale mówi: "Czekam na pierwszego klienta (WaitForFirstConsumer)".
3. Ty: Tworzysz Poda (2-pod-dynamic.yaml). <-- TU JESTEŚMY
4. Kubernetes (Scheduler): Przypisuje Poda do konkretnego węzła (k3s-master).
5. `StorageClass`: "Aha! Pod ma ruszyć na k3s-master. To teraz wiem, gdzie stworzyć folder!".
6. `StorageClass`: Tworzy fizyczny `PV`.
7. Kubernetes: Zmienia status `PVC` na `Bound`.
8. Pod: Uruchamia się (Running).

To musisz zrobić teraz.
# kubectl get pod pod-z-dyskiem
    Error from server (NotFound): pods "pod-z-dyskiem" not found
Nie wdrożyłeś pliku z Podem.
więc idziemy do kroku 4.

Krok 4.
-------
Użyj tego w Podzie - 2-pod-dynamic.yaml:
   Podepniemy ten dysk pod serwer Nginx, żeby przechowywał tam plik index.html.

Wdróż to tj tego PODa: 
# kubectl apply -f 2-pod-dynamic.yaml
    pod/pod-z-dyskiem created

Krok 5.
-------
Test Trwałości:
Wejdź do poda i stwórz plik:
# kubectl exec pod-z-dyskiem -- sh -c "echo 'DANE TRWALE' > /usr/share/nginx/html/index.html"

Sprawdź, czy plik tam jest:
# kubectl exec pod-z-dyskiem -- cat /usr/share/nginx/html/index.html
    DANE TRWALE

Skasuj poda:
# kubectl delete pod pod-z-dyskiem
    pod "pod-z-dyskiem" deleted from default namespace

Sprawdź, czy plik tam jest:
# kubectl exec pod-z-dyskiem -- cat /usr/share/nginx/html/index.html
    Error from server (NotFound): pods "pod-z-dyskiem" not found

Wdróż go ponownie:
# kubectl apply -f 2-pod-dynamic.yaml

Sprawdź, czy plik tam jest:
# kubectl exec pod-z-dyskiem -- cat /usr/share/nginx/html/index.html
    DANE TRWALE

Jeśli widzisz "DANE TRWALE", to znaczy, że zadziałało. Dysk (PV) przeżył śmierć Poda.

Co się właśnie stało:
1. Stworzyłeś `PersistentVolumeClaim` (Zlecenie na dysk).
2. Stworzyłeś Poda, który używa tego PVC.
3. Kubernetes przydzielił Poda do węzła (k3s-master
4. StorageClass (local-path) zobaczył, gdzie jest Pod i stworzył fizyczny `PersistentVolume` (folder na dysku).
5. Kubernetes "spiął" (Bound) PVC z PV.
6. Pod uruchomił się, mając dostęp do trwałego dysku.
7. Dane na tym dysku przetrwały restart Poda.
Gratulacje! Jesteś teraz mistrzem Dynamicznego Provisioningu w Kubernetes!


Powinno teraz być STATUS: Bound
# kubectl get pvc
    NAME                STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
    moje-zlecenie-pvc   Bound    pvc-f4717eda-3d27-46a6-a3f2-720ff35e57e4   100Mi      RWO            local-path     <unset>                 25m

Powinien teraz być widoczny PV utworzony automatycznie:
# kubectl get pv
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                                                                               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    pvc-f4717eda-3d27-46a6-a3f2-720ff35e57e4   100Mi      RWO            Delete           Bound    default/moje-zlecenie-pvc 


Podsumowanie dla Szefa:
-----------------------
`Dynamic Provisioning` (Lab 2):
"Szefie, używamy tego na co dzień.
Ja proszę o dysk (PVC), a chmura (StorageClass) sama mi go tworzy. Szybko i wygodnie."

 







