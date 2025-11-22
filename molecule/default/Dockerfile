FROM rockylinux:9
ENV container docker
RUN dnf -y update && dnf -y install systemd passwd sudo which procps iproute && dnf -y clean all
VOLUME ["/sys/fs/cgroup"]
STOPSIGNAL SIGRTMIN+3
CMD ["/usr/sbin/init"]
