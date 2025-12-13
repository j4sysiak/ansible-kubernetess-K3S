
# cd ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB2-Logika-Warunkowa

Scenariusz:
-----------
Szef mówi: 
"Słuchaj, na produkcji potrzebujemy Ingressa, żeby klienci wchodzili.
Ale na środowisku testowym (dev) szkoda nam zasobów, tam wystarczy zwykły Pod. 
Zrób tak, żeby ten sam Chart potrafił tworzyć Ingressa albo nie, w zależności od jednej flagi."


1. Edytuj values.yaml
# vi ~/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB1--Helm-Chart--Hello_World/moj-nginx/values.yaml
   Dodaj nową sekcję na końcu pliku:
```
ingress:
   enabled: true  # <--- To będzie nasz przełącznik
   host: "moj-nginx.local"
```

2. Stwórz szablon templates/ingress.yaml
# vi ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB1--Helm-Chart--Hello_World/moj-nginx/templates/ingress.yaml
   Użyjemy instrukcji warunkowej {{- if .Values.ingress.enabled }}.


3. Testowanie (Dry Run)
   Nie musisz tego wdrażać, żeby sprawdzić, czy działa. 
   Użyjemy trybu --dry-run, który tylko "udaje" instalację i pokazuje wygenerowany YAML.
   Test 1 (Włączony):
# helm upgrade --install test-helma ./moj-nginx --dry-run
   Powinieneś zobaczyć w wynikach kod Ingressa.

   Test 2 (Wyłączony):
# helm upgrade --install test-helma ./moj-nginx --set ingress.enabled=false --dry-run
W wynikach NIE powinno być śladu po Ingressie.
Wniosek: Twój Chart jest teraz inteligentny. 
Reaguje na konfigurację.










