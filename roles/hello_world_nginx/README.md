
# ansible-playbook -i inventory/hosts.ini destroy_hello_world_nginx.yml
# ansible-playbook -i inventory/hosts.ini deploy_hello_world_nginx.yml
 

Opis, co my tu robimy:
----------------------
Rola `hello_world_nginx` wykonuje proste wdrożenie aplikacji nginx i wystawienie jej w klastrze — krótko:
 - Tworzy (lub zapewnia) namespace `hello-world`.
 - Aplikuje manifesty: 
    1. Deployment (prosty serwer, readinessProbe, zasoby)
    2. Service typu NodePort (eksponuje aplikację poza klastrem).
 - Czeka na rollout Deploymentu (zadanie typu Wait for deployment rollout).
 - Zawiera instrukcje debugowania i obejścia problemów z dostępem do NodePort (np. kubectl port-forward).

Szybkie komendy debugowe (użyj swojego kubeconfig):  (poczekaj chwilę po wdrożeniu, aż pody będą w stanie Ready)
# kubectl --kubeconfig=./k3s-kubeconfig get all -n hello-world
    NAME                               READY   STATUS    RESTARTS   AGE
    pod/hello-world-7f86d974d5-xvbm8   1/1     Running   0          6m51s

    NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    service/hello-world   NodePort   10.43.41.170   <none>        80:30080/TCP   6m51s

    NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/hello-world   1/1     1            1           6m51s

    NAME                                     DESIRED   CURRENT   READY   AGE
    replicaset.apps/hello-world-7f86d974d5   1         1         1       6m51s

# kubectl --kubeconfig=./k3s-kubeconfig get svc -n hello-world hello-world
    NAME          TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
    hello-world   NodePort   10.43.41.170   <none>        80:30080/TCP   6m16s

# kubectl --kubeconfig=./k3s-kubeconfig get deployments -n hello-world
    NAME          READY   UP-TO-DATE   AVAILABLE   AGE
    hello-world   1/1     1            1           7m54s

potem sprawdź pody:
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world get pods -o wide
    NAME                           READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    hello-world-7f86d974d5-xvbm8   1/1     Running   0          8m24s   10.42.0.10   k3s-master   <none>           <none>

# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world describe deployment hello-world
  [...]

# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world get events --sort-by=.metadata.creationTimestamp
    LAST SEEN   TYPE     REASON              OBJECT                              MESSAGE
    9m19s       Normal   Scheduled           pod/hello-world-7f86d974d5-xvbm8    Successfully assigned hello-world/hello-world-7f86d974d5-xvbm8 to k3s-master
    9m20s       Normal   SuccessfulCreate    replicaset/hello-world-7f86d974d5   Created pod: hello-world-7f86d974d5-xvbm8
    9m20s       Normal   ScalingReplicaSet   deployment/hello-world              Scaled up replica set hello-world-7f86d974d5 from 0 to 1
    9m19s       Normal   Pulling             pod/hello-world-7f86d974d5-xvbm8    Pulling image "nginx:stable-alpine"
    5m31s       Normal   Pulled              pod/hello-world-7f86d974d5-xvbm8    Successfully pulled image "nginx:stable-alpine" in 4m9.867s (4m9.867s including waiting). Image size: 21015643 bytes.
    5m31s       Normal   Created             pod/hello-world-7f86d974d5-xvbm8    Created container: nginx
    5m30s       Normal   Started             pod/hello-world-7f86d974d5-xvbm8    Started container nginx

# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world logs <pod-name> -c <container-name>
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world logs hello-world-7f86d974d5-xvbm8 -c hello-world

Port‑forward (szybkie obejście): 
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world port-forward svc/hello-world 8080:80 &

teraz mozna odpalić w przeglądarce lub curl:
# curl -v http://localhost:8080/ | head -n 10
# http://localhost:8080/         powinna sie pojawić stronka ---->   "Welcome to nginx!"


Typowe problemy:
NodePort niedostępny, gdy k3s działa w kontenerze — rozwiązania: kubectl port-forward, uruchomić k3s z --net=host lub zainstalować MetalLB.
Niezgodne nazwy/labelki lub błędy readinessProbe powodują, że rollout nie dochodzi do stanu Ready — sprawdź describe i logs.


////////////////////////////////// rozwiązanie problemu /////////////////////////////////////
Najprawdopodobniej NodePort nie jest osiągalny z Twojego hosta (adres 172.17.0.2 to IP w wewnętrznej sieci kontenera/klastra). 
Szybkie kroki debugowe i obejścia:
Sprawdź jakie adresy mają węzły i czy nodePort jest poprawny.
Zweryfikuj dostępność serwisu z poziomu klastra (curl z podu).
Jeśli k3s działa w kontenerze/VM, użyj kubectl port-forward albo zmapuj porty na hoście.


