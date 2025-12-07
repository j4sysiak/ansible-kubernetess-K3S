Krok 1: Generowanie Certyfikatów (Twoja "Kłódka")
Musimy stworzyć certyfikat dla domeny passwords.local
Bez tego Vaultwarden nie pozwoli Ci się zalogować.

1. Klucz prywatny
# openssl genrsa -out tls.key 2048

2. Certyfikat publiczny (ważny 365 dni)
# openssl req -new -x509 -key tls.key -out tls.crt -days 365 -subj "/CN=passwords.local"

Krok 2:
Teraz wgrajmy go do klastra jako Kubernetes Secret typu TLS:
# kubectl create secret tls vaultwarden-tls --key tls.key --cert tls.crt
    secret/vaultwarden-tls created

Krok 3: 
Hasło Administratora (Dla aplikacji)
Vaultwarden ma specjalny panel admina (do zarządzania użytkownikami), który jest chroniony tokenem. 
Nie chcemy tego tokena wpisywać "na twardo" w pliku Deploymentu.
Stworzymy Kubernetes Secret z tokenem: SuperTajneHasloAdmina123
# kubectl create secret generic vaultwarden-secret --from-literal=ADMIN_TOKEN=SuperTajneHasloAdmina123
    secret/vaultwarden-secret created

Krok 4: 
Plik Manifestu vaultwarden.yaml
Stwórz plik:  vaultwarden.yaml 

Zawiera on 4 elementy:
1. PVC: Dysk 1GB, żeby hasła nie zniknęły po restarcie kontenera.
2. Deployment: Sama aplikacja. Zauważ, jak pobieramy ADMIN_TOKEN z sekretu.
3. Service: Wewnętrzne wyjście aplikacji.
4. Ingress: Wystawienie na świat z HTTPS.

Wdróż to:
# kubectl apply -f vaultwarden.yaml
    persistentvolumeclaim/vaultwarden-pvc created
    deployment.apps/vaultwarden created
    service/vaultwarden-svc created
    ingress.networking.k8s.io/vaultwarden-ingress created

Krok 5: 
Konfiguracja DNS (Windows)
Twój Windows musi wiedzieć, gdzie szukać passwords.local.
Uruchom Notatnik jako Administrator.
Otwórz plik C:\Windows\System32\drivers\etc\hosts.
Dodaj na końcu linię:
 
    127.0.0.1 passwords.local
Zapisz plik.



Krok 6: 
Wielki Test (Czy to działa?)
Teraz najważniejsza chwila.
Otwórz przeglądarkę.
Wejdź na adres: https://passwords.local
(Jeśli wejdziesz przez http, powinien Cię automatycznie przekierować na https).

Co powinieneś zobaczyć:
Ostrzeżenie o certyfikacie ("Połączenie nie jest prywatne"). To normalne przy własnym certyfikacie. Kliknij "Zaawansowane -> Przejdź do strony".
Stronę logowania Vaultwarden (ciemnoszara/niebieska).
Test Funkcjonalny (Czy HTTPS działa poprawnie?):
Kliknij "Create Account".
Wpisz byle jaki email, nazwę i hasło.
Kliknij "Create Account".
Jeśli działa: Konto się utworzy. Oznacza to, że przeglądarka zaakceptowała szyfrowanie.
Jeśli błąd: "Error: An unexpected error has occurred" (często z czerwoną ramką) – oznacza to zazwyczaj problem z HTTPS (przeglądarka blokuje kryptografię JS). Ale u nas powinno być OK.
Test Panelu Admina:
Wejdź na: https://passwords.local/admin
Zostaniesz poproszony o "Admin Token".
Wpisz: SuperTajneHasloAdmina123
Powinieneś zobaczyć panel konfiguracyjny serwera (User overview, Settings itp.).
Daj znać, czy udało Ci się założyć konto! To ostateczny dowód, że wszystko działa. 🚀



















