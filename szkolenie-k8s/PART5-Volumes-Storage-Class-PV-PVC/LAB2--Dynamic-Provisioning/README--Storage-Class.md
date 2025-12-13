Storage Class (SC) jest często "cichym bohaterem", którego nie widać, dopóki się go nie poszuka, 
a to on odwala całą czarną robotę.
W Twoim ćwiczeniu (LAB2) Storage Class znajduje się w dwóch miejscach:
1. W Twoim pliku YAML (Zlecenie)
   Otwórz plik `1-pvc-dynamic.yaml`. 
   Zobaczysz tam linijkę:
   `spec:
    storageClassName: local-path  # <--- O TUTAJ!`
   W tym miejscu powiedziałeś Kubernetesowi: 
   "Hej, chcę dysk. Niech zajmie się tym wykonawca o nazwie local-path".

2. W Twoim Klastrze (Firma Budowlana)
   Storage Class to obiekt, który już istnieje w Twoim klastrze (zainstalował go K3s przy starcie). Sprawdźmy go.
   Wpisz w terminalu:
# kubectl get sc      (Skrót sc to StorageClass).
     NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
     local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  ...
   
   Jak to działa w praktyce? (Mechanizm)
   Wyobraź sobie taką scenę w restauracji:

   Ty (Programista): 
   -----------------
   Podnosisz rękę i dajesz kelnerowi kartkę (to jest PVC). 
   Na kartce jest napisane: "Poproszę Pizzę (1GB miejsca)".
   
   Kelner (API Server): 
   --------------------
   Patrzy na kartkę. 
   Widzi dopisek: `storageClassName: local-path`.
   `Storage Class` (Szef Kuchni - local-path): Kelner zanosi zamówienie do konkretnego kucharza (Storage Class).
   Gdybyś napisał aws-ebs, zamówienie poszłoby do kucharza od AWS.
   Gdybyś napisał azure-file, poszłoby do kucharza od Azure.
   Napisałeś local-path, więc zamówienie trafiło do "Kucharza Lokalnego".
   
   Persistent Volume (Pizza): 
   --------------------------
   Kucharz (local-path) bierze mąkę i piecze Pizzę (tworzy fizyczny katalog na dysku). 
   Następnie wydaje ją kelnerowi jako gotowy produkt `PV`.
   Bound: Kelner stawia Pizzę (PV) na Twoim stoliku `PVC`. Zamówienie zrealizowane.
   
   Dlaczego K3s używa local-path?
   Ponieważ Twój klaster działa w kontenerze Dockera, nie ma dostępu do prawdziwych, fizycznych dysków twardych czy chmury Amazon/Google.
   `Storage Class` local-path to sprytny skrypt w K3s, który mówi:
   "Nie mam prawdziwych dysków, więc jak ktoś poprosi o wolumen, to po prostu stworzę nowy folder wewnątrz kontenera k3s-master i będę udawał, że to profesjonalny dysk."
   
   Podsumowując
   -------------------------------------------------------------------
   `PVC`: Twoje żądanie ("Chcę dysk").
   `Storage Class`: Automat/Reguła ("Jak i gdzie ten dysk stworzyć").
   `PV`: Wynik ("Konkretny kawałek pamięci").

Gdybyś nie wpisał w YAML storageClassName: local-path, 
   Kubernetes użyłby klasy oznaczonej jako (default) – czyli w K3s i tak użyłby local-path.