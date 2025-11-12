
# bash
ansible-playbook -i inventory site.yml
kubectl --kubeconfig=k3s-kubeconfig rollout status ds/dhcp-server -n dhcp
poczekaj chwilę i sprawdź logi:
kubectl --kubeconfig=k3s-kubeconfig logs -n dhcp -l app=dhcp-server -f

------------------------------------------

# Sprawdź namespace dhcp (jeśli został utworzony)
kubectl --kubeconfig=k3s-kubeconfig get daemonset -n dhcp

    NAME          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    dhcp-server   1         1         0       1            0           <none>          2m35s


# Zobacz wszystkie namespacey
kubectl --kubeconfig=k3s-kubeconfig get namespaces

    NAME               STATUS   AGE
    default            Active   2d1h
    dhcp               Active   7m49s
    hello-kubernetes   Active   47h
    hello-world        Active   2d
    ingress-nginx      Active   2d1h
    kube-node-lease    Active   2d1h
    kube-public        Active   2d1h
    kube-system        Active   2d1h

# Sprawdź pody we wszystkich namespacach
kubectl --kubeconfig=k3s-kubeconfig get pods -A | grep dhcp

    dhcp    dhcp-server-8l6q4    0/1     Error     7 (5m19s ago)   11m


-------------------------------------------------------
# Sprawdź pody
kubectl --kubeconfig=k3s-kubeconfig get pods -o wide

(ansible-venv) jacek@Friedrichshafen:~/dev/ansible-kubernetess-K3S$ kubectl --kubeconfig=k3s-kubeconfig get pods -o wide
No resources found in default namespace.

# Sprawdź logi
kubectl --kubeconfig=k3s-kubeconfig logs -l app=dhcp-server -f

# Sprawdź DaemonSet
kubectl --kubeconfig=k3s-kubeconfig get daemonset dhcp-server