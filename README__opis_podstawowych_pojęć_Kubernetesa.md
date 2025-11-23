Pojęcia w kontekście Kubernetesa:
---------------------------------

1. Ingress (zasób Kubernetes)
   Ingress – reguły routingu HTTP/HTTPS w Kubernetes.

   Jest to obiekt w Kubernetes, który opisuje:
   *z jakiego adresu / domeny / ścieżki*
   *na jaki Service w klastrze* ma iść ruch HTTP/HTTPS.
   Tylko deklaracja reguł routingu, np.:
   https://mojastrona.pl/ → Service frontend (port 80)
   https://api.mojastrona.pl/ → Service backend (port 8080)
   Ingress sam nie przyjmuje ruchu z Internetu – do tego potrzebny jest kontroler.


2. Ingress NGINX (ingress-nginx)
   Ingress NGINX (ingress-nginx) – kontroler, który implementuje te reguły przy pomocy NGINX.

To konkretny Ingress Controller, realizowany jako Deployment w klastrze, używający serwera NGINX jako reverse proxy / load balancer.
Działa tak:
Nasłuchuje obiektów *Ingress* w klastrze.
Generuje z nich konfigurację NGINX.
NGINX przyjmuje ruch z zewnątrz i kieruje go do odpowiednich Service-ów zgodnie z regułami Ingress.
ingress-nginx to projekt (repozytorium GitHub + chart Helma + obrazy Docker), którym instalujesz ten kontroler w klastrze.


3. Chart (Helm Chart)
   Chart – pakiet z definicjami zasobów (w tym kontrolera) dla Helma.
    
Pakiet dla Helma, czyli:
szablony YAML (Deployment, Service, Ingress, ConfigMap, itp.),
domyślne wartości (values.yaml),
metadane (Chart.yaml).
Chart jest:
powtarzalnym sposobem zainstalowania aplikacji (np. ingress-nginx, prometheus, grafana),
parametryzowalny przez values.yaml lub --set.
Przykład: chart ingress-nginx/ingress-nginx zawiera wszystkie manifesty do uruchomienia kontrolera Ingress NGINX.
 
4. Helm
   Helm – menedżer pakietów, który tym chartem zarządza i instaluje go w klastrze.

Narzędzie (klient CLI) i system pakietów dla Kubernetesa.
Służy do:
instalacji chartów: helm install ...,
aktualizacji: helm upgrade ...,
usuwania: helm uninstall ...,
zarządzania repozytoriami chartów: helm repo add, helm repo update.
Helm nie jest częścią ingress-nginx – to osobny program, który:
pobiera chart ingress-nginx,
generuje z niego manifesty,
wysyła je do API serwera K8s.

Dodaj 'Ingress Nginx' z repozytorium GitHuba/ingress-nginx
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

Zaktualizuj listę dostępnych chartów
# helm repo update   

--------------------------------------------------------------------
Najbliższe porównanie:
Chart ≈ pakiet RPM/DEB (pojedynczy pakiet z metadanymi i plikami),
Helm ≈ menedżer pakietów (tak jak dnf/yum dla RPM albo apt dla DEB).
Czyli:
Chart to „rpm/deb dla Kubernetesa” – gotowy pakiet aplikacji dla klastra.
helm install ... działa podobnie jak apt install ... lub dnf install ..., tylko zamiast plików na systemie instaluje zasoby w klastrze (Deployment, Service, Ingress itd.).
 
--------------------------------------------------------------------

# helm install my-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace --kubeconfig=k3s-kubeconfig

Objaśnienie komendy Helm:
---------------------------------------------------------------
helm
- Program CLI, menedżer pakietów (chartów) dla Kubernetesa.
  install
- Akcja: zainstaluj nowy release z charta do klastra.
  my-ingress
- Nazwa releaseʼu Helma.
- Po instalacji wszystkie obiekty w klastrze będą miały etykiety/nazwy zawierające tę nazwę (np. my-ingress-ingress-nginx-controller).
  ingress-nginx/ingress-nginx
- Skąd wziąć chart:
- ingress-nginx (przed slash) – nazwa repozytorium chartów, które wcześniej dodałeś helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
- ingress-nginx (za slash) – nazwa konkretnego charta w tym repo.
- Razem: weź chart ingress-nginx z repo ingress-nginx.
  --namespace ingress-nginx
- Zainstaluj ten release do przestrzeni nazw Kubernetesa ingress-nginx.
- Wszystkie Deploymenty, Serviceʼy itd. trafią do namespace ingress-nginx.
  --create-namespace
- Jeśli namespace ingress-nginx jeszcze nie istnieje, utwórz go automatycznie przed instalacją.
- Dzięki temu nie musisz wcześniej robić kubectl create namespace ingress-nginx.
  --kubeconfig=k3s-kubeconfig
- Użyj konkretnego pliku kubeconfig (k3s-kubeconfig) zamiast domyślnego ~/.kube/config.
- Tym wskazujesz, do którego klastra Kubernetes (tu: K3s) Helm ma się podłączyć i tam zainstalować release.
-----------------------------------------------------------------

CRD w Kubernetes to CustomResourceDefinition.
W skrócie:
Jest to definicja własnego typu zasobu w Kubernetes, rozszerzenie API.
Standardowe typy to np. Pod, Service, Ingress.
Dzięki CRD możesz mieć nowe typy, np. Prometheus, Alertmanager, ServiceMonitor, które tworzy kube-prometheus-stack.
Jak to działa w Twoim przypadku:
Zainstalowanie kube-prometheus-stack przez Helm dodało CRD, np.:
prometheuses.monitoring.coreos.com
alertmanagers.monitoring.coreos.com
servicemonitors.monitoring.coreos.com
Po dodaniu CRD możesz robić:
kubectl get prometheus
kubectl get servicemonitor itd., bo API serwera już zna te typy.
Usuwanie CRD (kubectl delete crd ...) usuwa typ zasobu z klastra (i zwykle wszystkie jego obiekty). U Ciebie wiszące delete crd powodowało problemy z API.

