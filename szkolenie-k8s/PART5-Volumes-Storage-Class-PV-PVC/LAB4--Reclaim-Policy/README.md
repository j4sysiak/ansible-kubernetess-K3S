LAB4:
------
Reclaim Policy (Polityka Odzyskiwania)
---------------------------------------
# cd /home/jacek/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART5-Volumes-Storage-Class-PV-PVC/LAB4--Reclaim-Policy

krytyczny element.
Co się stanie z naszymi danymi, jak ktoś przez pomyłkę skasuje `PVC` (Zlecenie)?"
W obecnej konfiguracji odpowiedź brzmi: "Dane przepadną bezpowrotnie."
Dlatego proponuję ostatni, krótki LAB4, który dotyczy Reclaim Policy (Polityki Odzyskiwania). 

To jest Twój "dupochron".
 
Nauczysz się, jak skonfigurować wolumen tak, żeby nie kasował się automatycznie po usunięciu `PVC`. 
To różnica między Delete (domyślne) a Retain (zachowaj).
Opcja B: Idziemy dalej (StatefulSets)
Skoro umiesz już podpinać dyski, możemy przejść do StatefulSets. 
To jest specjalny rodzaj Deploymentu dedykowany do baz danych (np. jak zrobić klaster MySQL Primary-Replica), 
który bardzo mocno polega na wiedzy o `PVC`.

W domyślnej konfiguracji `Dynamic Provisioning`, którą robiliśmy w LAB2, `StorageClass` ma politykę Delete.
To oznacza: Kasujesz `PVC` (Zlecenie) -> Automat kasuje `PV` (Dysk) -> Dane znikają.
W produkcji dla bazy danych to katastrofa. 
Zrobimy teraz konfigurację `Retain` (Zachowaj).

Zrobimy to metodą `Static Provisioning` (ręczną), bo wtedy mamy pełną kontrolę nad parametrami dysku.
 
Krok 1: 
-------

Stwórz `PV` z polisą "Retain"
Stwórz plik: 5-pv-retain.yaml  
Zwróć uwagę na kluczową linię persistentVolumeReclaimPolicy.

Wdróż:
# kubectl apply -f 5-pv-retain.yaml
    persistentvolume/bezpieczny-dysk-pv created

Sprawdź:
# kubectl get pv
    NAME                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM                                                                                                               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    bezpieczny-dysk-pv   100Mi      RWO            Retain           Available                                                                                                                       manual-safe    <unset>                          105s


Krok 2:
-------
Stwórz `PVC`, które użyje tego `PV`
Stwórz plik: 6-pvc-retain.yaml
Zwróć uwagę, że storageClassName musi się zgadzać z tym w `PV`.

Wdróż:
# kubectl apply -f 6-pvc-retain.yaml
    persistentvolumeclaim/bezpieczne-zlecenie-pvc created

Sprawdź:
Poczekaj chwilę i sprawdź, czy się połączyły (Bound):
# kubectl get pvc bezpieczne-zlecenie-pvc
    NAME                      STATUS   VOLUME               CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
    bezpieczne-zlecenie-pvc   Bound    bezpieczny-dysk-pv   100Mi      RWO            manual-safe    <unset>                 20s

Krok 3: 
-------

Zapisz dane (Symulacja pracy)
Nie będziemy tworzyć pliku YAML dla Poda, zrobimy to "na skróty" z linii komend, podpinając ten dysk. 
Uruchomimy mały kontener, który zapisze plik i zniknie.
Wklej to w terminalu (jedna długa komenda):

```
kubectl run zapisywacz --image=alpine --restart=Never --overrides='
{
  "spec": {
            "volumes": [{"name": "vol", "persistentVolumeClaim": {"claimName": "bezpieczne-zlecenie-pvc"}}],
            "containers": [{
                            "name": "alpine",
                            "image": "alpine",
                            "command": ["sh", "-c", "echo BARDZO WAZNE DANE > /data/sekret.txt"],
                            "volumeMounts": [{"mountPath": "/data", "name": "vol"}]
                           }]
            }
}'
```
pod/zapisywacz created

Sprawdź:
# kubectl get pods zapisywacz
    NAME         READY   STATUS      RESTARTS   AGE
    zapisywacz   0/1     Completed   0          56s

Sprawdź, czy plik jest na dysku:
# kubectl run czytacz --image=alpine --restart=Never --overrides='
{
  "spec": {
            "volumes": [{"name": "vol", "persistentVolumeClaim": {"claimName": "bezpieczne-zlecenie-pvc"}}],
            "containers": [{                
                            "name": "alpine",
                            "image": "alpine",
                            "command": ["sh", "-c", "cat /data/sekret.txt"],
                            "volumeMounts": [{"mountPath": "/data", "name": "vol"}]
                           }]
            }   
}'
pod/czytacz created

# kubectl logs czytacz
    BARDZO WAZNE DANE


Krok 4:
-------

KATASTROFA (Symulacja błędu ludzkiego)
Szef przychodzi i przez pomyłkę kasuje Twoje Zlecenie `PVC`.
# kubectl delete pvc bezpieczne-zlecenie-pvc
W normalnych warunkach (LAB2) w tym momencie straciłbyś dane. Ale my mamy polisę Retain.

Krok 5: 
-------

Weryfikacja (Czy dane przetrwały?)
Sprawdź status Wolumenu `PV`:
# kubectl get pv bezpieczny-dysk-pv
    NAME                 CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
    bezpieczny-dysk-pv   100Mi      RWO            Retain           Bound    default/bezpieczne-zlecenie-pvc   manual-safe    <unset>                          22m

Co powinieneś zobaczyć:
Status: Released (Zwolniony).
To oznacza: "Klient oddał dysk, ale ja go NIE sformatowałem. 
Dysk leży na półce i czeka na admina. Dane są w środku."
Dowód ostateczny:
Sprawdźmy fizycznie w kontenerze Dockera, czy plik tam jest.
# docker exec -it k3s-master cat /tmp/dane-bezpieczne/sekret.txt
Jeśli zobaczysz "BARDZO WAZNE DANE", to uratowałeś firmę. 🛡️


Podsumowanie dla Szefa (Wnioski):
---------------------------------
 
Domyślnie (Delete): 
Kubernetes sprząta po sobie. 
Jak usuwamy aplikację i jej `PVC`, dysk jest formatowany (np. usuwany z AWS). 
To dobre dla plików tymczasowych.

Produkcja (Retain): 
Dla baz danych ustawiamy Retain. 
Jak ktoś przez pomyłkę usunie `PVC`, dysk w chmurze zostaje. 
Kubernetes go odłącza, ale nie kasuje. 
Administrator może ręcznie podpiąć go z powrotem.
To zamyka temat wolumenów. 
Masz teraz kompletny obraz: tworzenie dynamiczne, ręczne i zabezpieczanie przed skasowaniem.  



