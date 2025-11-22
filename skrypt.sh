#!/usr/bin/env bash
# language: bash
set -euo pipefail

ROLE="${1:-dhcp_server_locally}"
BASE="roles/${ROLE}"
MOLECULE_DIR="molecule/default"

echo "Tworzę strukturę roli: ${BASE}"

# Katalogi roli + molecule
mkdir -p \
  "${BASE}"/{tasks,defaults,handlers,meta,templates,files,vars} \
  "${MOLECULE_DIR}"

# Pliki podstawowe
cat > "${BASE}/defaults/main.yml" <<'EOF'
---
dhcp_package: dhcp-server
dhcp_service: dhcpd
dhcp_config_path: /etc/dhcp/dhcpd.conf
dhcp_leases_dir: /var/lib/dhcp
dhcp_subnet: "172.17.10.0"
dhcp_netmask: "255.255.0.0"
dhcp_range_start: "172.17.10.100"
dhcp_range_end: "172.17.10.200"
dhcp_routers: "172.17.0.1"
dhcp_dns: "8.8.8.8, 8.8.4.4"
EOF

cat > "${BASE}/tasks/main.yml" <<'EOF'
---
- name: Install DHCP package
  ansible.builtin.package:
    name: "{{ dhcp_package }}"
    state: present
  become: true

- name: Ensure leases dir exists
  ansible.builtin.file:
    path: "{{ dhcp_leases_dir }}"
    state: directory
    owner: root
    group: root
    mode: '0755'
  become: true
EOF

cat > "${BASE}/meta/main.yml" <<'EOF'
galaxy_info:
  author: j4sysiak
  description: DHCP server role (RHEL9-like)
  license: MIT
  min_ansible_version: 2.14
dependencies: []
EOF

cat > "${BASE}/templates/dhcpd.conf.j2" <<'EOF'
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet {{ dhcp_subnet }} netmask {{ dhcp_netmask }} {
  range {{ dhcp_range_start }} {{ dhcp_range_end }};
  option routers {{ dhcp_routers }};
  option domain-name-servers {{ dhcp_dns }};
}
EOF

cat > "${BASE}/README.md" <<EOF
Role: ${ROLE}
Szkielet roli DHCP — pliki: defaults, tasks, templates, meta.
EOF

# Molecule files (minimal)
cat > "${MOLECULE_DIR}/molecule.yml" <<'EOF'
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: molecule_local/dhcp-test:latest
    pre_build_image: false
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
provisioner:
  name: ansible
verifier:
  name: ansible
EOF

cat > "${MOLECULE_DIR}/converge.yml" <<'EOF'
---
- name: Converge
  hosts: all
  become: true
  roles:
    - role: ${ROLE}
EOF

cat > "${MOLECULE_DIR}/verify.yml" <<'EOF'
---
- name: Verify
  hosts: all
  gather_facts: false
  tasks:
    - name: Wait for systemd
      ansible.builtin.wait_for:
        path: /run/systemd/system
        timeout: 60
EOF

cat > "${MOLECULE_DIR}/Dockerfile" <<'EOF'
FROM rockylinux:9
ENV container docker
RUN dnf -y update && dnf -y install systemd passwd sudo which procps iproute && dnf -y clean all
VOLUME ["/sys/fs/cgroup"]
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
EOF

echo "Utworzono role i molecule: ${BASE} oraz ${MOLECULE_DIR}"
echo "Możesz teraz dopisać taski/templaty i uruchomić: molecule create && molecule converge && molecule verify"

