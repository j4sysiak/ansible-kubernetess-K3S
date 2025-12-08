szkolenia prowadzonego przez Mumshada Mannambetha (z kursu KodeKloud).
https://www.youtube.com/watch?v=GhZi4DxaxxE&t=95s
od 10 min.
--------------------------------------------------
Ingress Controler on NGINX  z serwisem LadBalancer
---------------------------------------------------------------------------------------
czyli opowieść, z jakich "części" składa się recepcjonista (Pod + Service + ConfigMap).
---------------------------------------------------------------------------------------


Chodzi o to, że w tej chwili w Twoim jednym małym klastrze (kontenerze Dockera) działają 
                    dwa konkurencyjne systemy robiące dokładnie to samo.

Wyobraź to sobie na przykładzie biurowca:
Główny Recepcjonista (Ten z Helma/K3s):
Zainstalowaliśmy go wcześniej (albo był wbudowany w K3s).
Siedzi przy Głównym Wejściu (Port 80).
To dzięki niemu działały strony http://localhost/apple i banana.
To jest ten "produkcyjny", którego chcemy używać.

Tymczasowy Recepcjonista (Ten z ćwiczenia YT LAB1-manual-ingress):
Stworzyliśmy go przed chwilą ręcznie w namespace `ingress-space`.
Siedzi przy Tylnym Wejściu (działa na typie NodePort, czyli jakimś losowym porcie np. 30315, a nie na głównym 80).
Stworzyliśmy go tylko po to, żebyś zobaczył, z jakich "części" składa się recepcjonista (Pod + Service + ConfigMap).
Dlaczego sugeruję go usunąć?
Marnowanie Zasobów (RAM/CPU):
Twój kontener Dockera ma ograniczone zasoby. Utrzymywanie drugiego, nieużywanego Nginxa zabiera pamięć, 
    którą moglibyśmy przeznaczyć na bazę danych lub inne aplikacje w kolejnych lekcjach.
Zamieszanie w Routingu (Konflikty):
Gdy stworzysz teraz nowy plik Ingress (regułę), może dojść do sytuacji, 
                       w której obaj recepcjoniści rzucą się do obsługi tego zadania.
Jeśli zapomnisz dodać ingressClassName: nginx (lub ustawisz złą klasę), Twój "Tymczasowy" Ingress 
      może próbować przejąć ruch, ale ponieważ siedzi na "tylnym wejściu" (innym porcie), w przeglądarce nic nie zadziała. 
To prowadzi do trudnych do wykrycia błędów typu: "Wszystko wgrałem dobrze, a strona nie działa".

------------------------- moje pytanie -------------------------------------
ale jednak. a nie możemy uzywać tego kontrolera zamiast tego z Helma ?
----------------------------------------------------------------------------
Oczywiście, że możemy!
Jeśli chcesz używać tego ręcznie stworzonego `Ingress Controllera` zamiast tego z Helma/K3s, 
                   to jak najbardziej możesz to zrobić.
Musisz jednak pamiętać o kilku rzeczach:
1. Usunięcie Helm Nginx Ingress Controllera:
Musisz usunąć ten zainstalowany przez Helma, aby uniknąć konfliktów.
Możesz to zrobić za pomocą polecenia Helm uninstall.
2. Ustawienie IngressClass:
Upewnij się, że wszystkie Twoje zasoby Ingress mają ustawioną właściwość ingressClassName na nginx
                                         (lub inną nazwę, którą nadałeś swojemu Ingress Controllerowi).
3. Monitorowanie:
Regularnie sprawdzaj, czy Twój ręcznie zainstalowany Ingress Controller działa poprawnie i czy nie ma konfliktów z innymi zasobami w klastrze.
Podsumowując, tak, możesz używać ręcznie zainstalowanego Ingress Controllera zamiast tego z Helma/K3s, ale musisz być świadomy potencjalnych konfliktów i zarządzać nimi odpowiednio.
-------------------------
Jednak, jest to trochę jak wybór między samochodem, który zbudowałeś sam w garażu, a samochodem z salonu.
Oto różnice i konsekwencje takiej decyzji:
1. Twój Ręczny Kontroler (Samoróbka)
   Zaleta: Wiesz o nim wszystko, bo sam wpisałeś każdą linijkę YAML. Pełna kontrola.
   Wada: Jest bardzo "goły".
   Nie ma skonfigurowanych metryk (Prometheus).
   Nie ma automatycznego skalowania (HPA).
   Używa typu NodePort (dziwne porty typu 30xxx), więc nie działa na porcie 80 (musiałbyś to zmienić ręcznie).
   Musisz ręcznie pilnować aktualizacji wersji w plikach YAML.
