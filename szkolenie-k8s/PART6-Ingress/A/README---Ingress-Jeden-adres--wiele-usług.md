Lab 9: Ingress (Jeden adres, wiele usług)
-------------------------------------------------------
Scenariusz: 
Masz wiele usług (Service) w klastrze, ale chcesz mieć jeden punkt wejścia (adres IP)
         i kierować ruch do różnych usług na podstawie ścieżki URL.

Rozwiązanie: 
Ingress - komponent Kubernetes, który zarządza dostępem zewnętrznym do usług w klastrze, zazwyczaj HTTP.


Scenariusz: 
Masz dwie aplikacje: sklep i blog. 
Chcesz, żeby były dostępne pod jednym adresem IP (port 80), ale pod różnymi ścieżkami: localhost/sklep i localhost/blog.
K3s ma wbudowany kontroler Ingress (Traefik), więc to zadziała "z pudełka".

1. Uruchom dwie proste aplikacje (tzw. backendy):

Stwórz plik:  apple.yaml
Stwórz plik:  banana.yaml

Wdróż obie aplikacje:

# kubectl apply -f apple.yaml
    deployment.apps/apple created

Sprawdź, czy działa aplikacja apple:
# kubectl get deployment apple
    NAME    READY   UP-TO-DATE   AVAILABLE   AGE
    apple   1/1     1            1           46s

# kubectl apply -f banana.yaml
    deployment.apps/banana created

Sprawdź, czy działa aplikacja banana:
# kubectl get deployment banana
    NAME    READY   UP-TO-DATE   AVAILABLE   AGE
    banana   1/1     1            1           82s

Sprawdź Pody:
# kubectl get pods -o wide
    NAME                               READY   STATUS    RESTARTS      AGE    IP           NODE         NOMINATED NODE   READINESS GATES
    apple-754df5984f-bkqzq             1/1     Running   0             119s   10.42.0.37   k3s-master   <none>           <none>
    banana-5b95d46c88-fkfn2            1/1     Running   0             106s   10.42.0.38   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0             31h    10.42.0.23   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0             31h    10.42.0.24   k3s-master   <none>           <none>
    my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0             31h    10.42.0.25   k3s-master   <none>           <none>
    my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0             27h    10.42.0.28   k3s-master   <none>           <none>
    mysql-c7d44f448-rcvrp              1/1     Running   0             25m    10.42.0.36   k3s-master   <none>           <none>
    secure-pod                         1/1     Running   2 (97s ago)   26h    10.42.0.31   k3s-master   <none>           <none>
    zombie-app-6db6d4d847-brtt9        1/1     Running   0             25h    10.42.0.33   k3s-master   <none>           <none>

Wystaw serwisy (to można zrobić z linii komend):
Teraz musimy stworzyć serwisy dla tych deploymentów, aby Ingress mógł się z nimi połączyć.

# kubectl expose deployment apple --port=5678
    service/apple exposed

# kubectl expose deployment banana --port=5678
    service/banana exposed


Sprawdź serwisy:
# kubectl get svc
    NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
    apple                            ClusterIP      10.43.88.0      <none>        5678/TCP       34s
    banana                           ClusterIP      10.43.145.85    <none>        5678/TCP       17s
    kubernetes                       ClusterIP      10.43.0.1       <none>        443/TCP        47h
    my-internal-service              ClusterIP      10.43.3.73      <none>        80/TCP         30h
    my-internal-service-custom       ClusterIP      10.43.117.2     <none>        80/TCP         27h
    my-lb-service-custom-app         LoadBalancer   10.43.136.176   172.17.0.2    80:30603/TCP   26h
    my-nodeport-service              NodePort       10.43.165.45    <none>        80:30007/TCP   30h
    my-nodeport-service-custom-app   NodePort       10.43.203.42    <none>        80:30008/TCP   27h


2. Stwórz ingress-routing.yaml:

3. Zadanie dla Ciebie:
# kubectl apply -f ingress-routing.yaml
    ingress.networking.k8s.io/owocowy-ingress created

Otwórz przeglądarkę w Windowsie.
Wejdź na: http://localhost/apple -> powinieneś zobaczyć tekst "apple".
Wejdź na: http://localhost/banana -> powinieneś zobaczyć tekst "banana".
Właśnie skonfigurowałeś profesjonalny routing HTTP!


