Helm to najlepszy przyjaciel administratora Kubernetes. 
Jak raz to zrozumiesz, nie będziesz chciał wracać do zwykłych plików YAML.
To jest esencja Helma: Jeden szablon, wiele różnych konfiguracji.
 
# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB1--Helm-Chart--Hello_World

opis Helma i Charta:
--------------------
# vi ~/dev/ansible-kubernetess-K3S/README__opis_podstawowych_pojęć_Kubernetesa.md


opis skrótowy Helma:
--------------------
Wyobraź sobie, że piszesz pismo urzędowe (Deployment).

Bez Helma (Czysty Kubernetes): 
------------------------------
Masz wydrukowane pismo, w którym długopisem wpisałeś dane. 
Jak chcesz zmienić nazwisko, musisz przepisać całą stronę na nowo.

Z Helmem: 
---------
Masz szablon w Wordzie z pustymi polami (np. {{ IMIE_NAZWISKO }}).
Masz osobny mały plik `values.yaml` (dane), gdzie wpisujesz: Jan Kowalski.
Helm klika "Drukuj" -> łączy szablon z danymi -> wysyła gotowy plik do Kubernetesa.
Helm Chart to po prostu folder, w którym leżą te szablony.

Zadanie - task
--------------
1. Stworzymy Charta.
3. Dodamy własny szablon (Template).
3. Wstrzykniemy własną konfigurację przez plik `values.yaml`.

Krok 1: 
-------
Generowanie Charta (helm create)
Helm ma komendę, która tworzy gotową strukturę katalogów (szkielet). 
Nazwijmy nasz chart `moj-nginx`.
# helm create moj-nginx
Zobacz, co powstało:
# ls -F moj-nginx/
Powinieneś zobaczyć:  `cd moj-nginx/`
 - Chart.yaml (Metadane: nazwa, wersja).
 - values.yaml (Tu wpisujemy nasze dane/zmienne).
 - templates/ (Tu leżą szablony z "dziurami" na dane).

Krok 2: 
-------
Sprzątanie (Dla jasności)
Domyślny szkielet jest bardzo skomplikowany (ma Ingressy, ServiceAccounty itd.). 
Żebyś zrozumiał zasadę, uprościmy go drastycznie.
Wejdź do katalogu i usuń domyślne szablony:
# cd moj-nginx
rm -rf templates/*
Teraz masz czysty chart bez żadnych plików w templates. 
Budujemy od zera.

Krok 3: 
-------
Dodanie własnego Szablonu (Template)
Szef chciał "dodać jakiś template". 
Stworzymy `ConfigMap`, która będzie przechowywać wiadomość powitalną.
Stwórz plik:  templates/configmap.yaml (wewnątrz katalogu moj-nginx):
 
Zauważ te dziwne nawiasy {{ ... }}. To jest miejsce, gdzie Helm wstawi dane.
.Release.Name - to nazwa, którą nadamy przy instalacji (np. "instancja-1").
.Values.szef.wiadomosc - to wartość, którą pobierzemy z pliku values.yaml.

Krok 4: 
-------
Konfiguracja Wartości (values.yaml)
Teraz musimy zdefiniować tę wartość szef.wiadomosc.
Otwórz plik values.yaml (jest w katalogu moj-nginx). Usuń wszystko co tam jest i wklej tylko to:
 
```
# To jest plik z domyślną konfiguracją
szef:
wiadomosc: "Domyślna wiadomość: Pracujcie ciężko!"
```

Krok 5: 
-------
Instalacja (Połączenie Szablonu z Danymi)
Wyjdź z katalogu czarta o jeden poziom w górę:
# cd ..

Teraz najważniejsza komenda. 
Mówimy Helmowi: "Zainstaluj chart z katalogu moj-nginx i nazwij to wdrożenie test-helma".
# helm install test-helma ./moj-nginx

    NAME: test-helma
    LAST DEPLOYED: Sat Dec 13 18:59:48 2025
    NAMESPACE: default
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None

Weryfikacja:
Sprawdź, czy `ConfigMap` powstał i co ma w środku:
# ckubectl get cm
        NAME                DATA   AGE
        kube-root-ca.crt    1      20d
        my-website-config   1      20d
        produkcja-config    1      18d
    --->test-helma-config   1      2m4s <--------------  jest!

 Powinieneś widzieć: test-helma-config

# kubectl describe cm test-helma-config
```
Name:         test-helma-config
Namespace:    default
Labels:       app.kubernetes.io/managed-by=Helm
Annotations:  meta.helm.sh/release-name: test-helma
meta.helm.sh/release-namespace: default

Data
====
index.html:
----
<html>
<h1>Wiadomosc od Szefa:</h1>
<p>Domyślna wiadomość: Pracujcie ciężko!</p>   <------------------------------------- jest!
</html>
BinaryData
====
Events:  <none>
```

Powinieneś zobaczyć w Data: Domyślna wiadomość: `Pracujcie ciężko!`.


Krok 6: 
-------
Custom Configuration (Nadpisywanie)
Teraz pokażemy potęgę Helma. 
Szef chce zmienić wiadomość, ale bez edytowania plików wewnątrz charta.
Mamy dwie opcje:

Opcja A: Przez linię komend (--set)
# helm upgrade test-helma ./moj-nginx --set szef.wiadomosc="Podwyżki nie będzie!"


Sprawdź teraz:
# kubectl describe cm test-helma-config
```
<html>
<h1>Wiadomosc od Szefa:</h1>
<p>Podwyżki nie będzie!</p>      <------------------------------------- jest!
</html>
```

Widzisz? Tekst się zmienił na "Podwyżki nie będzie!".


Opcja B: Przez własny plik values (Bardziej profesjonalnie)
1. Stwórz plik moje-ustawienia.yaml (obok katalogu z chartem):
2. Zrób upgrade używając tego pliku:
# helm upgrade test-helma ./moj-nginx -f moje-ustawienia.yaml

Sprawdź ponownie:
# kubectl describe cm test-helma-config
```
<html>
<h1>Wiadomosc od Szefa:</h1>
<p>Żartowałem, premia w piątek!</p>      <------------------------------------- jest!
</html>
```
Powinno być o premii.



Podsumowanie dla Szefa
Zrealizowałeś zadanie w 100%:
1. Create helm chart: Stworzyłeś strukturę `moj-nginx`.
2. Add template: Dodałeś plik templates/configmap.yaml z kodem {{ .Values... }}.
3. Custom configuration:
      Pokazałeś, jak zmieniać działanie (treść ConfigMapy) używając `values.yaml` lub flagi --set, 
      bez dotykania kodu źródłowego szablonu.
To jest esencja Helma: Jeden szablon, wiele różnych konfiguracji.


