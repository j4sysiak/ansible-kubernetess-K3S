1. Zainstaluj kolekcję community.kubernetes (zawiera ona moduł Helm):
# ansible-galaxy collection install community.kubernetes

Starting galaxy collection install process
Process install dependency map
Starting collection install process
Downloading https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/artifacts/community-kubernetes-2.0.1.tar.gz to /home/jacek/.ansible/tmp/ansible-local-126046fcfucf3/tmplm334ulj/community-kubernetes-2.0.1-gjj73dxz
Installing 'community.kubernetes:2.0.1' to '/home/jacek/.ansible/collections/ansible_collections/community/kubernetes'
community.kubernetes:2.0.1 was installed successfully
'kubernetes.core:5.4.1' is already installed, skipping.

*********************************************************

Twoja Misja
1. Upewnij się, że Twój klaster K3s i ingress-nginx działają.

 
2. Uruchom playbook: 
# ansible-playbook deploy_monitoring.yml      (Może to potrwać kilka minut).

3. Weryfikacja:
Sprawdź pody: 
# kubectl --kubeconfig=k3s-kubeconfig get pods -n monitoring

Sprawdź Ingress: 
# kubectl --kubeconfig=k3s-kubeconfig get ingress -n monitoring

Wielki Finał:
Edytuj plik C:\Windows\System32\drivers\etc\hosts jako administrator i dodaj linię: 127.0.0.1 grafana.local
Otwórz przeglądarkę i wejdź na http://grafana.local:8081
Zaloguj się (użytkownik: admin, hasło: prom-operator) i zobacz gotowe dashboardy monitorujące Twój klaster.

