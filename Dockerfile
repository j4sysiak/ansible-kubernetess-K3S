FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y curl openssh-server fuse-overlayfs && \
    mkdir /var/run/sshd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
