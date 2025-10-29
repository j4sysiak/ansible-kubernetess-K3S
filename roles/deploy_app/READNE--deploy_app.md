# ***********************************************************************************
# *** Nowy, Bardziej Zaawansowany Krok: Wdrażanie Aplikacji za pomocą Helma i Ansible
# ***********************************************************************************

Stworzymy nową, super użyteczną rolę: deploy_app - 'ansible-kubernetess-K3S\roles\deploy_app'
Ta rola nie będzie instalować oprogramowania za pomocą apt.
Zamiast tego, użyje komendy helm, którą właśnie zainstalowaliśmy,
aby wdrożyć gotową aplikację (chart) do naszego klastra Kubernetes.
To nauczy Cię, jak orkiestrować narzędzia wiersza poleceń za pomocą Ansible.
Nasz cel: Zautomatyzujemy wdrożenie ingress-nginx, którego wcześniej instalowałeś ręcznie.


*****************************************************************************************************
Deploy application
# ansible-playbook deploy_helm_chart.yml


Weryfikacja: Sprawdź, czy pody ingress-nginx znowu działają:
# kubectl --kubeconfig=k3s-kubeconfig get pods -n ingress-nginx

    NAME                                                   READY   STATUS             RESTARTS   AGE
    my-ingress-ingress-nginx-controller-6b974db7d5-qcglk   0/1     ImagePullBackOff   0          4m10s