szkolenia prowadzonego przez Mumshada Mannambetha (z kursu KodeKloud).
https://www.youtube.com/watch?v=GhZi4DxaxxE&t=95s
od 10 min.
----------------------------------------------------------------------
Ingress Controler on NGINX  z serwisem NodePort
----------------------------------------------------------------------
czyli opowieść, z jakich "części" składa się recepcjonista (Pod + Service + ConfigMap).
---------------------------------------------------------------------------------------

# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART11-Online-store-part-2--Manual-ingress/LAB1-manual-ingress-as-NodePort

To ćwiczenie pokazuje, jak zbudować `Ingress Controller` od zera, tworząc ręcznie wszystkie wymagane obiekty Kubernetes.
Stwórzmy nowy katalog, żeby nie pomieszać tego z poprzednimi ćwiczeniami.

Krok 1: 
-------
Konfiguracja i Uprawnienia (ConfigMap, ServiceAccount)
Wideo wyjaśnia, że Nginx potrzebuje miejsca na konfigurację (ConfigMap) 
oraz uprawnień do "patrzenia" na klaster (ServiceAccount). 
Dodatkowo musimy stworzyć Namespace (namespace: `ingress-space`), żeby trzymać tam porządek.

Stwórz plik: 1-prereqs.yaml 
1. tworzy namespace: `ingress-space`, żeby trzymać tam wszystkie obiekty związane z Ingressem
2. tworzy `ConfigMap` dla Nginx, żeby mógł trzymać swoją konfigurację
3. tworzy `ServiceAccount` dla Nginx, żeby miał tożsamość w klastrze
4. tworzy `ClusterRole` z uprawnieniami dla Nginx, żeby mógł czytać Ingressy i Serwisy w całym klastrze
5. tworzy `ClusterRoleBinding`, który łączy `ServiceAccount` z `ClusterRole`, żeby Nginx miał te uprawnienia 
                                                                       bo nie mieszka w namespace `ingress-space`

Krok 2:
-------
Deployment (Serce Kontrolera)
To jest najważniejszy moment (ok. 11 minuty filmu). 
Musimy uruchomić Poda z obrazem Nginxa, ale to nie jest zwykły Nginx. 
To specjalny obraz, który potrafi czytać Ingressy.
Musimy mu też przekazać specjalne zmienne środowiskowe (env), o których mowa w filmie, 
            żeby wiedział, jak się nazywa i gdzie żyje.
Stwórz plik:  2-deployment.yaml 

co tu się dzieje?
1. Tworzy Deployment o nazwie `nginx-ingress-controller` w namespace `ingress-space`
2. Używa obrazu `k8s.gcr.io/ingress-nginx/controller:v1.2.1`, który jest specjalnym Nginxem dla Ingressów
3. Przekazuje zmienne środowiskowe, które konfigurują Nginx:
   - `POD_NAME` – nazwa Poda (dynamicznie pobierana)
   - `POD_NAMESPACE` – namespace Poda (dynamicznie pobierana)
4. Ustawia `ServiceAccount` na `ingress-serviceaccount`, żeby Nginx miał odpowiednie uprawnienia
5. Eksponuje porty 80 i 443, które Nginx będzie nasłuchiwać
6. Definiuje strategię aktualizacji i zasoby

Krok 3: 
-------
Serwis (Wystawienie na świat)
Na koniec (ok. 12 minuty), instruktor wyjaśnia, że sam Deployment jest niedostępny z zewnątrz. 
Potrzebujemy Serwisu typu `NodePort`, żeby "otworzyć dziurę" w klastrze.

Stwórz plik: 3-service.yaml

co tu się dzieje?
1. Tworzy Serwis o nazwie `ingress-service` w namespace `ingress-space`
2. Typ Serwisu to `NodePort`, co oznacza, że będzie dostępny na wszystkich węzłach klastra pod losowo wybranymi portami
3. Serwis przekierowuje ruch na port 80 Poda (`nginx-ingress-controller`)
4. Kubernetes automatycznie przypisze porty NodePort (w zakresie 30000-32767) dla portów 80 i 443
5. Definiuje selektor, który łączy Serwis z Podem Nginx
6. Ustawia typ protokołu na TCP


