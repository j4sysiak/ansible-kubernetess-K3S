Szybka procedura diagnostyczna i naprawcza:
Sprawdź stan podów i ewentualne błędy:


////////////////////////////  Na lokalnym hoście  //////////////////////////////////

Użyj pobranego kubeconfig (k3s-kubeconfig) do zapytań Kubernetes z twojej maszyny lokalnej.

 Sprawdź wszystkie pody
# kubectl get pods -A
# kubectl --kubeconfig=k3s-kubeconfig get pods -A

 Opisz pody, które mają problemy (przykład)
# kubectl --kubeconfig=k3s-kubeconfig describe pod <POD_NAME> -n <NAMESPACE>
# kubectl --kubeconfig=k3s-kubeconfig logs <POD_NAME> -n <NAMESPACE> --all-containers

 



//////////////////////////   Wewnątrz kontenera kontrolera (k3s-container)  ////////////////////////////////////////

Polecenia dotyczące procesu k3s, logów systemowych i socketu containerd wykonuj wewnątrz kontenera. Najpierw wejdź do kontenera:
# docker exec -it k3s-master bash
    Sprawdź, czy proces k3s działa
# pgrep -fl k3s
    Sprawdź, czy socket containerd istnieje
# ls -l /run/k3s/containerd/containerd.sock

Sprawdź runtime (embedded containerd) i czy klient widzi socket:

Upewnij się, że używasz właściwego endpointu
# export CONTAINERD_SOCK=unix:///run/k3s/containerd/containerd.sock

Lista wszystkich kontenerów przy użyciu crictl
# crictl --runtime-endpoint=$CONTAINERD_SOCK ps -a

Lista kontenerów w containerd (namespace k8s.io)
# ctr -n k8s.io containers list

Przejrzyj logi k3s / containerd w poszukiwaniu błędów związanych z runtime:

 Szukaj komunikatów 'not found' i powiązanych błędów
#  tail -n 200 /var/log/k3s.log | grep -E "NotFound|Error getting ContainerStatus|ContainerStatus from runtime service failed" -n -C 3


 
Jeśli wiadomości są ciągłe i wpływają na działanie klastrа — zrestartuj k3s (ze zwolnieniem zasobów przed restartem):

 Zabij proces k3s i uruchom ponownie (jeśli uruchamiasz bez systemd)
# pkill -f /usr/local/bin/k3s
# nohup /usr/local/bin/k3s server > /var/log/k3s.log 2>&1 &


//////////////////////////////////////////////////////////////////////////////////////////
Uwagi krótkie:
Jeśli po sprawdzeniu:
# kubectl get pods -A  
       wszystkie pody są OK, możesz zignorować sporadyczne wpisy NotFound — to typowe gdy runtime już usunął kontener, 
                  a kubelet jeszcze próbuje odczytać status.

Jeśli widzisz wiele crashów/RestartBackOff — najpierw zbadaj konkretne pody (describe + logs), potem przyjrzyj się crictl ps -a i ctr dla niezgodności stanu.
Masz poprawnie ustawiony snapshotter: fuse-overlayfs w \/etc/rancher/k3s/config.yaml`` więc poprzedni problem z overlayfs powinien być rozwiązany.


 