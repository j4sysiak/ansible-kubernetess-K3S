Scenariusz: Kolega instaluje Twój chart i pyta: "No dobra, zainstalowałem.
I co teraz? Jaki jest adres? Jak się zalogować?".

1. W katalogu templates jest specjalny plik NOTES.txt.
To, co w nim napiszesz, wyświetli się w terminalu po zakończeniu instalacji.
Edytuj ten plik, żeby dodać instrukcje dla użytkownika Twojego charta.

2. Zainstaluj chart:
# helm upgrade --install test-helma ./moj-nginx

    Release "test-helma" has been upgraded. Happy Helming!
    NAME: test-helma
    LAST DEPLOYED: Sat Dec 13 20:59:33 2025
    NAMESPACE: default
    STATUS: deployed
    REVISION: 7
    TEST SUITE: None
    NOTES:
    GRATULACJE! Wdrozyles aplikacje: test-helma.
    1. Twoja wiadomosc od szefa to: Domyślna wiadomość: Pracujcie ciężko!
    2. Aby sprawdzic pody, wpisz:
       kubectl get pods -l app=test-helma
    3. Milego dnia!

Zobaczysz w terminalu swoją własną, spersonalizowaną instrukcję obsługi.
To jest znak rozpoznawczy profesjonalnych chartów.

Podsumowanie:
Jeśli przerobisz te laby, będziesz umiał:
1. Warunkowo włączać/wyłączać zasoby (if).
2. Generować konfigurację z list (range).
3. Cofać zepsute wdrożenia (rollback).
4. Pisać instrukcje dla użytkowników (NOTES.txt).
5. To solidny zestaw umiejętności!




























