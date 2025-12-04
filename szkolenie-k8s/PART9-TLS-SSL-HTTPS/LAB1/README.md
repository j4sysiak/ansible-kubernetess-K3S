
Teoria dla Szefa (W 3 punktach)
Gdy szef zapyta, jak działa SSL w K8s, odpowiadasz:
1. TLS Termination na Ingressie: Nie szyfrujemy ruchu do samego kontenera z aplikacją (to by było trudne w zarządzaniu). 
   Szyfrowanie kończy się na "bramie" (Ingress Controller).

2. Kubernetes Secrets: Certyfikaty (klucz publiczny i prywatny) trzymamy w obiekcie typu Secret. 
   Ingress pobiera je stamtąd automatycznie.

3. SNI (Server Name Indication): 
   Ingress potrafi obsłużyć wiele różnych certyfikatów na jednym adresie IP, rozróżniając je po nazwie domeny.

LAB: Wdrażamy bezpieczną stronę secure.local
Zrobimy to w 4 krokach w katalogu szkolenie-k8s/PART9-TLS-SSL-HTTPS

Krok 1: Wygeneruj Certyfikat (OpenSSL)
W prawdziwym świecie te pliki kupujesz w urzędzie certyfikacji (lub dostajesz z Let's Encrypt). 
My wygenerujemy je sami.

W terminalu WSL wpisz:
----------------------
1. Wygeneruj klucz prywatny (to jest Twój "tajny podpis")
# openssl genrsa -out tls.key 2048

2. Wygeneruj certyfikat publiczny ważny dla domeny "secure.local"
# openssl req -new -x509 -key tls.key -out tls.crt -days 365 -subj "/CN=secure.local"


# Teraz masz w katalogu dwa pliki: tls.key (klucz) i tls.crt (certyfikat).
    -rw-------  1 jacek jacek  1704 Dec  4 20:27 tls.key
    -rw-r--r--  1 jacek jacek  1123 Dec  4 20:27 tls.crt


Krok 2: Wgraj certyfikat do Kubernetesa (Secret)
Kubernetes musi "mieć" te pliki u siebie, żeby Nginx mógł ich użyć. 
Tworzymy Sekret typu tls.

# kubectl create secret tls moj-sekret-ssl --cert=tls.crt --key=tls.key
    secret/moj-sekret-ssl created

Sprawdź, czy powstał:
# kubectl get secret moj-sekret-ssl
    NAME             TYPE                DATA   AGE
    moj-sekret-ssl   kubernetes.io/tls   2      48s

Krok 3: Wdróż aplikację i Ingress z TLS
Stwórz plik secure-app.yaml. 
Zdefiniujemy tu aplikację oraz Ingress, który używa naszego sekretu.

Wdróż to:
cd szkolenie-k8s/PART9-TLS-SSL-HTTPS/LAB1
# kubectl apply -f secure-app.yaml
    deployment.apps/secure-app created
    service/secure-svc created
    ingress.networking.k8s.io/secure-ingress created
Sprawdź, czy wszystko działa:
# kubectl get all

    NAME                                   READY   STATUS    RESTARTS   AGE
    pod/secure-app-599d74895f-2mqcf        1/1     Running   0          2m42s

    NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    service/secure-svc       ClusterIP   10.43.80.87     <none>        80/TCP     2m42s

    NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/secure-app         1/1     1            1           2m42s

    NAME                                         DESIRED   CURRENT   READY   AGE
    replicaset.apps/secure-app-599d74895f        1         1         1       2m42s

    NAME                                       CLASS    HOSTS              ADDRESS        PORTS     AGE
    ingress.networking.k8s.io/secure-ingress   <none>   secure.local

Krok 4: Konfiguracja DNS (Windows)
Żeby to przetestować, Twój Windows musi wiedzieć, co to jest secure.local.
Edytuj jako Administrator plik C:\Windows\System32\drivers\etc\hosts.
Dodaj linię:
 127.0.0.1 secure.local

WIELKI TEST
Otwórz przeglądarkę.
Wpisz adres: https://secure.local (zwróć uwagę na https).

Dziala:  
JESTEM BEZPIECZNY (HTTPS)!

Co się stanie?
Przeglądarka wyświetli ostrzeżenie o bezpieczeństwie ("Połączenie nie jest prywatne").
Dlaczego? Bo sami podpisaliśmy certyfikat, a nie zaufany urząd. 
To normalne w labach. 
Szefowi powiesz: "To dowód, że szyfrowanie działa, tylko certyfikat jest testowy".
Kliknij "Zaawansowane" -> "Przejdź do strony (niebezpieczne)".
Zobaczysz tekst: "JESTEM BEZPIECZNY (HTTPS)!".
W pasku adresu zobaczysz Kłódkę (może być przekreślona lub z wykrzyknikiem). 
Kliknij na nią -> "Certyfikat". Zobaczysz tam nazwę "secure.local".


Pytanie Bonusowe od Szefa
Szef: "A co jeśli wejdę przez HTTP (http://secure.local)?"
Ty: "Sprawdźmy!"
Wpisz w przeglądarce http://secure.local.
Ingress Nginx jest domyślnie tak skonfigurowany, że jeśli widzi sekcję tls w konfiguracji, 
to automatycznie wysyła kod 308 Permanent Redirect i wymusza na przeglądarce przejście na HTTPS. To jest "secure by default".

http://secure.local  --> automatyczny redirect do: https://secure.local


Automatyzacja w produkcji (To warto wspomnieć)
W prawdziwej pracy rzadko generuje się certyfikaty ręcznie openssl. 
Używa się narzędzia Cert-Manager.
Jak to działa?
Instalujesz w klastrze cert-manager.
W Ingressie dodajesz jedną linijkę (adnotację): cert-manager.io/cluster-issuer: "letsencrypt".
Kubernetes sam idzie do Let's Encrypt, pobiera darmowy, zaufany certyfikat, tworzy Sekret i go podpina. Wszystko dzieje się samo.
Ale żeby to zrozumieć, musiałeś najpierw zrobić to ręcznie – tak jak powyżej.
Daj znać, czy kłódka się pojawiła! 🔒