Jednak, przed uruchomieniem i weryfikacją zróbmy porządne sprzątanie:
---------------------------------------------------------------------
Upewnij się, że masz czyste środowisko (jeśli nie posprzątałeś wcześniej):
sprawdź, czy namespace: `ingress-space` istnieje:
# kubectl get namespaces
    NAME              STATUS   AGE
    default           Active   15d
    ingress-space     Active   21h<------------- do usunięcia!

Jeśli tak, usuń go:
Usuwa całą przestrzeń nazw (Pody, Serwisy, Deploymenty)
# kubectl delete namespace ingress-space
    namespace "ingress-space" deleted

Sprawdź, czy istnieją globalne uprawnienia (RBAC):
# kubectl get clusterrolebinding ingress-role-binding
    NAME                   ROLE                       AGE
    ingress-role-binding   ClusterRole/ingress-role   95m

# kubectl get clusterrole ingress-role
    NAME           CREATED AT
    ingress-role   2025-12-08T19:02:15Z

Jeśli tak, usuń je:
Te obiekty nie mieszkają w żadnym namespace, więc nie znikną same:
# kubectl delete clusterrolebinding ingress-role-binding
    clusterrolebinding.rbac.authorization.k8s.io "ingress-role-binding" deleted

# kubectl delete clusterrole ingress-role
    clusterrole.rbac.authorization.k8s.io "ingress-role" deleted

Sprawdź, czy istnieją obiekty w namespace: `ingress-space`:
# kubectl get all -n ingress-space
Jeśli tak, usuń je:
# kubectl delete all --all -n ingress-space

Sprawdź, czy istnieją obiekty RBAC w namespace ingress-space:
# kubectl get rolebinding -n ingress-space
# kubectl get role -n ingress-space
Jeśli tak, usuń je:
# kubectl delete rolebinding <nazwa-rolebinding> -n ingress-space
# kubectl delete role <nazwa-role> -n ingress-space



Teraz masz czyste środowisko do pracy.

Uruchomienie i Weryfikacja:
---------------------------
Teraz możesz to wdrożyć, żeby zobaczyć, jak te komponenty wstają "ręcznie":
# kubectl apply -f 1-prereqs.yaml
    namespace/ingress-space created
    configmap/nginx-configuration created
    serviceaccount/ingress-serviceaccount created
    clusterrole.rbac.authorization.k8s.io/ingress-role created
    clusterrolebinding.rbac.authorization.k8s.io/ingress-role-binding created

# kubectl apply -f 2-deployment.yaml
    deployment.apps/nginx-ingress-controller created

# kubectl apply -f 3-service.yaml
    service/ingress-service created


Sprawdź, co powstało:
# kubectl get all -n ingress-space
    NAME                                            READY   STATUS    RESTARTS   AGE
    pod/nginx-ingress-controller-5b869c5c9c-pcwlt   1/1     Running   0          29s

    NAME                      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-service   NodePort   10.43.253.202   <none>        80:30952/TCP,443:30458/TCP   15s

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-ingress-controller   1/1     1            1           29s

    NAME                                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-ingress-controller-5b869c5c9c   1         1         1       29s


# kubectl get pods -n ingress-space -w  (Flaga -w pozwoli Ci obserwować proces na żywo).
    NAME                                        READY   STATUS    RESTARTS   AGE
    nginx-ingress-controller-5b869c5c9c-pcwlt   1/1     Running   0          79s


-------------------------------- jeśli blad: `ImagePullBackOff` ----------------------------
Jeśli, w powyższym przykładzie widać błąd `ImagePullBackOff`.
Oznacza to, że Kubernetes nie może pobrać obrazu z rejestru.
W filmie instruktor używa obrazu "k8s.gcr.io/ingress-nginx/controller:v1.2.1",
który może być niedostępny w Twoim środowisku.
Aby to naprawić:

# kubectl describe pod -n ingress-space nginx-ingress-controller-5b869c5c9c-pcwlt
[fajne logi z opisu poda]
 


Można to sprawdzić i naprawić! Błąd ImagePullBackOff oznacza, 
       że Kubernetes próbuje pobrać ten konkretny obraz (0.21.0), ale mu się nie udaje.