2. Kontroler z Helma (Ten "główny")
   Zaleta: To standard produkcyjny.
   Ma wbudowane najlepsze praktyki bezpieczeństwa.
   Automatycznie integruje się z monitoringiem.
   Jest skonfigurowany jako LoadBalancer (działa od razu na porcie 80).
   Łatwo się aktualizuje jedną komendą (helm upgrade).

Decyzja: Czy warto zamieniać?
Do celów edukacyjnych – jak najbardziej, to świetne ćwiczenie! Jeśli chcesz, żeby Twój ręczny kontroler 
                        stał się tym "Głównym", musimy go trochę "podrasować", żeby przejął ruch na porcie 80.
Jeśli chcesz to zrobić, oto instrukcja ("Upgrade z garażu na salon"):
Musimy wykonać 3 kroki:
1. Usunąć konkurencję (Ten kontroler z Helma/K3s).
2. Przerobić Twój serwis z NodePort na LoadBalancer (żeby zajął port 80).
3. Zdefiniować klasę Ingress, żeby system wiedział, że to on rządzi.
4. 
Chcesz spróbować? Jeśli tak, wykonaj poniższe kroki. 
Jeśli wolisz spokój i stabilność do kolejnych lekcji, zostaw tak jak jest (czyli usuń manualny).

-------------------------
PLAN: Awansujemy Ręczny Kontroler na Szefa
Zakładam, że nie usunąłeś jeszcze namespace: `ingress-space`.

Krok 1: 
Pozbywamy się konkurencji
Musimy zwolnić port 80. 
Jeśli masz zainstalowany ingress przez Helm (w namespace `ingress-nginx` lub `default`), usuń go.
# kubectl get pods -n ingress-space
    NAME                                        READY   STATUS    RESTARTS   AGE
    nginx-ingress-controller-5b869c5c9c-dbgcf   1/1     Running   0          67m


Musisz usunąć stary `Ingress Controller`, który zainstalowaliśmy wcześniej (prawdopodobnie przez Helm). 
On teraz "okupuje" port 80 jako LoadBalancer.
Oto jak to zrobić krok po kroku, bezpiecznie i czysto:

Krok 1: 
Sprawdź, co dokładnie blokuje port
Wpisz tę komendę, aby zobaczyć wszystkie serwisy typu LoadBalancer w całym klastrze:
Sprawdź, czy coś innego działa jako LoadBalancer
# kubectl get svc -A | grep LoadBalancer
    ingress-nginx   ingress-nginx-controller  LoadBalancer   10.43.81.211    172.17.0.2    80:31896/TCP,443:32006/TCP     14d

To nam mówi dwie rzeczy:
Nazwa serwisu (np. `ingress-nginx-controller`).
Namespace (przestrzeń nazw), w której siedzi (np. `ingress-nginx` lub `default`).

Metoda B: "Opcja Nuklearna" (Najszybsza)
Jeśli `Ingress Controller` siedzi w swoim własnym namespace (zazwyczaj `ingress-nginx`), 
       możesz po prostu usunąć cały ten namespace. 
Kubernetes posprząta wszystko, co w nim jest.
# kubectl delete namespace ingress-space
    namespace "ingress-space" deleted

Metoda A: "Opcja Precyzyjna" (Jeśli nie chcesz usuwać całego namespace)
Jeśli chcesz być bardziej precyzyjny i usunąć tylko ten konkretny `Ingress Controller`, wykonaj te kroki:
Znajdź namespace, w którym siedzi `Ingress Controller` (np. `ingress-nginx`).
Przełącz się na ten namespace:
# kubectl config set-context --current --namespace=ingress-nginx
Usuń ten serwis LoadBalancer i deployment (jeśli istnieje)
# kubectl delete svc ingress-nginx-controller -n ingress-nginx
    service "ingress-nginx-controller" deleted from ingress-nginx namespace
# kubectl delete deployment nginx-ingress-controller -n ingress-nginx

Metoda A: Przez Helm (Najczystsza)
Jeśli instalowaliśmy to przez Helm (a tak robiliśmy w roli Ansible), najlepiej odinstalować to też Helmem.
Zobacz listę zainstalowanych pakietów Helm:
# helm list -A
    NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
    ingress-nginx   ingress-nginx   1               2025-12-07 19:21:21.893689319 +0100 CET deployed        ingress-nginx-4.14.1    1.14.1

Szukaj czegoś o nazwie `ingress-nginx` lub podobnej.
Odinstaluj to (podstaw odpowiednią nazwę i namespace z listy wyżej):
(Jeśli nazwa pakietu to np. my-ingress, wpisz my-ingress. Jeśli namespace to default, wpisz -n default).
# helm uninstall ingress-nginx -n ingress-nginx
    release "ingress-nginx" uninstalled

potwierdzamy, że nie ma już LoadBalancerów i nie ma już konkurencji nic nie nasluchuje na porcie 80
# kubectl get svc -A | grep LoadBalancer
-> pusto