--------------------------------------------------------------------------------------------------------------------------
To jest bardzo czujna i trafna uwaga! Bardzo dobrze, że to zauważyłeś. Masz rację – ClusterIP jest niedostępny z zewnątrz.

Ale... w tym przypadku to zadziała. Dlaczego?

Dlatego, że w grę wchodzi Ingress Controller (ten nasz "bramkarz", np. Nginx lub Traefik), który działa jako pośrednik.

Jak to działa (Magia Ingressa)

Wyobraź sobie to jak biurowiec:

Twoje aplikacje (apple i banana) siedzą w biurach numer 5 i 6. 
Drzwi do tych biur są zamknięte dla osób z ulicy. 
To jest ClusterIP. Nikt z zewnątrz (Windows) nie wejdzie bezpośrednio do biura nr 5.

Ingress Controller to recepcjonista siedzący w głównym holu. 
Główne wejście do budynku (Port 80) jest otwarte dla wszystkich. 
Docker przekierował to wejście na Twój localhost.

Ty (Przeglądarka) wchodzisz do głównego holu (localhost:80) i mówisz recepcjoniście: "Chcę do działu /apple".

Recepcjonista (Ingress Controller) jest pracownikiem firmy, więc on ma klucze do wewnętrznych biur! 
On idzie do biura nr 5 (przez sieć wewnętrzną klastra), bierze odpowiedź i przynosi ją Tobie do głównego holu.

Ścieżka Ruchu

Twój ruch wygląda tak:

Windows (Przeglądarka): http://localhost/apple
⬇️ (Port Forwarding Dockera)

K3s Container (Port 80): Tu nasłuchuje Ingress Controller (np. Nginx).
⬇️ (Routing wewnątrz klastra - to kluczowy moment!)

Serwis apple (ClusterIP): Ingress Controller łączy się z tym wewnętrznym IP.
⬇️

Pod apple: Aplikacja odpowiada.

Wniosek

Dlatego właśnie w Kubernetesie rzadko używa się NodePort czy LoadBalancer dla każdej małej aplikacji.
Wystawia się tylko jednego Ingress Controllera "na świat" (np. przez LoadBalancer), a wszystkie aplikacje pod spodem są ukryte jako ClusterIP. Ingress Controller działa jak "wtyczka", która łączy świat zewnętrzny z prywatną siecią klastra.

Więc śmiało, odpalaj! To zadziała właśnie dzięki temu mechanizmowi pośredniczenia.



--------------------------------------------------------------------------------------------------------------------------
Spróbuj też z wiersza poleceń (WSL):
# curl http://localhost/apple
    apple   
# curl http://localhost/banana
    banana

Gratulacje! Udało Ci się skonfigurować Ingress w Kubernetesie, umożliwiając dostęp do wielu usług pod jednym adresem IP na podstawie ścieżek URL.

----------------   jak masz 404  w przeglądarce ----------------------
To jest bardzo dobra wiadomość, chociaż wygląda jak błąd!
Komunikat 404 Not Found oraz podpis nginx/1.29.3 oznaczają, że:
Sieć działa: Twój ruch z Windowsa przeszedł przez Dockera i dotarł do Klastra.
Ingress Controller działa: Odpowiedział Ci Nginx (nasz "bramkarz"), a nie przeglądarka ("Connection Refused").
Dlaczego 404?
Ponieważ zainstalowaliśmy ingress-nginx (przez Helma), ale w naszym pliku ingress-routing.yaml nie powiedzieliśmy, 
że to właśnie ON ma obsłużyć te reguły. 
W Kubernetesie może być wielu "bramkarzy", więc musimy wskazać konkretnego klasę.
Bez tego, Twój Ingress Controller widzi plik, ale go ignoruje, więc nie wie, gdzie przekierować /apple, 
i wyświetla domyślny błąd 404.
Rozwiązanie: Dodaj ingressClassName
Musimy dodać jedną linijkę do pliku ingress-routing.yaml.

W niektórych klastrach Kubernetes może być konieczne określenie klasy Ingress, aby wskazać,
który kontroler Ingress ma obsługiwać dany zasób Ingress.
W k3s domyślnym kontrolerem jest Traefik, ale warto to jawnie zaznaczyć.

