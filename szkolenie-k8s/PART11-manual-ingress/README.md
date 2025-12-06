Ingress Controler om NGINX
--------------------------
To ćwiczenie pokazuje, jak zbudować Ingress Controller od zera, tworząc ręcznie wszystkie wymagane obiekty Kubernetes.
Stwórzmy nowy katalog, żeby nie pomieszać tego z poprzednimi ćwiczeniami

Krok 1: Konfiguracja i Uprawnienia (ConfigMap, ServiceAccount)
Wideo wyjaśnia, że Nginx potrzebuje miejsca na konfigurację (ConfigMap) 
oraz uprawnień do "patrzenia" na klaster (ServiceAccount). 
Dodatkowo musimy stworzyć Namespace, żeby trzymać tam porządek.

Stwórz plik: 1-prereqs.yaml 


Krok 2: Deployment (Serce Kontrolera)
To jest najważniejszy moment (ok. 11 minuty filmu). 
Musimy uruchomić Poda z obrazem Nginxa, ale to nie jest zwykły Nginx. 
To specjalny obraz, który potrafi czytać Ingressy.
Musimy mu też przekazać specjalne zmienne środowiskowe (env), o których mowa w filmie, 
            żeby wiedział, jak się nazywa i gdzie żyje.
Stwórz plik:  2-deployment.yaml 


Krok 3: Serwis (Wystawienie na świat)
Na koniec (ok. 12 minuty), instruktor wyjaśnia, że sam Deployment jest niedostępny z zewnątrz. 
Potrzebujemy Serwisu typu NodePort, żeby "otworzyć dziurę" w klastrze.
Stwórz plik: 3-service.yaml 


Uruchomienie i Weryfikacja
Teraz możesz to wdrożyć, żeby zobaczyć, jak te komponenty wstają "ręcznie":
# kubectl apply -f 1-prereqs.yaml
    configmap/nginx-configuration created
    serviceaccount/ingress-serviceaccount created

# kubectl apply -f 2-deployment.yaml
    deployment.apps/nginx-ingress-controller created

# kubectl apply -f 3-service.yaml
    service/ingress-service created


Sprawdź, co powstało:
# kubectl get all -n ingress-space
    NAME                                            READY   STATUS             RESTARTS   AGE
    pod/nginx-ingress-controller-6bff97ddbb-c6pgw   0/1     ImagePullBackOff   0          55s

    NAME                      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-service   NodePort   10.43.146.49   <none>        80:30315/TCP,443:30992/TCP   36s

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-ingress-controller   0/1     1            0           55s

    NAME                                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-ingress-controller-6bff97ddbb   1         1         0       55s





-------------------------------- blad ----------------------------
W powyższym przykładzie widać błąd ImagePullBackOff.
Oznacza to, że Kubernetes nie może pobrać obrazu z rejestru.
W filmie instruktor używa obrazu "k8s.gcr.io/ingress-nginx/controller:v1.2.1",
który może być niedostępny w Twoim środowisku.
Aby to naprawić:

Można to sprawdzić i naprawić! Błąd ImagePullBackOff oznacza, że Kubernetes próbuje pobrać ten konkretny obraz (0.21.0), ale mu się nie udaje.
Dlaczego?
Szkolenie, które oglądasz, ma już kilka lat. W świecie IT to wieczność.
Stary obraz zniknął: Repozytorium quay.io mogło usunąć tak starą wersję.
Niekompatybilność: Nawet jakbyś go pobrał, ten stary Nginx (wersja 0.21) nie zadziałałby na Twoim nowym K3s (wersja 1.30+), bo używa starych zapytań do API, które już nie istnieją.
Aby to naprawić i sprawić, by zaświeciło się na zielono (Running), musimy zrobić dwie rzeczy:
Użyć nowszego obrazu (wspieranego przez Google/Kubernetes).
Dodać brakujące uprawnienia (RBAC), o których instruktor nie wspomniał w tej minucie (lub pominął dla uproszczenia), a bez których Nginx i tak by się wyłożył zaraz po pobraniu obrazu.
Przygotowałem dla Ciebie plik naprawczy 4-fix-everything.yaml. Zawiera on działający obraz i niezbędne uprawnienia.
Naprawa w jednym kroku
Stwórz w katalogu manual-ingress plik 4-fix-everything.yaml:

Uruchom naprawę
# cd LAB2-FIX
# kubectl apply -f 4-fix-everything.yaml
    deployment.apps/nginx-ingress-controller configured




Weryfikacja
Teraz daj mu chwilę na pobranie nowego obrazu i sprawdź status:
# kubectl get pods -n ingress-space
    NAME                                       READY   STATUS    RESTARTS   AGE
    nginx-ingress-controller-cd7685684-gvgqr   1/1     Running   0          14m

# kubectl get all -n ingress-space
    NAME                                           READY   STATUS    RESTARTS   AGE
    pod/nginx-ingress-controller-cd7685684-gvgqr   1/1     Running   0          14m

    NAME                      TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-service   NodePort   10.43.146.49   <none>        80:30315/TCP,443:30992/TCP   23m

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-ingress-controller   1/1     1            1           23m

    NAME                                                  DESIRED   CURRENT   READY   AGE
    replicaset.apps/nginx-ingress-controller-6bff97ddbb   0         0         0       23m
    replicaset.apps/nginx-ingress-controller-cd7685684    1         1         1       14m

Powinieneś zobaczyć:
pod/nginx-ingress-controller-... w stanie Running (1/1 READY).




Pełen sukces! 🎯
Twój wynik pokazuje idealny stan zdrowia:
Pod: 1/1 Running – Kontener Nginx działa, nie restartuje się.
Service: NodePort – Jest aktywny i nasłuchuje.
Deployment: 1/1 – Kubernetes utrzymuje wymaganą liczbę kopii.
Co to oznacza w praktyce?
Oznacza to, że zrozumiałeś i ręcznie odtworzyłeś to, co zazwyczaj robią automatyczne instalatory. Wiesz już, że Ingress Controller to nie "magia", tylko zestaw konkretnych klocków:
Pod (z aplikacją Nginx),
ServiceAccount + RBAC (uprawnienia do patrzenia na klaster),
Service (okno na świat).
Co robimy dalej?
Ponieważ ten "manualny" Ingress Controller był tylko ćwiczeniem edukacyjnym i działa w osobnej przestrzeni nazw (ingress-space), proponuję go teraz posprzątać.



sprzzątanie:
1. Usuń całą przestrzeń nazw (Pody, Serwisy, Deploymenty)
# kubectl delete namespace ingress-space
 
2. Usuń globalne uprawnienia (RBAC)
   Te obiekty nie mieszkają w żadnym namespace, więc nie znikną same:
# kubectl delete clusterrolebinding ingress-role-binding
# kubectl delete clusterrole ingress-role