Krok 2: 
Przerabiamy Twój Serwis na LoadBalancer
Twój ręczny serwis (3-service.yaml) był typu NodePort. 
Zmieńmy go, żeby był bramą na świat.
Edytuj plik 3-service.yaml (w katalogu manual-ingress):


# cd szkolenie-k8s/PART11-manual-ingress/LAB2-manual-ingress-as-LB
Uruchomienie i Weryfikacja
Teraz możesz to wdrożyć, żeby zobaczyć, jak te komponenty wstają "ręcznie":
# kubectl apply -f 1-prereqs.yaml
    namespace/ingress-space created
    configmap/nginx-configuration created
    serviceaccount/ingress-serviceaccount created
    clusterrole.rbac.authorization.k8s.io/ingress-role unchanged
    clusterrolebinding.rbac.authorization.k8s.io/ingress-role-binding unchanged

# kubectl apply -f 2-deployment.yaml
    deployment.apps/nginx-ingress-controller created

# kubectl apply -f 3-service.yaml
    service/ingress-service created

Sprawdź, czy dostał adres IP (powinien dostać 172.17.0.2):
# kubectl get svc -n ingress-space
    NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    ingress-service   LoadBalancer   10.43.161.145   172.17.0.2    80:31421/TCP,443:30382/TCP   16s


Sprawdź, co powstało:
# kubectl get all -n ingress-space
    NAME                                            READY   STATUS    RESTARTS   AGE
    pod/nginx-ingress-controller-5b869c5c9c-dbgcf   1/1     Running   0          72s

    NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    service/ingress-service   LoadBalancer   10.43.161.145   172.17.0.2    80:31421/TCP,443:30382/TCP   58s

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/nginx-ingress-controller   1/1     1            1           72s

    NAME                                                  DESIRED   CURRENT   READY   AGE
    .apps/nginx-ingress-controller-5b869c5c9c   1         1         1       72s


# kubectl get pods -n ingress-space -w  (Flaga -w pozwoli Ci obserwować proces na żywo).


Krok 3: 
Konfiguracja IngressClass
Żeby Twoje Ingressy (np. sklep.local) wiedziały, że mają używać TEGO kontrolera, musimy stworzyć obiekt IngressClass.
Stwórz plik:  4-ingress-class.yaml 

Zastosuj:
# kubectl apply -f 4-ingress-class.yaml
    ingressclass.networking.k8s.io/nginx-manual created

Sprawdź, czy powstał:
# kubectl get ingressclass
    NAME           CONTROLLER             PARAMETERS   AGE
    nginx          k8s.io/ingress-nginx   <none>       14d
    nginx-manual   k8s.io/ingress-nginx   <none>       21s  


Weryfikacja
-----------
Teraz Twój ręczny kontroler powinien obsługiwać cały ruch.
przekopiujny 2 pliki:
 - szkolenie-k8s/PART10-Online-store/1-app.yaml    ---------> i move to: `app.yaml`
 - szkolenie-k8s/PART10-Online-store/2-ingress.yaml  -------> i move to: `ingress.yaml`

 
Ustaw w: ingress.yaml
ingressClassName: `nginx-manual`
(Bo tak nazwaliśmy naszą klasę w deploymentcie i w pliku class.yaml).
Wejdź na http://www.my-online-store.com/wear


-----------------------------------------------------------------------------------------------
Uważaj na namespace!
Moga być problemy z namespace, bo w plikach app.yaml i ingress.yaml nie bylo  określonego namespace -
                                                                               - teraz juz wpisalem `default`.
Domyślnie, jeśli nie podasz `-n default` w komendzie tworzącej Deployment, kubectl będzie działać w namespace `default`.
Więc albo dopisuj `-n default` do każdej komendy deploymentu pliku app.yaml i ingress.yaml.
Albo zmień domyślny kontekst globalnie (patrz niżej).

# kubectl get ingress -n default
    NAME                 CLASS   HOSTS                     ADDRESS      PORTS     AGE
    ingress-wear-watch   nginx   www.my-online-store.com   172.17.0.2   80        21h
# kubectl delete ingress ingress-wear-watch -n default
    ingress.networking.k8s.io "ingress-wear-watch" deleted from default namespace

Zmiana domyślnego kontekstu (Najwygodniejszy)
Jeśli nie chcesz ciągle dopisywać `-n default`, możesz po prostu przestawić swoją konsolę tak, 
                                                                        żeby domyślnie pracowała w default.
1. Przestaw konsolę:
# kubectl config set-context --current --namespace=default
    Context "default" modified.

2. Sprawdź, gdzie jesteś:
# kubectl get pods
    NAME                                READY   STATUS             RESTARTS          AGE
    [...]
    video-deployment-79df85996d-c928j   1/1     Running            0                 22h
    wear-deployment-68999fc75c-pmn6j    1/1     Running            0                 22h

