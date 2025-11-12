---
Krótko:
- Rola tworzy namespace `dhcp`, ConfigMap z `dhcpd.conf` i DaemonSet który uruchamia serwer DHCP na każdym węźle.
- Wymagane: hostNetwork i dostęp do UDP portu 67, kontener uruchomiony z uprawnieniami (\`privileged\`) — ryzyko dla sieci hosta.
- Testuj w izolowanym środowisku.
- Zmodyfikuj zmienne w \`roles/dhcp_server/vars/main.yml\` przed uruchomieniem.

Działanie: ta rola tworzy ConfigMap i DaemonSet przez wywołania kubectl (użyj poprawnej ścieżki w zmiennej kubeconfig).