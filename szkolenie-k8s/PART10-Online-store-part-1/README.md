szkolenia prowadzonego przez Mumshada Mannambetha (z kursu KodeKloud).
https://www.youtube.com/watch?v=GhZi4DxaxxE&t=95s
do 10 min.
----------------------------------------------------------------------

To klasyczny przykład "My Online Store".
Scenariusz z tego szkolenia:
Mamy sklep internetowy dostępny pod domeną: www.my-online-store.com.
Mamy dwie oddzielne aplikacje (mikroserwisy):
 - Wear Service (Ubrania)    – dostępny pod ścieżką /wear.
 - Video Service (Streaming) – dostępny pod ścieżką /watch.
Ingress ma rozdzielać ruch do tych dwóch serwisów na podstawie URL.
Przygotowałem dla Ciebie gotowy kod, który odwzorowuje ten scenariusz w Twoim klastrze K3s. 
Użyjemy prostych obrazów, które będą symulować te aplikacje, żebyś widział efekt.

Krok 1: 
Aplikacje Backendowe (Wear & Video)
Stwórz plik: 1-apps.yaml
W tym pliku definiujemy Deploymenty i Serwisy dla obu "działów" sklepu. 
Zauważ, że Serwisy są typu ClusterIP (domyślnie), bo nie chcemy ich wystawiać bezpośrednio – dostęp ma być tylko przez Ingress.

Zastosuj:
# kubectl apply -f 1-apps.yaml
    deployment.apps/wear-deployment created
    service/wear-service created
    deployment.apps/video-deployment created
    service/video-service created

Krok 2: Ingress Resource (Serce systemu)
To jest dokładnie to, o czym była mowa w szkoleniu. 
Reguły routingu.
Stwórz plik: 2-ingress.yaml

Zastosuj:
# kubectl apply -f 2-ingress.yaml
    ingress.networking.k8s.io/ingress-wear-watch created

Krok 3: Konfiguracja DNS (Windows)
W szkoleniu mowa jest o konfiguracji DNS. 
Ponieważ nie mamy prawdziwej domeny, musimy "oszukać" Twój komputer.
Uruchom Notatnik jako Administrator.
Otwórz C:\Windows\System32\drivers\etc\hosts.
Dodaj linię (lub zaktualizuj istniejącą):
   127.0.0.1 www.my-online-store.com
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

Dlaczego? 
Bo w naszym Ingressie zdefiniowaliśmy reguły TYLKO dla /wear i /watch. 
Nie powiedzieliśmy, co robić ze stroną główną /, więc Nginx domyślnie wyrzuca błąd. To jest poprawne zachowanie!
Daj znać, czy sklep działa! 





