Zastosuj:
# kubectl apply -f apps.yaml    (lub ze wskazaniem namespace = default:  `kubectl apply -f apps.yaml -n default`)
    deployment.apps/wear-deployment created
    service/wear-service created
    deployment.apps/video-deployment created
    service/video-service created

 
Zastosuj:
# kubectl apply -f ingress.yaml     (lub ze wskazaniem namespace = default:  `kubectl apply -f ingress.yaml -n default`)
    ingress.networking.k8s.io/ingress-wear-watch created

# kubectl get ingress -A
        NAMESPACE   NAME                 CLASS          HOSTS                     ADDRESS      PORTS     AGE
        default     admin-ingress        nginx          admin.local               172.17.0.2   80, 443   2d19h
    --->default     ingress-wear-watch   nginx-manual   www.my-online-store.com   172.17.0.2   80        3m5s
        default     owocowy-ingress      nginx          *                         172.17.0.2   80        11d
        default     secure-ingress       nginx          secure.local              172.17.0.2   80, 443   2d20h
        default     sni-ingress          nginx          bank.local,sklep.local    172.17.0.2   80, 443   2d19h
 

ale tak naprawde i najlepiej, to zmodyfikuj pliki: `app.yaml` i `ingress.yaml` i dodaj w nich namespace: `default`


Krok 3: 
Konfiguracja DNS (Windows)
W szkoleniu mowa jest o konfiguracji DNS.
Ponieważ nie mamy prawdziwej domeny, musimy "oszukać" Twój komputer.
Uruchom Notatnik jako Administrator.
Otwórz C:\Windows\System32\drivers\etc\hosts.
Dodaj linię (lub zaktualizuj istniejącą):
  `127.0.0.1 www.my-online-store.com`
(Używamy 127.0.0.1, bo Docker mapuje port 80).
 

Wielki Test (Sprawdzenie Wiedzy)
Teraz sprawdźmy, czy zadziałało to tak, jak na filmie.
Otwórz przeglądarkę.

Wejdź na: http://www.my-online-store.com/wear
Oczekiwany wynik: Komunikat o koszulkach (Wear App).

Wejdź na: http://www.my-online-store.com/watch
Oczekiwany wynik: Komunikat o wideo (Video App).

Wejdź na: http://www.my-online-store.com (bez ścieżki)
Oczekiwany wynik: Błąd 404 Not Found (nginx).


Jeśli działa – Gratulacje!
Właśnie własnoręcznie zbudowałeś i skonfigurowałeś główny router dla całego klastra, zastępując gotowca.
To jest poziom "Hard".


------------------------  sprzątanie ------------------------------ 
Wykonaj te komendy, aby usunąć całe to laboratorium:
Upewnij się, że masz czyste środowisko (jeśli nie posprzątałeś wcześniej):
sprawdź, czy namespace: `ingress-space` istnieje:
# kubectl get namespaces
        NAME              STATUS   AGE
        cert-manager      Active   23h
        default           Active   16d
        ingress-nginx     Active   25h
    --->ingress-space     Active   50m<------------------
        kube-node-lease   Active   16d
        kube-public       Active   16d
        kube-system       Active   16d
        monitoring        Active   16d
 
Jeśli tak, usuń go:
Usuwa całą przestrzeń nazw (Pody, Serwisy, Deploymenty)
# kubectl delete namespace ingress-space

Sprawdź, czy istnieją globalne uprawnienia (RBAC):
# kubectl get clusterrolebinding ingress-role-binding
# kubectl get clusterrole ingress-role
Jeśli tak, usuń je:
Te obiekty nie mieszkają w żadnym namespace, więc nie znikną same:
# kubectl delete clusterrolebinding ingress-role-binding
# kubectl delete clusterrole ingress-role

Sprawdź, czy istnieją obiekty w namespace ingress-space:
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
nie ma już namespace `ingress-space`
# kubectl get ingress -A
    NAMESPACE   NAME                 CLASS          HOSTS                     ADDRESS      PORTS     AGE
    default     admin-ingress        nginx          admin.local               172.17.0.2   80, 443   2d19h
    default     ingress-wear-watch   nginx-manual   www.my-online-store.com   172.17.0.2   80        27m
    default     owocowy-ingress      nginx          *                         172.17.0.2   80        11d
    default     secure-ingress       nginx          secure.local              172.17.0.2   80, 443   2d20h
    default     sni-ingress          nginx          bank.local,sklep.local    172.17.0.2   80, 443   2d20h

nie ma już namespace: `ingress-space`
# kubectl get namespaces
    NAME              STATUS   AGE
    cert-manager      Active   23h
    default           Active   16d
    ingress-nginx     Active   25h
    kube-node-lease   Active   16d
    kube-public       Active   16d
    kube-system       Active   16d
    monitoring        Active   16d