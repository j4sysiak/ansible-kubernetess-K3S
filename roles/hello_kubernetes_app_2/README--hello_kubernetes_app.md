yaml
# File: roles/hello_kubernetes_app_2/tasks/main.yml
- name: Apply Kubernetes manifest from role files
  community.kubernetes.k8s:
  kubeconfig: "{{ kubeconfig }}"
  state: present
  src: "{{ role_path }}/files/app.yaml"

# Przed uruchomieniem:
# 1) Zainstaluj kolekcję (w wierszu poleceń):
# ansible-galaxy collection install community.kubernetes

# 2) Uruchom playbook (w katalogu projektu):
# ansible-playbook deploy_hello_kubernetes_app_2.yml


yaml
# File: roles/hello_kubernetes_app_2/tasks/main.yml
- name: Apply Kubernetes manifest from role files
  community.kubernetes.k8s:
  kubeconfig: "{{ kubeconfig }}"
  state: present
  src: "{{ role_path }}/files/app.yaml"

# Przed uruchomieniem:
# 1) Zainstaluj kolekcję (w wierszu poleceń):
# ansible-galaxy collection install community.kubernetes

# 2) Uruchom playbook (w katalogu projektu):
# ansible-playbook deploy_hello_kubernetes_app_2.yml


///////////////////////////////////////////////////////////////////////////////////














Wykorzystamy całą infrastrukturę, którą zbudowaliśmy (k3s + ingress-nginx), aby wdrożyć i publicznie udostępnić 
prostą aplikację.

Nasz Plan: Wdrożenie i Udostępnienie Aplikacji "Hello Kubernetes" 
       - to jest taka stronka, ktora bedzie dostepna pod urlem: http://localhost:8081

Zrobimy to w dwóch etapach, używając Ansible do zarządzania wszystkim:

# Etap 1: Wdrożenie Aplikacji w Klastrze
Utworzenie roli: hello_kubernetes_app
Celem tej roli będzie wdrożenie aplikacji "Hello Kubernetes" i udostępnienie jej za pomocą zasobu Ingress 
                               (Udostępnienie Aplikacji na Zewnątrz).
 
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
    NAME                               READY   STATUS              RESTARTS   AGE
    hello-kubernetes-bd87d88d7-6p5cz   0/1     ContainerCreating   0          12s
    hello-kubernetes-bd87d88d7-dtkbp   0/1     ContainerCreating   0          12s
    hello-kubernetes-bd87d88d7-ngwsl   0/1     ContainerCreating   0          12s

Sprawdź, czy zasób Ingress został stworzony:
# kubectl --kubeconfig=k3s-kubeconfig get ingress
    NAME                       CLASS    HOSTS   ADDRESS   PORTS   AGE
    hello-kubernetes-ingress   <none>   *                 80      33s

Finał: Otwórz przeglądarkę i wejdź na adres http://localhost:8081
        Ta strona nie działa