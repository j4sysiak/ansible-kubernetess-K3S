

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

jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ helm version
version.BuildInfo{Version:"v3.19.0", GitCommit:"3d8990f0836691f0229297773f3524598f46bda6", GitTreeState:"clean", GoVersion:"go1.24.7"}

**************************************************************8

# Dodaj repozytorium z Ingress Nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Zaktualizuj listę dostępnych chartów
helm repo update

# Zainstaluj Ingress Nginx w swoim klastrze (pamiętaj o kubeconfig)
helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig
```Po wykonaniu tych komend, zobaczysz, że `kubectl get pods -n ingress-nginx` pokaże te same pody, które widziałeś wcześniej, ale tym razem zainstalowane i zarządzane przez Helma


# ***********************************************************************************
# *** Nowy, Bardziej Zaawansowany Krok: Wdrażanie Aplikacji za pomocą Helma i Ansible
# ***********************************************************************************

Stworzymy nową, super użyteczną rolę: deploy_app. Ta rola nie będzie instalować oprogramowania za pomocą apt. Zamiast tego, użyje komendy helm, którą właśnie zainstalowaliśmy, aby wdrożyć gotową aplikację (chart) do naszego klastra Kubernetes.
To nauczy Cię, jak orkiestrować narzędzia wiersza poleceń za pomocą Ansible.
Nasz cel: Zautomatyzujemy wdrożenie ingress-nginx, którego wcześniej instalowałeś ręcznie.

