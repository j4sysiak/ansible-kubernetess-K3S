Wykorzystamy całą infrastrukturę, którą zbudowaliśmy (k3s + ingress-nginx), aby wdrożyć i publicznie udostępnić 
prostą aplikację.

Nasz Plan: Wdrożenie i Udostępnienie Aplikacji "Hello Kubernetes"

Zrobimy to w dwóch etapach, używając Ansible do zarządzania wszystkim:

# Etap 1: Wdrożenie Aplikacji w Klastrze
Utworzenie roli: hello_kubernetes_app
Celem tej roli będzie wdrożenie aplikacji "Hello Kubernetes" i udostępnienie jej za pomocą zasobu Ingress.
 
# Etap 2: Udostępnienie Aplikacji na Zewnątrz
Przygotuj Manifesty Aplikacji
Utworzymy proste plik manifestu YAML dla aplikacji "Hello Kubernetes".
Wszystkie pliki konfiguracyjne naszej aplikacji umieścimy wewnątrz nowej roli.
 - roles/hello_kubernetes_app/files/deployment.yaml   (plik manifestu, dla zasobów: Service + Deployment)
 - roles/hello_kubernetes_app/files/ingress.yaml    (plik manifestu, tym razem dla zasobu: Ingress)


# Etap 3: Implementacja Zadań w tasks/main.yml
Zadania w nowej roli będą bardzo proste: zastosuj oba pliki manifestu.
 - roles/hello_kubernetes_app/tasks/main.yml 


# Etap 4: Stwórz Playbook do Wdrożenia Aplikacji
Upewnij się, że Twój klaster K3s i ingress-nginx działają.
Uruchamiamy playbooka, który wywoła naszą nową rolę:
# ansible-playbook deploy_hello_app.yml

# Etap 5: Weryfikacja:
Sprawdź, czy pody działają:
# kubectl --kubeconfig=k3s-kubeconfig get pods
Sprawdź, czy zasób Ingress został stworzony:
# kubectl --kubeconfig=k3s-kubeconfig get ingress
Finał: Otwórz przeglądarkę i wejdź na adres http://localhost:8081.