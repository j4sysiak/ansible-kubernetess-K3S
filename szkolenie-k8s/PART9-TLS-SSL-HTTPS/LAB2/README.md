Skupimy się na mechanizmie SNI (Server Name Indication).
Scenariusz dla Szefa:
"Szefie, mamy jeden adres IP, ale chcemy hostować pod nim dwie różne bezpieczne strony: bank.local i sklep.local. Każda musi mieć swój WŁASNY certyfikat SSL. Jak to zrobić?"
Zrobimy to w tym laboratorium.

Lab: Multi-Domain HTTPS (SNI)
Musimy wygenerować dwa różne certyfikaty.
Wgrać je jako dwa różne Sekrety i skonfigurować Ingress tak, żeby wiedział, który certyfikat podać w zależności od tego, jaki adres wpisze użytkownik.

Krok 1: Generowanie Certyfikatów (Bądźmy Urzędem Certyfikacji)
W terminalu WSL (w katalogu szkolenie-k8s) wygeneruj certyfikaty dla dwóch domen.
1. Dla domeny bank.local:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout bank.key -out bank.crt -subj "/CN=bank.local"

2. Dla domeny sklep.local:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout sklep.key -out sklep.crt -subj "/CN=sklep.local"

Teraz masz 4 pliki: 2 klucze (.key) i 2 certyfikaty (.crt).
    -rw------- 1 jacek jacek 1704 Dec  4 21:02 bank.key
    -rw-r--r-- 1 jacek jacek 1115 Dec  4 21:02 bank.crt
    -rw------- 1 jacek jacek 1704 Dec  4 21:03 sklep.key
    -rw-r--r-- 1 jacek jacek 1119 Dec  4 21:03 sklep.crt

Krok 2: Tworzenie Sekretów w K8s
Teraz wgramy je do klastra.
 - Sekret dla banku
# kubectl create secret tls bank-tls --key bank.key --cert bank.crt
    secret/bank-tls created

 - Sekret dla sklepu
# kubectl create secret tls sklep-tls --key sklep.key --cert sklep.crt
    secret/sklep-tls created
Sprawdź, czy powstały:
# kubectl get secrets

Krok 3: Wdrożenie Aplikacji (Backendy)
Stwórzmy prosty plik https-apps.yaml, który uruchomi dwie aplikacje testowe.

Wdróż to:
# kubectl apply -f https-apps.yaml
    deployment.apps/bank-app created
    service/bank-svc created
    deployment.apps/sklep-app created
    service/sklep-svc created


Krok 4: Ingress z konfiguracją SNI (To jest sedno)
Stwórz plik: https-ingress.yaml  
Zauważ, jak mapujemy hosty do konkretnych sekretów.

Wdróż to:
# kubectl apply -f https-ingress.yaml
    ingress.networking.k8s.io/sni-ingress created

Krok 5: Konfiguracja DNS (Windows)
Edytuj plik hosts w Windowsie (jako Administrator), aby dodać nasze nowe domeny:
    127.0.0.1 bank.local sklep.local


Wielki Test (Sprawdzamy Certyfikaty)
To jest najważniejsza część. 
Nie chodzi tylko o to, czy strona działa, ale jaki certyfikat widzisz.

Test 1: Bank
Wejdź na https://bank.local (zaakceptuj ryzyko, bo certyfikat jest "self-signed").
Powinieneś zobaczyć: "WITAJ W BANKU...".
Kliknij na kłódkę (lub "Niezabezpieczona") w pasku adresu -> Certyfikat.
W szczegółach certyfikatu, w polu "Wystawiony dla" (Common Name) musisz zobaczyć: bank.local.

Test 2: Sklep
Wejdź na https://sklep.local.
Powinieneś zobaczyć: "WITAJ W SKLEPIE...".
Sprawdź certyfikat.
W polu "Wystawiony dla" musisz zobaczyć: sklep.local.


Wnioski dla Szefa:
Działa: Udało nam się obsłużyć dwie różne domeny na jednym adresie IP (Twoim localhost), używając szyfrowania.
SNI: Ingress Controller "zajrzał" do pakietu, zanim nawiązał pełne szyfrowane połączenie, zobaczył, o jaką domenę pytasz, i podał odpowiedni certyfikat z odpowiedniego Sekretu.
Separacja: Certyfikat banku nie pasuje do sklepu i odwrotnie. To jest kluczowe dla bezpieczeństwa w środowiskach multi-tenant (wielu klientów na jednym klastrze).
Jeśli to zadziała, jesteś mistrzem TLS w Ingressie! 🔐