Dlaczego to konieczne?
Wcześniej, w starszych wersjach Kubernetesa, często działo się to automatycznie. 
Teraz standardem jest jawne definiowanie ingressClassName, 
 szczególnie gdy (tak jak my) wyłączyliśmy domyślnego Traefika i zainstalowaliśmy ręcznie Nginxa.


----------------   nadal masz 404  w przeglądarce ----------------------

To jest bardzo dobry znak! Błąd 404 Not Found z podpisem nginx oznacza, że:

1. Sieć działa (Twój Windows łączy się z K3s).
2. Ingress Controller (Nginx) odebrał zapytanie.
3. Problem: Nginx nie znalazł "odbiorcy" dla ścieżki /banana lub /apple (albo backend nie działa).

Musimy przeprowadzić krótkie śledztwo wewnątrz klastra, aby znaleźć "zaginione ogniwo".
Wykonaj te 4 komendy diagnostyczne w swoim terminalu WSL i wklej mi ich wyniki. 
To pozwoli nam natychmiast namierzyć błąd.

1. Sprawdź, czy mamy poprawną "Klasę Ingress"
   Musimy się upewnić, jak dokładnie nazywa się Twój Ingress Controller w systemie.
# kubectl get ingressclass
    NAME    CONTROLLER             PARAMETERS   AGE
    nginx   k8s.io/ingress-nginx   <none>       2d

2. Sprawdź, czy Serwisy (Apple/Banana) istnieją i mają dobre porty
   Ingress próbuje wysłać ruch do serwisów o nazwach apple i banana na porcie 5678. 
   Sprawdźmy, czy one tam są.

# kubectl get svc apple banana
    NAME     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
    apple    ClusterIP   10.43.88.0     <none>        5678/TCP   43m
    banana   ClusterIP   10.43.145.85   <none>        5678/TCP   42m


3. Sprawdź, czy Pody (aplikacje) żyją
   Może Deployment się nie udał i nie ma do czego wysłać ruchu.
# kubectl get pods
# kubectl get pods -l app=apple -o wide
    NAME                     READY   STATUS    RESTARTS   AGE    IP           NODE         NOMINATED NODE   READINESS GATES
    apple-754df5984f-bkqzq   1/1     Running   0          48m    10.42.0.37   k3s-master   <none>           <none>

# kubectl get pods -l app=banana -o wide
    NAME                      READY   STATUS    RESTARTS   AGE   IP           NODE         NOMINATED NODE   READINESS GATES
    banana-5b95d46c88-fkfn2   1/1     Running   0          48m   10.42.0.38   k3s-master   <none>           <none>


4. Sprawdź status samego Ingressa
   Zobaczmy, czy Ingress "zrozumiał" konfigurację i czy dostał adres IP.
# kubectl describe ingress owocowy-ingress
    Name:             owocowy-ingress
    Labels:           <none>
    Namespace:        default
    Address:          172.17.0.2
    Ingress Class:    nginx
    Default backend:  <default>
    Rules:
      Host        Path  Backends
      ----        ----  --------
      *
                  /apple      apple:5678 (10.42.0.37:5678)
                  /banana     banana:5678 (10.42.0.38:5678)
    Annotations:  <none>
    Events:
      Type    Reason  Age                From                      Message
      ----    ------  ----               ----                      -------
      Normal  Sync    37m (x2 over 38m)  nginx-ingress-controller  Scheduled for sync


5. Sprawdź, gdzie nasłuchuje Ingress Controller:
Musimy zobaczyć, jaki adres/port dostał Twój Btamkarz: Ingress Controller. 
On znajduje się w innej przestrzeni nazw (ingress-nginx), dlatego nie widzieliśmy go wcześniej.
# kubectl get svc -n ingress-nginx
    NAME                                 TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    ingress-nginx-controller             LoadBalancer   10.43.81.211   172.17.0.2    80:31896/TCP,443:32006/TCP   2d
    ingress-nginx-controller-admission   ClusterIP      10.43.140.62   <none>        443/TCP                      2d