Dlaczego?
Szkolenie, które oglądasz, ma już kilka lat. W świecie IT to wieczność.
Stary obraz zniknął: Repozytorium quay.io mogło usunąć tak starą wersję.
Niekompatybilność: 
Nawet jakbyś go pobrał, ten stary Nginx (wersja 0.21) nie zadziałałby na Twoim nowym K3s (wersja 1.30+), 
      bo używa starych zapytań do API, które już nie istnieją.
Aby to naprawić i sprawić, by zaświeciło się na zielono (Running), musimy zrobić dwie rzeczy:
Użyć nowszego obrazu (wspieranego przez Google/Kubernetes).
Dodać brakujące uprawnienia (RBAC), o których instruktor nie wspomniał w tej minucie (lub pominął dla uproszczenia), 
       a bez których Nginx i tak by się wyłożył zaraz po pobraniu obrazu.
Przygotowałem dla Ciebie plik naprawczy 4-fix-everything.yaml. 
Zawiera on działający obraz i niezbędne uprawnienia.
Naprawa w jednym kroku
Stwórz w katalogu manual-ingress plik 4-fix-everything.yaml:

Uruchom naprawę
# cd LAB1-FIX
# kubectl apply -f 4-fix-everything.yaml
    deployment.apps/nginx-ingress-controller configured


Weryfikacja
Teraz daj mu chwilę na pobranie nowego obrazu i sprawdź status:
# kubectl get pods -n ingress-space
    NAME                                        READY   STATUS    RESTARTS   AGE
    nginx-ingress-controller-5b869c5c9c-pcwlt   1/1     Running   0          12m

# kubectl get all -n ingress-space
    NAME                                            READY   STATUS    RESTARTS   AGE
    pod/nginx-ingress-controller-5b869c5c9c-pcwlt   1/1     Running   0          12m

    NAME                      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-service   NodePort   10.43.253.202   <none>        80:30952/TCP,443:30458/TCP   12m

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-ingress-controller   1/1     1            1           12m

    NAME                                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-ingress-controller-5b869c5c9c   1         1         1       12m

Powinieneś zobaczyć:
pod/nginx-ingress-controller-... w stanie Running (1/1 READY).




Pełen sukces! 🎯
Twój wynik pokazuje idealny stan zdrowia:
Pod: 1/1 Running – Kontener Nginx działa, nie restartuje się.
Service: NodePort – Jest aktywny i nasłuchuje.
Deployment: 1/1 – Kubernetes utrzymuje wymaganą liczbę kopii.
Co to oznacza w praktyce?
Oznacza to, że zrozumiałeś i ręcznie odtworzyłeś to, co zazwyczaj robią automatyczne instalatory. 
Wiesz już, że `Ingress Controller` to nie "magia", tylko zestaw konkretnych klocków:
1. Pod (z aplikacją Nginx),
2. ServiceAccount + RBAC (uprawnienia do patrzenia na klaster),
3. Service (okno na świat).

Weryfikacja:
------------

sprawdź, jakie porty NodePort zostały przypisane:
# kubectl get service ingress-service -n ingress-space
    NAME              TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    ingress-service   NodePort   10.43.197.25   <none>        80:32533/TCP,443:32205/TCP   88s

Zauważ, że w kolumnie PORT(S) widzisz coś takiego: 80:32533/TCP,443:32205/TCP
Oznacza to, że port 80 Poda Nginx jest dostępny na wszystkich węzłach klastra pod portem 32533.
Podobnie, port 443 jest dostępny pod portem 32205.
Możesz teraz przetestować Ingress, wysyłając żądania HTTP do dowolnego węzła klastra
na przypisanym porcie NodePort (np. 32533 dla HTTP).
jak to zrobić, użyj narzędzia curl lub przeglądarki internetowej.
#  www.my-online-store.com/wear
#  www.my-online-store.com/watch
 

Co robimy dalej?
Ponieważ ten "manualny" `Ingress Controller` był tylko ćwiczeniem edukacyjnym i działa w osobnej przestrzeni nazw 
(namespace: `ingress-space`), proponuję go teraz posprzątać.
i przejść do następnego laboratorium, gdzie zainstalujemy `NGINX Ingress Controller` z serwisem `LoadBalancer`.
# cd ../LAB2-manual-ingress-as-LB

 

