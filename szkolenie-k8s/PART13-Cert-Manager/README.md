Co to jest Cert-Manager?
------------------------

Pamiętasz, jak przed chwilą musiałeś:
Wpisywać komendy openssl, żeby wygenerować klucze?
Wpisywać kubectl create secret, żeby wrzucić je do klastra?
Pilnować, kiedy certyfikat wygaśnie (np. za rok)?

Cert-Manager to automat (robot), który robi to wszystko za Ciebie.
Ty w pliku Ingressa piszesz tylko: "Chcę certyfikat dla domena.local".
Cert-Manager widzi to żądanie.
Sam generuje klucze.
Sam tworzy Kubernetes Secret.
Sam go odnawia, jak się kończy termin ważności.
W środowisku produkcyjnym Cert-Manager łączy się np. z Let's Encrypt, dając Ci darmowe, zielone kłódki automatycznie. 
W naszym laboratorium (localhost) użyjemy go do generowania certyfikatów "Self-Signed" (samo-podpisanych), 
 ale bez wpisywania ani jednej komendy openssl.

LAB: Automatyzacja SSL z Cert-Managerem
Zróbmy to. Zobaczysz, jak Secret "pojawia się sam".

Krok 1: 
Instalacja Cert-Managera
Musimy zainstalować ten program w klastrze. 
Najszybciej z oficjalnego pliku YAML.
Wpisz w terminalu WSL:
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml

Poczekaj chwilę, aż pody wstaną. Sprawdź:
# kubectl get pods -n cert-manager
    NAME                                       READY   STATUS              RESTARTS   AGE
    cert-manager-7d678bfb4f-rwdhf              0/1     ContainerCreating   0          24s
    cert-manager-cainjector-7449dc67b9-89z65   0/1     ContainerCreating   0          24s
    cert-manager-webhook-7789f864b7-qbs9r      0/1     Running             0          24s
(Powinieneś zobaczyć 3 pody: cert-manager, cainjector, webhook w stanie Running).

Krok 2: 
Stworzenie "Wydawcy" (Issuer)
Musimy powiedzieć Cert-Managerowi, kto ma wystawiać certyfikaty. 
Ponieważ jesteśmy na lokalnym Dockerze, stworzymy "Wydawcę Samo-podpisanego" (SelfSigned).
Stwórz plik:  issuer.yaml

Wdróż go:
# kubectl apply -f issuer.yaml
    clusterissuer.cert-manager.io/selfsigned-issuer created

Krok 3: 
Aplikacja + Ingress (Magia Automatyzacji)
Teraz wystawimy nową aplikację (np. "Auto-SSL").
W pliku Ingress dodamy specjalną adnotację, która powie Cert-Managerowi: "Hej, załatw mi certyfikat!".
Stwórz plik:   auto-ssl-app.yaml 

Wdróż to:
# kubectl apply -f auto-ssl-app.yaml
    deployment.apps/auto-ssl-app created
    service/auto-ssl-svc created
    ingress.networking.k8s.io/auto-ssl-ingress created

Krok 4:
Obserwacja Magii
Teraz patrz uważnie. 
Nie tworzyliśmy ręcznie sekretu automat-tls-secret. 
Sprawdźmy, czy istnieje.
# kubectl get secret automat-tls-secret
    NAME                 TYPE                DATA   AGE
    automat-tls-secret   kubernetes.io/tls   3      107s

Na początku może go nie być, ale po kilku sekundach powinien się pojawić.
Możesz też sprawdzić status certyfikatu:
# kubectl get certificate
    NAME                 READY   SECRET               AGE
    automat-tls-secret   True    automat-tls-secret   2m27s
Powinieneś zobaczyć READY: True.

Krok 5: 
Test w przeglądarce
Dodaj do hosts w Windowsie: 127.0.0.1 auto.local 
Wejdź na https://auto.local 
Zadziała tak samo jak wcześniej (ostrzeżenie o certyfikacie -> strona Nginx), ale tym razem nie dotknąłeś OpenSSL ani razu.
Wniosek dla Szefa
Twój kolega miał rację co do funkcjonalności, ale pomylił nazwy.
Vaultwarden = Menedżer haseł dla ludzi (logujesz się, kopiujesz hasło do Netflixa).
Cert-Manager = Automat do certyfikatów SSL dla maszyn (klaster sam sobie generuje klucze i wpina je do Ingressa).
W profesjonalnych klastrach używa się obu tych narzędzi.

Podsumowanie:
Cert-Manager to potężne narzędzie do automatyzacji zarządzania certyfikatami SSL w Kubernetes.
Pozwala na automatyczne generowanie, odnawianie i zarządzanie certyfikatami bez konieczności ręcznego wykonywania poleceń OpenSSL.
Dzięki niemu możesz skupić się na rozwijaniu aplikacji, zamiast martwić się o bezpieczeństwo połączeń.

# https://auto.local
 
    Welcome to nginx!
    If you see this page, the nginx web server is successfully installed and working. Further configuration is required.

    For online documentation and support please refer to nginx.org.
    Commercial support is available at nginx.com.
    Thank you for using nginx.















