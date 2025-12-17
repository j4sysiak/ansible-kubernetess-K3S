Finałowy Boss: GitOps z `ArgoCD`
Skoro "ręczne" zarządzanie (kubectl apply) masz w małym palcu, czas na Ostateczną Metodę Pracy, 
którą stosuje się w Netflixie, Google czy Spotify.

# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART15-Operator/LAB2-ArgoCD-GitOps

Scenariusz dla Szefa:
"Szefie, kubectl apply jest ryzykowne. 
Jak ja pójdę na urlop, a stażysta coś wpisze źle, to położy produkcję. 
Wdrażam GitOps. 
Od teraz nikt nie dotyka klastra ręcznie. 
Zmieniamy pliki w Gicie, a robot `ArgoCD` sam pilnuje, żeby klaster był zsynchronizowany."
Co zrobimy?
Zainstalujemy `ArgoCD`.
Podłączymy go do publicznego repozytorium na GitHubie.
Zmienimy coś w kodzie na GitHubie i zobaczymy, jak klaster sam się naprawia/aktualizuje.

Krok 1: 
-------
Instalacja `ArgoCD` (przez `Helm`)
`ArgoCD` to potężna kobyła, ale instalacja jest prosta.

Dodaj repozytorium
# helm repo add argo https://argoproj.github.io/argo-helm
    "argo" has been added to your repositories

# helm repo update
    Hang tight while we grab the latest from your chart repositories...
    ...Successfully got an update from the "cnpg" chart repository
    ...Successfully got an update from the "ingress-nginx" chart repository
    ...Successfully got an update from the "argo" chart repository
 
Zainstaluj.
(Ustawiamy LoadBalancer, żeby łatwo wejść przez IP kontenera, ale `ArgoCD` ma własne certyfikaty, 
           więc przeglądarka będzie krzyczeć - to normalne).

# helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=LoadBalancer
  
    Release "argocd" does not exist. Installing it now.
     Error: failed pre-install: 1 error occurred:
     * timed out waiting for the condition
     * 

        F U C K !  timed out ! ! !

sprzatanie:
# kubectl get pods -n argocd
No resources found in argocd namespace.

Skoro jest pusto (No resources found), to znaczy, że mamy czystą kartę i żadne stare "śmieci" nie będą blokować instalacji.
Możemy od razu zastosować metodę "Pancerną" (bez Helma), która jest odporna na timeouty.
Wykonaj te kroki w terminalu:
Krok 1: Instalacja (Manifest YAML)
Wklej tę komendę. Ona pobierze oficjalną definicję ArgoCD i wdroży ją do klastra:
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Czekanie na start
Teraz Kubernetes będzie pobierał obrazy. Sprawdzaj status tą komendą:
Musisz poczekać, aż wszystkie 5-6 podów (np. argocd-server, argocd-repo-server, argocd-dex-server itp.) 
będzie miało status Running. Może to potrwać 2-3 minuty.

# kubectl get pods -n argocd
    NAME                                                READY   STATUS            RESTARTS   AGE
    argocd-application-controller-0                     1/1     Running           0          38s
    argocd-applicationset-controller-5c9b95498b-zdddk   1/1     Running           0          38s
    argocd-dex-server-cccc8f49d-q7cnx                   0/1     Running           0          38s
    argocd-notifications-controller-576c4d5559-lbrw9    1/1     Running           0          38s
    argocd-redis-684497594f-pzlb6                       0/1     Running           0          38s
    argocd-repo-server-6c857c79ff-mbkl7                 1/1     Running           0          38s
    argocd-server-9dc66fd74-dgkkf                       1/1     Running           0          38s

Wystawienie na świat (LoadBalancer)
Domyślnie `ArgoCD` instaluje się jako serwis wewnętrzny. 
Zmieńmy go na dostępny z zewnątrz (LoadBalancer):
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    service/argocd-server patched

Sprawdź, czy zmiana się przyjęła:
# kubectl get svc -n argocd
    NAME                                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    argocd-applicationset-controller          ClusterIP      10.43.187.38    <none>        7000/TCP,8080/TCP            4m35s
    argocd-dex-server                         ClusterIP      10.43.204.61    <none>        5556/TCP,5557/TCP,5558/TCP   4m35s
    argocd-metrics                            ClusterIP      10.43.51.16     <none>        8082/TCP                     4m35s
    argocd-notifications-controller-metrics   ClusterIP      10.43.98.177    <none>        9001/TCP                     4m35s
    argocd-redis                              ClusterIP      10.43.131.197   <none>        6379/TCP                     4m35s
    argocd-repo-server                        ClusterIP      10.43.225.144   <none>        8081/TCP,8084/TCP            4m35s
    argocd-server                             LoadBalancer   10.43.169.101   <pending>     80:30792/TCP,443:30850/TCP   4m35s
    argocd-server-metrics                     ClusterIP      10.43.195.101   <none>        8083/TCP                     4m35s

Krok 2: 
-------
Zdobycie hasła
ArgoCD generuje losowe hasło dla użytkownika admin. Musimy je wydobyć.
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    W4asX6qsw7OKJx3H
(Skopiuj to hasło!)

