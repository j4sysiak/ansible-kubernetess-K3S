LAB 3: 
------

Pętle (range) - Generowanie Listy

Scenariusz: 
Szef mówi: 
"Potrzebujemy przekazać do aplikacji listę zmiennych środowiskowych (ENV). 
Ale ta lista ciągle się zmienia. 
Raz jest 5 zmiennych, raz 20. 
Nie chcę za każdym razem edytować pliku deployment.yaml."

1. Edytuj values.yaml
# vi ~/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB1--Helm-Chart--Hello_World/moj-nginx/values.yaml

2. Stwórz szablon templates/deployment.yaml
# vi ~/dev/ansible-kubernetess-K3S/szkolenie-k8s/PART14-Helm-Chart/LAB1--Helm-Chart--Hello_World/moj-nginx/templates/deployment.yaml
(Uprościmy to do samego fragmentu z containers, żebyś widział mechanizm).

3. Testowanie:
# helm upgrade --install test-helma ./moj-nginx --dry-run
   Zobaczysz, że Helm "przejechał" przez listę w values.yaml i wygenerował piękną listę env w pliku YAML.



























