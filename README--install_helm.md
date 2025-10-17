

# ansible-playbook install_helm.yml --ask-become-pass

password n a roota: jacek


lub 

Zrobimy to w bezpieczny sposób, tworząc dedykowany plik konfiguracyjny dla Twojego użytkownika.
Jak to zrobić?
W swoim terminalu WSL/Ubuntu wykonaj następującą komendę:

# sudo visudo -f /etc/sudoers.d/90-jacek

sudo visudo: To jest specjalne, bezpieczne narzędzie do edycji plików konfiguracyjaxcyjnych sudo. Zawsze go używaj!
-f /etc/sudoers.d/90-jacek: Mówi visudo, aby stworzył i edytował nowy plik o nazwie 90-jacek w specjalnym katalogu. Dzięki temu nie modyfikujemy głównego pliku sudoers i łatwo możemy cofnąć zmiany.
Po wykonaniu komendy otworzy się edytor tekstu (prawdopodobnie nano). Wklej do tego pliku jedną, jedyną linię:
 
jacek ALL=(ALL) NOPASSWD: ALL


jacek: Nazwa Twojego użytkownika.
ALL=(ALL): Może uruchamiać polecenia jako dowolny użytkownik.
NOPASSWD: ALL: Najważniejsza część. Może uruchamiać wszystkie polecenia (ALL) bez pytania o hasło.
Zapisz i zamknij plik:
W nano: Ctrl + X, następnie Y (aby potwierdzić zapis), a następnie Enter (aby potwierdzić nazwę pliku).
visudo sprawdzi składnię pliku przed zapisaniem. Jeśli wszystko jest w porządku, wróci do linii komend.
Weryfikacja
Aby sprawdzić, czy zmiana zadziałała, spróbuj uruchomić jakąś prostą komendę sudo, np.:
 
sudo ls /root

jeszcze raz bez hasła:
# ansible-playbook install_helm.yml 


