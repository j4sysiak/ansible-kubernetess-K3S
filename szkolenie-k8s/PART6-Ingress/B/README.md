Skupimy się na 3 aspektach.
1. Virtual Hosting (Host-based routing): Jak mieć sklep.pl i blog.pl na tym samym adresie IP?
2. TLS/SSL Termination: Jak włączyć kłódkę (HTTPS)?
3. Architektura: Jak to działa pod maską (Layer 7 vs Layer 4).
Przygotowałem  "Ingress Masterclass".

"Czym się różni Ingress od LoadBalancera?"
 
LoadBalancer (Warstwa 4 - TCP): 
Działa jak "głupi" ruter. 
Widzi tylko adresy IP i porty. 
Dla każdej usługi potrzebujesz osobnego publicznego IP (co w chmurze kosztuje $).

Ingress (Warstwa 7 - HTTP/HTTPS): 
Działa jak "inteligentny" ruter. 
Zagłada do środka pakietu HTTP. 
Widzi adres URL (sklep.pl) i ścieżkę (/koszyk).

Zaleta: 
Możemy wystawić tysiące usług na JEDNYM publicznym adresie IP, rozróżniając je po domenach.

------------------------------------------------------------------------------------------------------

Praktyka - Virtual Hosting (Blue vs Green)
Zrobimy klasyczny scenariusz. 
Masz dwie domeny:
  - blue.local
  - green.local

Obie mają kierować do tego samego klastra, ale do innych aplikacji.

1. Przygotowanie "oszukanego" DNS
Musimy powiedzieć Twojemu Windowsowi, że te domeny istnieją.
Otwórz notatnik jako Administrator.
Edytuj C:\Windows\System32\drivers\etc\hosts.
Dodaj linię (to jest IP Twojego kontenera, sprawdź 172.17... jeśli się zmienił):

        127.0.0.1 blue.local green.local
 
Stwórz plik colors-app.yaml z dwoma aplikacjami i dwoma serwisami: colors-app.yaml
Wdróż to: 
# kubectl apply -f colors-app.yaml
    deployment.apps/blue-app created
    service/blue-svc created
    deployment.apps/green-app created
    service/green-svc created

Sprawdź, czy działa: 
# kubectl get pods
    NAME                               READY   STATUS             RESTARTS        AGE
    blue-app-5c9574cd5d-x97r5          1/1     Running            0               33s
    green-app-8c58774d8-sq67k          1/1     Running            0               33s

# kubectl get svc
    NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
    blue-svc                         ClusterIP   10.43.118.184   <none>        80/TCP         77s
    green-svc                        ClusterIP   10.43.162.53    <none>        80/TCP         77s



2. Ingress z Virtual Hostingiem
Teraz najważniejszy plik. 
Stwórz:  ingress-hosts.yaml

Usuń stare Ingressy (jeśli istnieją):
# kubectl delete ingress owocowy-ingress
# kubectl delete ingress produkcja-ingress
Usuń też stary, jeśli istnieje
# kubectl delete ingress color-ingress

Wdróż to: 
# kubectl apply -f ingress-hosts.yaml
    ingress.networking.k8s.io/color-ingress created
Sprawdź Ingress:
# kubectl get ingress
    NAME            CLASS   HOSTS                    ADDRESS      PORTS   AGE
    color-ingress   nginx   blue.local,green.local   172.17.0.2   80      5m11s

-------------------------   uderzenie bezpośrednio w IP Ingressa   ----------------------------
W skrócie:
W Twoim środowisku (Windows + Docker Desktop) bezpośredni adres IP kontenera (172.17.0.2) jest nieosiągalny z poziomu WSL.
To jest specyfika działania Docker Desktop na Windowsie. 
Docker działa w jednej wirtualnej maszynie, a Twoje Ubuntu (WSL) w drugiej. 
Domyślnie nie ma między nimi "kabla", który pozwalałby na ruch do prywatnych adresów IP kontenerów (172.x.x.x). 
Docker Desktop "wystawia" usługi tylko przez localhost (Port Forwarding).
Dowód (Test wewnątrz)
Żebyś miał 100% pewności, że Ingress i adres IP działają poprawnie, wejdźmy do kontenera i tam wykonajmy to polecenie (bo tam sieć lokalna działa):

# docker exec -it k3s-master curl -H "Host: blue.local" http://172.17.0.2
    JESTEM NIEBIESKI
# docker exec -it k3s-master curl -H "Host: green.local" http://172.17.0.2
    JESTEM ZIELONY
Wyjaśnienie:
Tutaj wszystko działa, bo jesteśmy "wewnątrz" tej samej sieci co Ingress Controller.
Dowód (Test z WSL Ubuntu)
Teraz spróbujmy to samo z WSL Ubuntu (Twojego terminala):
# curl -H "Host: blue.local" http:// http://172.17.0.2
    curl: (3) URL rejected: No host part in the URL
    curl: (7) Failed to connect to 172.17.0.2 port 80 after 2848 ms: Couldn't connect to server

Wyjaśnienie:
------------
Skoro Twój Ingress ma adres `IP: 172.17.0.2`, to oznacza, że nasłuchuje on na tym adresie wewnątrz sieci Dockera.
Ale ja chcę uderzyć bezpośrednio w adres IP kontenera  `172.17.0.2`, pomijając localhost. 
To jest bardzo "czyste" podejście sieciowe.
Skoro Twój Ingress Controller nasłuchuje na adresie `172.17.0.2` i obsługuje wirtualne hosty (blue.local), 
 musisz w zapytaniu curl zrobić dwie rzeczy:
Połączyć się z `IP: 172.17.0.2`
Przedstawić się (w nagłówku HTTP) jako np: `blue.local`

# docker exec -it k3s-master curl -H "Host: blue.local" http://172.17.0.2
    JESTEM NIEBIESKI
 
Wyjaśnienie części w curl:
--------------------------
http://172.17.0.2: To mówi curlowi: "Wyślij pakiet TCP na ten konkretny adres IP".
-H "Host: blue.local": To mówi Ingressowi: "Wiem, że przyszedłem na adres IP, 
            ale poproszę o stronę blue.local". 
Bez tego Ingress nie wiedziałby, czy chcesz blue czy green.


--------------------------  uderzenie przez localhost (mapowanie portów)  ----------------------------
# curl -H "Host: blue.local" http://localhost
    JESTEM NIEBIESKI
# curl -H "Host: green.local" http://localhost
    JESTEM ZIELONY
Skoro masz Docker Desktop z mapowaniem portów -p 80:80, Twój Windows widzi ten klaster jako localhost
(Wcześniej sugerowałem IP kontenera: 172.17.0.2 ,
ale przy mapowaniu -p 80:80 bezpieczniej i stabilniej jest użyć 127.0.0.1).
Jak to działa pod maską?
1. Wysyłasz pakiet na localhost (Twój komputer).
2. Docker przechwytuje pakiet i mówi: "Aha, to na port 80, przerzucam do kontenera 172.17.0.2".
3. Ingress odbiera pakiet. Widzi w środku napis Host: blue.local.
4. Ingress nie patrzy na to, że pakiet przyszedł przez localhost. Patrzy na nagłówek i kieruje do aplikacji Blue.


(mając wpisane w c:\Windows\System32\drivers\etc\hosts: `127.0.0.1 blue.local` oraz  ` 127.0.0.1 green.local`):
Testowanie:
   Otwórz przeglądarkę:
   http://blue.local -> Powinieneś zobaczyć "JESTEM NIEBIESKI"
   http://green.local -> Powinieneś zobaczyć "JESTEM ZIELONY"

$ curl -H "Host: blue.local" http://localhost
    JESTEM NIEBIESKI

$ curl -H "Host: green.local" http://localhost
    JESTEM ZIELONY

Co powiedzieć szefowi: 
"Zobacz szefie, jeden klaster, jeden adres IP, a obsłużyłem dwie różne 'domeny'. 
Ingress Controller patrzy na nagłówek 'Host' w zapytaniu HTTP i na tej podstawie kieruje ruch."


Oznacza to, że Twój komputer (Windows) poprawnie "rozmawia" z Dockerem, 
 Docker przekazuje ruch do K3s, a Ingress Controller (Nginx) poprawnie czyta nagłówki i kieruje ruch 
      do odpowiednich aplikacji. 
          To jest dokładnie tak, jak działa routing w profesjonalnych systemach produkcyjnych.


------------------------------------------------------------------------------------------------------
Praktyka - TLS/SSL Termination (HTTPS)
Teraz dodamy HTTPS do naszego Ingressu.
1. Tworzenie certyfikatu TLS
Dla testów lokalnych użyjemy self-signed certyfikatu.
Wygeneruj certyfikat i klucz:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=blue.local/O=MyOrg"   
Stwórz sekret TLS w Kubernetes:
# kubectl create secret tls tls-secret --key tls.key --cert tls.crt
    secret/tls-secret created
Sprawdź sekret: 
# kubectl get secret tls-secret
    NAME         TYPE                DATA   AGE
    tls-secret   kubernetes.io/tls   2      1m
2. Modyfikacja Ingress do obsługi TLS
Edytuj plik ingress-hosts.yaml, dodając sekcję tls: 
3. Wdróż zmiany:
# kubectl apply -f ingress-hosts.yaml
    ingress.networking.k8s.io/color-ingress configured
Sprawdź Ingress:
# kubectl get ingress
    NAME            CLASS   HOSTS                    ADDRESS      PORTS                     AGE
    color-ingress   nginx   blue.local,green.local   172.17.0.
2   80, 443                  10m
Testowanie HTTPS:
   Otwórz przeglądarkę:
   https://blue.local -> Powinieneś zobaczyć "JESTEM NIEBIESKI" z ostrzeżeniem o certyfikacie (bo jest self-signed)
   https://green.local -> Powinieneś zobaczyć "JESTEM ZIELONY" z ostrzeżeniem o certyfikacie
$ curl -k -H "Host: blue.local" https://localhost
    JESTEM NIEBIESKI
$ curl -k -H "Host: green.local" https://localhost
    JESTEM ZIELONY
Co powiedzieć szefowi: 
"Szefie, teraz nasze usługi są dostępne przez HTTPS.
Ingress Controller obsługuje terminację TLS, więc ruch jest szyfrowany do Ingressa, a potem przekazywany do usług w klastrze."  

------------------------------------------------------------------------------------------------------
Podsumowanie
Teraz wiesz, jak używać Ingress do:
1. Virtual Hosting: Obsługa wielu domen na jednym adresie IP.
2. TLS/SSL Termination: Włączanie HTTPS dla Twoich usług.
Ingress to potężne narzędzie do zarządzania ruchem w klastrze Kubernetes.
