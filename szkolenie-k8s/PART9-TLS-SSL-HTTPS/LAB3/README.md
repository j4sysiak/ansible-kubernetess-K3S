Zabezpieczenie strony hasłem (Basic Auth) działające po HTTPS.
Scenariusz dla Szefa:
"Szefie, wystawiliśmy ten panel administracyjny (admin.local) na świat, jest zaszyfrowany kłódką, ale... każdy może tam wejść! Musimy dodać proste logowanie login/hasło, zanim w ogóle dopuścimy kogoś do aplikacji."
W Kubernetesie nie musisz modyfikować kodu aplikacji, żeby dodać logowanie. Zrobi to za Ciebie Ingress Controller.

Lab: Secure Admin Panel (HTTPS + Basic Auth)
Zbudujemy stronę https://admin.local, która:
Będzie szyfrowana (TLS).
Wyskoczy okienko przeglądarki z pytaniem o login i hasło.
Krok 1: Generowanie Certyfikatu (Standardowo)
W terminalu WSL (katalog szkolenie-k8s):

# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout admin.key -out admin.crt -subj "/CN=admin.local"

Stwórz sekret TLS w klastrze:
# kubectl create secret tls admin-tls --key admin.key --cert admin.crt
    secret/admin-tls created

Krok 2: Generowanie Hasła (To jest nowość)
Musimy stworzyć plik z zahaszowanym hasłem (standard htpasswd).
Użyjemy użytkownika admin i hasła tajne123.
Ponieważ możesz nie mieć narzędzia htpasswd pod ręką, przygotowałem dla Ciebie gotowy ciąg.
Stwórz plik:  auth-secret.yaml 


Wdróż go:
# kubectl apply -f auth-secret.yaml
    secret/basic-auth created

# kubectl get secret basic-auth
    NAME         TYPE     DATA   AGE
    basic-auth   Opaque   1      6m39s

Krok 3: Wdrożenie Aplikacji "Secret Admin"
To zwykła aplikacja, która nie wie nic o hasłach.
Stwórz plik: admin-app.yaml


Wdróż to:
# kubectl apply -f admin-app.yaml
    deployment.apps/admin-app created
    service/admin-svc created




Krok 4: Ingress z Adnotacjami (Magia Nginxa)
Teraz najważniejszy moment. 
Użyjemy Annotations (Adnotacji). 
To jest sposób na przekazanie specyficznej konfiguracji do Ingress Controllera (w tym wypadku Nginxa).
Stwórz plik:  admin-ingress.yaml

Wdróż to:
# kubectl apply -f admin-ingress.yaml
    ingress.networking.k8s.io/admin-ingress created


Krok 5: DNS (Windows)
Edytuj hosts w Windowsie:
    127.0.0.1 admin.local



Wielki Test
Otwórz przeglądarkę (najlepiej w trybie Incognito, żeby nie zapamiętała hasła).
Wejdź na: https://admin.local
Czego się spodziewać:
Najpierw zobaczysz ostrzeżenie o certyfikacie (zaakceptuj je).
BUM! Przeglądarka wyświetli systemowe okienko logowania.
Strona pod spodem się nie ładuje.
Jeśli klikniesz "Anuluj", dostaniesz błąd 401 Authorization Required.
Wpisz dane:
Użytkownik: admin
Hasło: tajne123
Dopiero teraz powinieneś zobaczyć tekst: "WITAJ W TAJNYM PANELU ADMINISTRATORA!".
Wnioski dla Szefa:
Bezpieczeństwo warstwowe: Mamy szyfrowanie (kłódka) ORAZ autoryzację (hasło).
Ochrona aplikacji: Sama aplikacja (ten pod http-echo) nie ma w sobie ani linijki kodu do logowania. Całą ochronę zapewnia Ingress przed wejściem do klastra. To odciąża programistów.
Daj znać, czy okienko logowania wyskoczyło! 🔐🕵️‍♂️



--------------   ERROR

User
teraz pojawilo się okno logowania, ale jak wpisuje admin / tajne123  
to nie przechodzi do stony tylko caly czas mam okno logowania, jakby haslo bylo spaprane.

Odp.

To klasyczny objaw. Pętla logowania (okienko wraca po wpisaniu danych) oznacza, że Nginx poprawnie czyta plik z hasłami, ale hash, który mu podałem w poprzednim kroku, nie pasuje do hasła tajne123 (mógł zostać źle wygenerowany lub źle zakodowany w Base64).
Zamiast polegać na moim "gotowcu", wygenerujemy poprawny plik z hasłami bezpośrednio u Ciebie. To najpewniejsza metoda.
Potrzebujemy małego narzędzia htpasswd.
Krok 1: Instalacja narzędzia (w WSL)
W swoim terminalu WSL (nie w kontenerze, po prostu w Ubuntu) wpisz:

# sudo apt-get update && sudo apt-get install -y apache2-utils


Krok 2: Wygenerowanie pliku z hasłem
Teraz stworzymy plik o nazwie auth, który będzie zawierał poprawnie zahaszowane hasło dla użytkownika admin.
Uruchom komendę:
# htpasswd -c auth admin
    New password:  test
    Re-type new password:  test
    Adding password for user admin


Zostaniesz zapytany o hasło. Wpisz: test (i potwierdź).
Teraz w Twoim katalogu powstał plik auth. 
Możesz sprawdzić jego zawartość (cat auth), powinien wyglądać mniej więcej tak: admin:$apr1$.....
Krok 3: Podmiana Sekretu w Kubernetesie
Teraz musimy usunąć stary, wadliwy sekret i wgrać ten nowy, który właśnie stworzyłeś. 
Najbezpieczniej jest użyć flagi --from-file, wtedy kubectl sam zajmie się kodowaniem Base64 i unikniemy pomyłek.

Usuń stary sekret:
# kubectl delete secret basic-auth
    secret "basic-auth" deleted from default namespace

Stwórz nowy z Twojego pliku:
# kubectl create secret generic basic-auth --from-file=auth
    secret/basic-auth created

Krok 4: Wielki Test (Ponownie)
Nginx Ingress Controller powinien automatycznie wykryć zmianę sekretu (może to potrwać kilka sekund).
Wróć do przeglądarki.
Odśwież stronę https://admin.local.
Gdy wyskoczy okienko:
Login: admin
Hasło: test
Teraz musi Cię wpuścić i pokazać komunikat "WITAJ W TAJNYM PANELU ADMINISTRATORA!".
 

Dziala!!
