Jeśli po wpisaniu kubectl get svc -n ingress-nginx zobaczysz przy ingress-nginx-controller status EXTERNAL-IP jako 172.17.0.2 (lub Pending -> 172.17.0.2), to znaczy,
że Ingress Controller przejął ruch.
Wtedy odśwież stronę http://localhost/banana w przeglądarce


----------------------  

To, co właśnie zrobiłeś, to esencja tego, jak działają nowoczesne strony internetowe i chmury. 
Rozbijmy to na prostą analogię, żebyś "zakumał" ideę, a nie tylko komendy.
Wyobraź sobie Duży Biurowiec.
1. Problem bez Ingressa
   Wcześniej (w Lab 3 z NodePort) każda aplikacja otwierała swoje własne "drzwi" na zewnątrz.
   Aplikacja "Apple" otwierała drzwi nr 30007.
   Aplikacja "Banana" otwierała drzwi nr 30008.
   Klient (przeglądarka) musiał wiedzieć: "Żeby dostać jabłko, muszę iść do drzwi 30007". 
   To jest niewygodne. Nikt nie chce wpisywać google.com:3421. Chcemy wpisywać po prostu adres.

2. Rozwiązanie z Ingressem (Recepcja)
   Ingress to Recepcjonista siedzący przy Głównym Wejściu (Port 80).
   Oto co zbudowałeś:
   Główne Wejście (LoadBalancer IP): 
   To jest jedyny adres, który zna świat (Twoja przeglądarka). 
   To jest Twój localhost przekierowany na 172.17.0.2.
   Recepcjonista (Ingress Controller Nginx): 
   To program, który stoi w drzwiach i wita każdego gościa. On nic nie produkuje, on tylko kieruje ruchem.
   Instrukcja dla Recepcjonisty (Plik YAML ingress-routing.yaml): 
   Dałeś recepcjoniście kartkę z zasadami:
   "Jak ktoś pyta o Apple (/apple) -> wyślij go do pokoju nr 1."
   "Jak ktoś pyta o Banana (/banana) -> wyślij go do pokoju nr 2."

3. Ścieżka Twojego Kliknięcia
   Kiedy wpisałeś w przeglądarce http://localhost/banana:
   Ty: Pukasz do głównych drzwi biurowca (Port 80).
   Nginx (Recepcjonista): 
   Odbiera Twoje zapytanie. Patrzy na adres koperty: /banana.
   Decyzja: Nginx zagląda do swojej ściągi (którą wgrałeś przez kubectl apply). 
   Widzi: "Aha! Banany są w serwisie banana".
   Przekierowanie: Nginx dzwoni do wewnętrznego serwisu banana (ClusterIP) i mówi: "Masz klienta".
   Aplikacja: Aplikacja Banana odpowiada, a Nginx przekazuje tę odpowiedź Tobie.
   Dlaczego to jest genialne?
   Dzięki temu mechanizmowi:
   Potrzebujesz tylko jednego publicznego adresu IP dla całego klastra (co oszczędza pieniądze w chmurze).
   Możesz mieć pod tym adresem tysiące różnych stron (/sklep, /blog, /poczta albo sklep.domena.com, blog.domena.com).
   Wszystkie certyfikaty SSL (kłódka w przeglądarce) konfigurujesz tylko raz – na Recepcji (Ingress), 
   a nie w każdej aplikacji z osobna.
   W skrócie: Zmieniłeś swój klaster z "dziurawego sera" (mnóstwo otwartych portów) w "elegancki biurowiec z jedną recepcją". 
   To jest standard produkcyjny.

4. Co dalej?
   Teraz, gdy już rozumiesz podstawy Ingressa, możesz eksperymentować z bardziej zaawansowanymi funkcjami:
   SSL/TLS: Dodaj certyfikaty, aby Twoje strony działały na HTTPS.
   Load Balancing: Skonfiguruj reguły, które rozkładają ruch między wieloma instancjami aplikacji.
   Autoryzacja: Dodaj mechanizmy uwierzytelniania na poziomie Ingressa.
   Monitoring: Śledź ruch i wydajność za pomocą narzędzi monitorujących.

5. Gratulacje! Opanowałeś kluczową technologię używaną w nowoczesnych aplikacjach webowych i chmurach. 
   Teraz możesz budować skalow


