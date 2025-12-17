Finałowy Boss: GitOps z `ArgoCD`
Skoro "ręczne" zarządzanie (kubectl apply) masz w małym palcu, czas na Ostateczną Metodę Pracy, 
którą stosuje się w Netflixie, Google czy Spotify.

# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART15-Operator/LAB2-ArgoCD-Operator

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

        F U C K !  timed


Krok 2: 
-------
Zdobycie hasła
ArgoCD generuje losowe hasło dla użytkownika admin. Musimy je wydobyć.
# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(Skopiuj to hasło!)

Krok 3: 
-------
Wejście do Dashboardu
Sprawdź, czy serwis wstał i ma IP:
# kubectl get svc -n argocd


Jeśli argocd-server ma typ LoadBalancer i IP 172.17.0.2 (lub podobne), wchodź w przeglądarce:
👉 https://172.17.0.2 (lub https://localhost jeśli Docker mapuje 443, ale tu może być konflikt z Nginxem, 
więc bezpieczniej użyć IP kontenera lub Port Forward).
Metoda pewna (Port Forward):
Jeśli masz konflikt portów (bo Nginx Ingress już zajmuje 80/443), użyj tunelu:
# kubectl port-forward svc/argocd-server -n argocd 8080:443
  
Wejdź w przeglądarce na:
👉 https://localhost:8080

1. Zaloguj się jako admin i użyj hasła z Kroku 2.
2. Zobaczysz piękny interfejs graficzny.


Krok 4: 
-------
Wdrożenie aplikacji z GitHuba (Magia)
Nie będziemy pisać YAML-i u siebie. 
Weźmiemy gotową aplikację demo od twórców ArgoCD.
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
ArgoCD przeczytało kod z GitHuba i wdrożyło go w Twoim klastrze.

Zadanie dla Ciebie (Test Samoleczenia)
`ArgoCD` ma włączone "Self Heal" (Samoleczenie).
Wróć do terminala.
Znajdź deployment guestbooka: 
# kubectl get deployment

ZABIJ GO RĘCZNIE! (Sabotaż):
# kubectl delete deployment guestbook-ui

Szybko przełącz się na zakładkę przeglądarki z `ArgoCD`.

Co zobaczysz?

`ArgoCD` natychmiast zaświeci się na żółto ("Out of Sync"), zauważy, że brakuje Deploymentu (który jest w Gicie), 
i natychmiast go odtworzy.

Jeśli to zobaczysz – zrozumiesz, dlaczego firmy kochają to narzędzie. 
Klaster pilnuje się sam.
Daj znać, jak poszło z "Magikiem" ArgoCD!

















