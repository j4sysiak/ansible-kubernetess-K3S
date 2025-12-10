Volumes-Storage-PV-PVC
----------------------
`Static Provisioning` (Lab 3): (Ręczna robota)
----------------------------------------------

# cd /home/jacek/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART5-Volumes-Storage-PV-PVC/LAB3


Czasami (rzadko) szef powie: "Mamy stary dysk twardy (NFS lub folder), musisz go podpiąć ręcznie, automat tego nie zrobi".
Wtedy musisz ręcznie stworzyć `PV` i ręcznie `PVC`.

KROK 1.
-------
Stwórz PV (Fizyczny zasób) - 3-pv-manual.yaml:
   W K3s na Dockerze użyjemy typu hostPath (folder wewnątrz kontenera Dockera).

Wdróż: 
# kubectl apply -f 3-pv-manual.yaml
    persistentvolume/manualny-pv-500m created

Sprawdź: 
# kubectl get pv    (Status: Available - czeka na klienta).
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                                                                               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    manualny-pv-500m                           500Mi      RWO            Retain           Available                                                                                                                       manual         <unset>                          21s
    pvc-f4717eda-3d27-46a6-a3f2-720ff35e57e4   100Mi      RWO            Delete           Bound       default/moje-zlecenie-pvc                                                                                           local-path     <unset>                          12m

Krok 2.
-------
Stwórz `PVC` (Zlecenie na ten konkretny dysk) - 4-pvc-manual.yaml:
Żeby `PVC` połączyło się z tym konkretnym `PV`, muszą się zgadzać:
  - storageClassName (manual)
  - accessModes
  - Rozmiar (PVC musi chcieć tyle samo lub mniej niż ma PV).

Wdróż: 
# kubectl apply -f 4-pvc-manual.yaml
    persistentvolumeclaim/manualne-zlecenie-pvc created


Krok 3.
-------

Moment prawdy (sprawdź):
Powinno teraz być STATUS: Bound
# kubectl get pvc
           NAME                    STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
    TU---->manualne-zlecenie-pvc   Bound    manualny-pv-500m                           500Mi      RWO            manual         <unset>                 108s
           moje-zlecenie-pvc       Bound    pvc-f4717eda-3d27-46a6-a3f2-720ff35e57e4   100Mi      RWO            local-path     <unset>                 34m


Powinien teraz być widoczny PV utworzony automatycznie:
# kubectl get pv
    NAME               CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                              STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    manualny-pv-500m   500Mi      RWO            Retain           Bound    default/manualne-zlecenie-pvc      manual         <unset>                          4m20s



Jeśli zrobiłeś wszystko dobrze, status obu zmieni się na Bound. 
Kubernetes znalazł pasujące do siebie `PV` i `PVC` i je "ożenił".

Podsumowanie dla Szefa:
-----------------------
`Static Provisioning` (Lab 2): 
"Używamy tego tylko, jak mamy specyficzny, istniejący już zasób (np. macierz dyskową), który musimy podpiąć 
                                                                                               'na sztywno' do klastra."














