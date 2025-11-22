# ***********************************************************************************
# *** Nowy, Bardziej Zaawansowany Krok: Wdrażanie Aplikacji za pomocą helma w Ansible
# ***********************************************************************************

Przeczytaj to: ansible-kubernetess-K3S\README__opis_podstawowych_pojęć_Kubernetesa.md
*****************************************************************************************************
Cel: Wdrożenie aplikacji w klastrze Kubernetes za pomocą Helma i Ansible
*****************************************************************************************************
Do tej pory instalowaliśmy aplikacje w klastrze K3s ręcznie, używając narzędzi wiersza poleceń, takich jak kubectl i helm.
Teraz zautomatyzujemy ten proces, tworząc rolę Ansible, która użyje Helma do wdrożenia aplikacji w klastrze.
Nauczysz się, jak orkiestrować narzędzia wiersza poleceń za pomocą Ansible, co jest kluczową umiejętnością w zarządzaniu infrastrukturą.
*****************************************************************************************************
Nowa Rola: deploy_app_using_helm_chart
*****************************************************************************************************
Stworzymy nową, super użyteczną rolę: deploy_app_using_helm_chart - 'ansible-kubernetess-K3S\roles\deploy_app_using_helm_chart'
Rola ta NIE będzie instalować oprogramowania za pomocą apt!
Zamiast tego, użyje komendy helm, którą właśnie zainstalowaliśmy,
aby wdrożyć gotową aplikację (chart) do naszego klastra Kubernetes.
To nauczy Cię, jak orkiestrować narzędzia wiersza poleceń za pomocą Ansible.
Nasz cel: Zautomatyzujemy wdrożenie ingress-nginx, którego wcześniej instalowałeś ręcznie.


*****************************************************************************************************

Deploy application
# ansible-playbook -i inventory/hosts.ini  destroy_app_using_helm_chart.yml
# ansible-playbook -i inventory/hosts.ini deploy_app_using_helm_chart.yml


Weryfikacja: Sprawdź, czy pody ingress-nginx znowu działają:
# kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx
 
      status musi pokazać "Running" - czekaj aż tak będzie

    NAME                                                   READY   STATUS    RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6766768fbc-l2nf2   1/1     Running   0          103s


Krótko: 
nie uruchamiasz Nginx „lokalnie” jako zwykły serwer HTTP, tylko wystawiasz Ingress Nginx w klastrze K3s, 
a http://localhost:8081 to tylko sposób przekierowania ruchu z Twojej maszyny do klastra.

Żeby ten finał zadziałał, muszą być spełnione wszystkie kroki „infrastrukturalne”, 
które wcześniej robiłeś ręcznie:
1. Klaster K3s musi działać (w kontenerze / VM, tak jak w Twoim projekcie).
2. W tym klastrze musi być zainstalowany Ingress Nginx:
      kiedyś robiłeś to ręcznie komendą helm install ...,

teraz robi to rola deploy_app_using_helm_chart (i dawniej playbook installing_charts_using_helm).

3. Musi być uruchomione forwardowanie portu z Twojego hosta na Service w klastrze, np.:
# kubectl --kubeconfig=k3s-kubeconfig port-forward -n ingress-nginx svc/my-ingress-ingress-nginx-controller 8081:80

4. Dopiero wtedy wejście na http://localhost:8081 pokaże stronę Welcome to nginx!.

Rola deploy_app_using_helm_chart (tak jak wcześniejszy installing_charts_using_helm) odpowiada tylko za krok 2 – czyli za to, 
żeby w klastrze był zainstalowany release Helma z Ingress Nginx.
Samo „odpalenie Nginx lokalnie” i dostęp przez localhost:8081 wymaga jeszcze osobnego kroku z kubectl
port-forward (albo NodePort / LoadBalancer), którego teraz rola nie robi.


teraz dziala:
Finał: Otwórz przeglądarkę i wejdź na http://localhost:8081
        Powinieneś zobaczyć domyślną stronę powitalną ingress-nginx:
        Welcome to nginx!