opis deploymentu
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world describe deployment hello-world
[...]

pokaż pody i status
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world get pods -o wide
    NAME                           READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
    hello-world-7f86d974d5-wxc6f   1/1     Running   0          6m22s   10.42.0.11   k3s-master   <none>           <none>

opis konkretnego poda (zastąp nazwą z poprzedniego)
kubectl --kubeconfig=./k3s-kubeconfig -n hello-world describe pod <pod-name>
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world describe pod hello-world-7f86d974d5-wxc6f
[...]

logi poda (wszystkie kontenery)
kubectl --kubeconfig=./k3s-kubeconfig -n hello-world logs <pod-name> --all-containers
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world logs hello-world-7f86d974d5-wxc6f --all-containers
[...]

zdarzenia w namespace
# kubectl --kubeconfig=./k3s-kubeconfig -n hello-world get events --sort-by='.metadata.creationTimestamp'
     LAST SEEN   TYPE     REASON              OBJECT                              MESSAGE
     9m39s       Normal   Scheduled           pod/hello-world-7f86d974d5-wxc6f    Successfully assigned hello-world/hello-world-7f86d974d5-wxc6f to k3s-master
     9m39s       Normal   SuccessfulCreate    replicaset/hello-world-7f86d974d5   Created pod: hello-world-7f86d974d5-wxc6f
     9m39s       Normal   ScalingReplicaSet   deployment/hello-world              Scaled up replica set hello-world-7f86d974d5 from 0 to 1
     9m38s       Normal   Pulled              pod/hello-world-7f86d974d5-wxc6f    Container image "nginx:stable-alpine" already present on machine
     9m38s       Normal   Created             pod/hello-world-7f86d974d5-wxc6f    Created container: nginx
     9m38s       Normal   Started             pod/hello-world-7f86d974d5-wxc6f    Started container nginx

pokaż węzły (nodes) i ich IP
# kubectl --kubeconfig=./k3s-kubeconfig get nodes -o wide
    NAME         STATUS   ROLES           AGE    VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION                     CONTAINER-RUNTIME
    k3s-master   Ready    control-plane   111m   v1.34.1+k3s1   172.17.0.2    <none>        Ubuntu 22.04.5 LTS   6.6.87.2-microsoft-standard-WSL2   containerd://2.1.4-k3s2

pokaż service (nodePort)
# kubectl --kubeconfig=./k3s-kubeconfig get svc -n hello-world hello-world -o yaml
[...]

pokaż endpoints
# kubectl --kubeconfig=./k3s-kubeconfig get endpoints -n hello-world
    NAME          ENDPOINTS       AGE
    hello-world   10.42.0.11:80   11m
 

# test z wnętrza klastra (uruchomi kontener z curl i spróbuje się połączyć z serwisem DNS)
kubectl --kubeconfig=./k3s-kubeconfig run --rm -i --tty curltest --image=curlimages/curl --restart=Never -- sh -c "curl -sS http://hello-world:80 || echo 'cluster curl failed'"

# jeśli k3s działa jako kontener -> sprawdź kontenery i mapowanie portów
docker ps | grep k3s
# (jeśli widać kontener, inspect sprawdzi porty)
# docker inspect <container_id>



---> to pomoglo (port-forward):
# szybkie obejście przez port-forward (udostępni serwis lokalnie na porcie 8080)
kubectl --kubeconfig=./k3s-kubeconfig -n hello-world port-forward svc/hello-world 8080:80 &

dziala: curl -v http://localhost:8080/ | head -n 10
dziala: http://localhost:8080/


////////////////  wyjaśnienie  ///////////////////////
W środowisku Docker, gdy uruchamiasz k3s w kontenerze, usługi typu NodePort mogą nie być bezpośrednio dostępne z hosta z powodu 
izolacji sieciowej kontenerów. 
Adres IP 172.17.0.2 to adres mostka Docker, który jest używany wewnętrznie przez kontenery, ale nie jest routowalny z zewnątrz.
Aby uzyskać dostęp do usługi NodePort z hosta, masz kilka opcji:
1. Użyj kubectl port-forward: To narzędzie pozwala na przekierowanie portu z serwisu w klastrze Kubernetes na lokalny port na hoście. 
   W ten sposób możesz uzyskać dostęp do usługi bezpośrednio z hosta.


2. Mapowanie portów w Dockerze: Jeśli uruchamiasz k3s 

3. Wykorzystaj MetalLB lub inny load balancer: W środowiskach bare-metal lub lokalnych możesz zainstalować MetalLB, 
     który pozwala na przydzielanie rzeczywistych adresów IP do usług typu LoadBalancer w Kubernetes.

