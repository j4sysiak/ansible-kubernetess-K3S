Szybka procedura diagnostyczna i naprawcza:
Sprawdź stan podów i ewentualne błędy:


////////////////////////////  Na lokalnym hoście  //////////////////////////////////
# sprawdź klienta kubectl (lokalnie)
kubectl version --client

# 1) Sprawdź i użyj wbudowanego k3s kubectl (jeśli jest)
docker exec -it k3s-master bash -c 'command -v k3s >/dev/null && k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -A || echo "k3s binary not found"'

# 2) Zalecane: skopiuj kubeconfig na host i użyj lokalnego kubectl
docker cp k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s-kubeconfig
chmod 600 ./k3s-kubeconfig
# (jeśli w kubeconfig jest server: https://127.0.0.1:6443 -> zmień na adres dostępny z hosta)
# przykładowa zmiana (dostosuj IP):
sed -i 's/127.0.0.1:6443/192.168.1.100:6443/' ./k3s-kubeconfig
export KUBECONFIG=$PWD/k3s-kubeconfig
kubectl get pods -A

 

# znajdź IP kontenera (użyj tego IP w kubeconfig)
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' k3s-master

# sprawdź czy port 6443 jest wystawiony na hoście
docker port k3s-master 6443 || true

# jeśli w kubeconfig jest server: https://127.0.0.1:6443 -> zamień na znalezione IP:6443
sed -i 's/127.0.0.1:6443/CONTAINER_IP:6443/' ./k3s-kubeconfig

# ustaw i użyj lokalnego kubectl
export KUBECONFIG=$PWD/k3s-kubeconfig
kubectl get pods -A


# skopiuj kubeconfig z kontenera
docker cp k3s-master:/etc/rancher/k3s/k3s.yaml ./k3s-kubeconfig
chmod 600 ./k3s-kubeconfig

# sprawdź wartość server: w pliku
grep '^  server:' -n ./k3s-kubeconfig || true

# jeśli trzeba, zamień 127.0.0.1:6443 na localhost:6443 (host nasłuchuje na 0.0.0.0:6443)
sed -i 's/127.0.0.1:6443/localhost:6443/' ./k3s-kubeconfig

# ustaw kubeconfig i przetestuj
export KUBECONFIG=$PWD/k3s-kubeconfig
kubectl get pods -A

# szybki test API
curl -k https://127.0.0.1:6443/version


# sprawdź węzły i status klastra
kubectl get nodes
kubectl get cs || true

# sprawdź zdarzenia i opis dla namespace kube-system
kubectl get events -A --sort-by='.metadata.creationTimestamp'
kubectl -n kube-system describe pod <POD_NAME>

# podejrzyj logi problematycznych podów (wszystkie kontenery)
kubectl logs -n <NAMESPACE> <POD_NAME> --all-containers

# sprawdź usługi i endpointy (np. kontroler ingress)
kubectl get svc -A
kubectl describe svc my-ingress-ingress-nginx-controller -n ingress-nginx

# jeśli chcesz testować dostęp do serwisów z hosta
curl -k https://127.0.0.1:6443/version
# test ingress (dostosuj host/port)
curl -v http://localhost/

# jeśli chcesz mieć kubeconfig globalnie dostępny na hoście:
mkdir -p ~/.kube
# zachowaj backup jeśli istnieje
[ -f ~/.kube/config ] && mv ~/.kube/config ~/.kube/config.bak
kubectl config view --flatten --minify > ~/.kube/config
chmod 600 ~/.kube/config


# Wyodrębnij i zdekoduj certy z kubeconfig używając lokalnego kubectl
kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > client.crt
kubectl --kubeconfig=./k3s-kubeconfig config view --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > client.key
chmod 600 client.key

# Teraz wykonaj zapytanie uwierzytelnione klientem
curl --cacert ca.crt --cert client.crt --key client.key https://127.0.0.1:6443/version

# Alternatywa: użyj kubectl (już działa) zamiast ręcznego curl
kubectl --kubeconfig=./k3s-kubeconfig version --short


# 1) Pełna wersja (client + server)
kubectl --kubeconfig=./k3s-kubeconfig version

# 2) Wersja server w formacie JSON (może być potrzebne -o zamiast --output)
kubectl --kubeconfig=./k3s-kubeconfig version -o json

# 3) Wyciągnij tylko gitVersion z JSON
kubectl --kubeconfig=./k3s-kubeconfig version -o json | jq -r '.serverVersion.gitVersion'

# 4) Alternatywa bez kubectl — bezpośrednie zapytanie API używając certyfikatów wyekstrahowanych z `k3s-kubeconfig`
curl --cacert ca.crt --cert client.crt --key client.key https://127.0.0.1:6443/version

