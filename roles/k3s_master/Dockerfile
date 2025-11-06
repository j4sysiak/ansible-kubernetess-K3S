# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server sudo ca-certificates curl \
 && mkdir -p /var/run/sshd \
 && echo 'root:test' | chpasswd \
 && sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# usuń CRLF i nadaj prawa wykonywania
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
 && chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 22 80 6443

ENTRYPOINT ["/bin/bash","/usr/local/bin/docker-entrypoint.sh"]