4. Sprawdź konfigurację sieci: Upewnij się, że sieć kontenera k3s pozwala na dostęp do portów NodePort z hosta. 
   Czasami może być konieczne dostosowanie ustawień sieciowych Dockera lub użycie trybu sieci hosta (--network host) podczas uruchamiania kontenera k3s.

5. Sprawdź zapory sieciowe: Upewnij się, że zapory sieciowe na hoście i w kontenerze nie blokują ruchu na portach NodePort.
6. Sprawdź konfigurację k3s: Upewnij się, że k3s jest poprawnie skonfigurowany do obsługi usług NodePort i że nie ma żadnych ograniczeń dotyczących dostępu z zewnątrz.
7. Debugowanie z poziomu klastra: Uruchom pod tymczasowy kontener w klastrze i spróbuj połączyć się z usługą NodePort z wnętrza klastra, aby upewnić się, że usługa działa poprawnie.
8. Sprawdź logi: Przejrzyj logi k3s i kontrolera sieciowego, aby zobaczyć, czy nie ma żadnych błędów związanych z usługami NodePort.
9. Użyj narzędzi do monitorowania sieci: Narzędzia takie jak tcpdump lub wireshark mogą pomóc w analizie ruchu sieciowego i zidentyfikowaniu problemów z dostępem do usług NodePort.
10. Skonsultuj dokumentację: Sprawdź dokumentację k3s i Dockera, aby upewnić się, że nie ma specyficznych wymagań lub ograniczeń dotyczących korzystania z usług NodePort w środowisku kontenerowym.
11. Skontaktuj się ze społecznością: Jeśli nadal masz problemy, rozważ skontaktowanie się ze społecznością k3s lub Dockera, gdzie możesz uzyskać pomoc od innych użytkowników, którzy mogli napotkać podobne problemy.
12. Rozważ użycie innego typu usługi: Jeśli NodePort nadal sprawia problemy, możesz rozważyć użycie innego typu usługi, takiego jak LoadBalancer (z MetalLB) lub ClusterIP z port-forwardingiem, w zależności od Twoich potrzeb i środowiska.
13. Sprawdź wersje oprogramowania: Upewnij się, że używasz kompatybilnych wersji k3s, Dockera i innych komponentów sieciowych, ponieważ niektóre problemy mogą wynikać z niezgodności wersji.
14. Testuj w różnych środowiskach: Jeśli to możliwe, spróbuj uruchomić k3s w innym środowisku (np. na maszynie wirtualnej lub innym hoście), aby sprawdzić, czy problem z dostępem do NodePort jest specyficzny dla Twojego obecnego środowiska Docker.


Wyjaśnienie krótkie: 172.17.0.2 to IP węzła w sieci kontenera/WSL2 — NodePort nie jest dostępny z Twojego hosta w tej konfiguracji. 
kubectl port-forward działa, bo mapuje port na localhost. 
Poniżej krótkie, praktyczne opcje i komendy.
Szybki test z wnętrza klastra (poprawna przestrzeń nazw):
Port‑forward (szybkie obejście, działa lokalnie na localhost).
Jeśli chcesz trwałe wystawienie na hosta — uruchomić k3s z --net=host lub zainstalować MetalLB / uruchomić k3s natywnie w WSL2 host‑network.
Przykładowe polecenia:

# 1) Test z wnętrza klastra (w namespace hello-world, użyj service name lub ClusterIP)
kubectl --kubeconfig=./k3s-kubeconfig run --rm -i --tty curltest --image=curlimages/curl --restart=Never -n hello-world -- sh -c "curl -sS http://hello-world:80 || echo 'cluster curl failed'"

# 2) Port-forward (uruchom w tle) i test lokalny
kubectl --kubeconfig=./k3s-kubeconfig -n hello-world port-forward svc/hello-world 8080:80 &
curl -v http://localhost:8080/ | head -n 10

# 3) Diagnoza: sprawdź czy k3s działa jako kontener (jeśli tak, NodePort może być izolowany)
docker ps | grep k3s || podman ps | grep k3s
# jeżeli k3s jest kontenerem, sprawdź inspect:
docker inspect <k3s_container_id>

# 4) Opcja: uruchomić k3s z host network (jeśli akceptowalne) — przykład przy ponownym uruchomieniu kontenera:
# (tylko gdy k3s uruchamiasz w kontenerze; to działa jeśli chcesz, by NodePort był dostępny na hoście)
docker stop <k3s_container_id>
docker rm <k3s_container_id>
docker run --name k3s --privileged --net=host ...   # parametry instalacji k3s zależne od Twojej konfiguracji

# 5) Alternatywa: użyj MetalLB lub loadbalancera, jeśli chcesz nadać klastrowi "zewnętrzne" IP dostępne z hosta
# (instalacja MetalLB to osobny krok)
