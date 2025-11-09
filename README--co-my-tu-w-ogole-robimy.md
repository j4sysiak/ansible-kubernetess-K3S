Krótko: wyjaśnię po polsku „co my tu w ogóle robimy” — najpierw plan, potem krótki opis każdego komponentu i roli w repo,
przyczyny najważniejszych błędów które widziałeś i na końcu konkretne, proste polecenia które możesz wpisać, żeby zobaczyć stan i kontynuować.
Plan (co zrobię dalej)

Szybka lista kroków/efektów jakie realizujesz (checklista).
Wyjaśnienie architektury: Ansible → Docker container → k3s → Helm → Ingress → aplikacja.

Krótkie omówienie najważniejszych problemów, które napotkałeś i dlaczego się pojawiły (ssh/known_hosts, systemd, overlayfs, DNS).
Konkretne polecenia do sprawdzenia stanu i dalsze proste kroki (deploy/test/cleanup).
Checklista — co robimy w tym projekcie

1. Uruchamiamy kontener Docker, który działa jako „maszyna” dla k3s (w kontenerze działa SSH i k3s).
2. Automatyzujemy instalację k3s w tym kontenerze przy pomocy Ansible (rola k3s_master).
3. Kopiujemy/konfigurujemy kubeconfig z klastra (plik k3s-kubeconfig), żeby kubectl/helm na hoście mogły się łączyć.
4. Instalujemy Helm i za jego pomocą wdrażamy kontroler ingress-nginx (rola deploy_app).
5. Wdrażamy prostą aplikację „hello” i tworzymy Ingress żeby trafić na usługę HTTP przez kontroler Ingress.

Co robi każdy „element” (konceptualnie)

Ansible (playbook + role): narzędzie do automatyzacji. 
Playbooki wykonują zadania na hostach (tutaj: na kontenerze lub lokalnie). 
Role grupują zadania (np. k3s_master, deploy_app, hello_kubernetes_app).

Docker container: tutaj działa „maszyna” k3s — musisz wystartować kontener z flagami (np. --privileged, -v /dev:/dev, --cgroupns=host) żeby k3s/containerd mogły działać poprawnie.
k3s: lekka dystrybucja Kubernetes (serwer + węzeł) — instaluje binarkę i uruchamia procesy, tworzy kubeconfig w /etc/rancher/k3s/k3s.yaml.

containerd + snapshotter: k3s używa containerd; domyślny snapshotter overlayfs może nie działać w kontenerze (brak wsparcia kernel/namespace), 
       więc rozwiązaniem jest fuse-overlayfs lub native.

kubeconfig (k3s-kubeconfig): plik z certyfikatami i adresem API; kopiujesz go na host i ustawiasz KUBECONFIG 
                        lub przekazujesz --kubeconfig do kubectl/helm.

Helm: menedżer chartów (aplikacji K8s). 
Rola deploy_app wykonuje helm install/upgrade aby zainstalować ingress-nginx.

Ingress controller (ingress-nginx): komponent, który czyta zasoby Ingress i kieruje ruch HTTP/HTTPS do serwisów w klastrze. 
Ingress to reguły L7 (host/path -> Service:port).

Service typu LoadBalancer w twoim Docker-klastrze otrzymał EXTERNAL-IP = adres dockerowego mostka (np. 172.17.0.2), 
    co oznacza: dostępny z hosta i innych kontenerów, ale nie z internetu bez dodatkowego rozwiązania (MetalLB lub przekierowania portów).

Gdzie w repo to jest zrobione (mapowanie plików)
roles/k3s_master/tasks/main.yml — instaluje k3s, ustawia snapshotter w /etc/rancher/k3s/config.yaml, 
                                  uruchamia k3s (czasem bez systemd), 
                                       czeka na pojawienie się /etc/rancher/k3s/k3s.yaml i kopiuje kubeconfig.

deploy_helm_chart.yml — playbook uruchamiający rolę deploy_app. Poprawiliśmy w nim kubeconfig_path.
roles/deploy_app/tasks/main.yml — wywołuje helm upgrade --install ... by zainstalować chart (ingress-nginx).

roles/hello_kubernetes_app/files/ — deployment/ingress manifests dla przykładowej aplikacji „Hello world”.

 