Znajdź adres IP:
# kubectl get svc -n argocd argocd-server
    NAME            TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    argocd-server   LoadBalancer   10.43.169.101   <pending>     80:30792/TCP,443:30850/TCP   6m21s

(Jeśli zobaczysz IP 172.17.0.2, to wchodź przez ten adres lub https://localhost jeśli masz mapowanie portu 443).


Krok 3: 
-------
Wejście do Dashboardu
Sprawdź, czy serwis wstał i ma IP:
# kubectl get svc -n argocd
    NAME                                      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
    argocd-applicationset-controller          ClusterIP      10.43.187.38    <none>        7000/TCP,8080/TCP            6m47s
    argocd-dex-server                         ClusterIP      10.43.204.61    <none>        5556/TCP,5557/TCP,5558/TCP   6m47s
    argocd-metrics                            ClusterIP      10.43.51.16     <none>        8082/TCP                     6m47s
    argocd-notifications-controller-metrics   ClusterIP      10.43.98.177    <none>        9001/TCP                     6m47s
    argocd-redis                              ClusterIP      10.43.131.197   <none>        6379/TCP                     6m47s
    argocd-repo-server                        ClusterIP      10.43.225.144   <none>        8081/TCP,8084/TCP            6m47s
    argocd-server                             LoadBalancer   10.43.169.101   <pending>     80:30792/TCP,443:30850/TCP   6m47s
    argocd-server-metrics                     ClusterIP      10.43.195.101   <none>        8083/TCP                     6m47s

Jeśli argocd-server ma typ LoadBalancer i IP 172.17.0.2 (lub podobne), wchodź w przeglądarce:
👉 https://172.17.0.2 (lub https://localhost jeśli Docker mapuje 443, ale tu może być konflikt z Nginxem, 
więc bezpieczniej użyć IP kontenera lub Port Forward).
Metoda pewna (Port Forward):
Jeśli masz konflikt portów (bo Nginx Ingress już zajmuje 80/443), użyj tunelu:
# kubectl port-forward svc/argocd-server -n argocd 8080:443
  
Wejdź w przeglądarce na:
👉 https://localhost:8080

dziala:
https://localhost:8080/login?return_url=https%3A%2F%2Flocalhost%3A8080%2Fapplications


1. Zaloguj się jako admin i użyj hasła z Kroku 2.
2. Zobaczysz piękny interfejs graficzny.

Zalogowalem sie do ArgoCD!

Krok 4: 
-------
Wdrożenie aplikacji z GitHuba (Magia)
Nie będziemy pisać YAML-i u siebie. 
Weźmiemy gotową aplikację demo od twórców `ArgoCD`.

W interfejsie ArgoCD kliknij + NEW APP (lewy górny róg).
Wypełnij formularz (to jest "trudne", więc uważaj):
Application Name: guestbook
Project: default
SYNC POLICY: Automatic (zaznacz też "Prune Resources" i "Self Heal" - to sprawi, że Argo będzie agresywnie pilnować porządku).
SOURCE (Repository URL): https://github.com/argoproj/argocd-example-apps.git
Path: guestbook
DESTINATION (Cluster URL): https://kubernetes.default.svc (to oznacza "ten klaster, w którym jestem").
Namespace: default

Kliknij CREATE (na samej górze).

Krok 5: 
-------
Obserwacja
Zobaczysz kafelek "guestbook".
Kliknij go.
Zobaczysz na żywo, jak `ArgoCD` rysuje "drzewo" aplikacji (Service, Deployment, ReplicaSet, Pod) i zapala je na zielono.
To jest właśnie GitOps. 
Nie wpisałeś ani jednej komendy kubectl apply. 
`ArgoCD` przeczytało kod z GitHuba i wdrożyło go w Twoim klastrze.

Zadanie dla Ciebie (Test Samoleczenia)
`ArgoCD` ma włączone "Self Heal" (Samoleczenie).
Wróć do terminala.
Znajdź deployment guestbooka: 
# kubectl get deployment
        NAME               READY   UP-TO-DATE   AVAILABLE   AGE
        [...]
    --->guestbook-ui       0/1     1            0           4m42s
        [...]


ZABIJ GO RĘCZNIE! (Sabotaż):
# kubectl delete deployment guestbook-ui
    deployment.apps "guestbook-ui" deleted from default namespace

Szybko przełącz się na zakładkę przeglądarki z `ArgoCD`.

Co zobaczysz?

`ArgoCD` natychmiast zaświeci się na żółto ("Out of Sync"), 
zauważy, że brakuje Deploymentu (który jest w Gicie), 
i natychmiast go odtworzy.

# kubectl get deployment
        NAME               READY   UP-TO-DATE   AVAILABLE   AGE
        [...]
    --->guestbook-ui       0/1     1            0           100s  <-  po restartcie!!
        [...]



Jeśli to zobaczysz – zrozumiesz, dlaczego firmy kochają to narzędzie. 
Klaster pilnuje się sam.
Daj znać, jak poszło z "Magikiem" ArgoCD!

Wszystko OK!!
















