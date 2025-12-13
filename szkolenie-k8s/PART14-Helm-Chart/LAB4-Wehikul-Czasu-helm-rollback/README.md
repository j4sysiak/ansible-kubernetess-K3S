LAB 4:
------
Wehikuł Czasu (helm rollback)
To jest najważniejsza operacja ratunkowa w pracy DevOpsa.
Scenariusz: 
Wdrożyłeś nową wersję aplikacji, ale okazało się, że ma krytyczny błąd (np. literówka w konfiguracji). 
Szef krzyczy: "Cofnij to natychmiast!".

1. Zróbmy zmianę nr 1 (Dobrą):
# helm upgrade test-helma ./moj-nginx --set szef.wiadomosc="Wersja 1 - Dziala"

2. Zróbmy zmianę nr 2 (Zepsutą):
# helm upgrade test-helma ./moj-nginx --set szef.wiadomosc="Wersja 2 - KATASTROFA BLAD"

3. Sprawdź historię:
   Wpisz:
# helm history test-helma
    REVISION        UPDATED                         STATUS          CHART           APP VERSION     DESCRIPTION
    1               Sat Dec 13 18:59:48 2025        superseded      moj-nginx-0.1.0 1.16.0          Install complete
    2               Sat Dec 13 19:05:30 2025        superseded      moj-nginx-0.1.0 1.16.0          Upgrade complete
    3               Sat Dec 13 19:07:49 2025        superseded      moj-nginx-0.1.0 1.16.0          Upgrade complete
    4               Sat Dec 13 20:50:49 2025        superseded      moj-nginx-0.1.0 1.16.0          Upgrade complete
    5               Sat Dec 13 20:51:22 2025        deployed        moj-nginx-0.1.0 1.16.0          Upgrade complete

Zobaczysz listę rewizji (1, 2, 3...). Ostatnia (najwyższa) to ta zepsuta.

4. Ratunek (Rollback):
   Cofamy się do poprzedniej wersji (np. rewizja nr 1).
# helm rollback test-helma 1
    Rollback was a success! Happy Helming!


5. Weryfikacja:
   Sprawdź `ConfigMap`:
# kubectl describe cm test-helma-config
   Powinieneś znowu widzieć "Wersja 1 - Dziala". Sytuacja opanowana w 5 sekund!































