# jesteśmy w katalogu roli k3s_master
/home/jacek/dev/ansible-kubernetess-K3S/roles/k3s_master

# cd roles/k3s_master

# chmod +x docker-entrypoint.sh
# chmod +x Dockerfile

to zbuduje obraz Dockera o nazwie k3s-master-image (korzystając z Dockerfile w tym katalogu)
# docker build -t k3s-master-image .

to uruchomi kontener Dockera o nazwie k3s-master z obrazem k3s-master-image
ale najpierw, jezeli mamy stary kontener o tej nazwie, to go stopujemy i usuwamy:
# docker stop k3s-master || true
# docker rm -f k3s-master || true

run it in WSL terminal:
```
docker run -d \
--name k3s-master \
--hostname k3s-master \
--privileged -v /dev:/dev \
--cgroupns=host \
-p 6443:6443 \
-p 8081:80 \
-p 2222:22 \
k3s-master-image
```


Kroki diagnostyczne:
# docker ps      /(działające)
# docker ps -a   /(ukryte - nie działające)
# docker logs k3s-master
# docker inspect k3s-master
# docker inspect -f '{{.State.ExitCode}}' k3s-master
0

# docker exec -it k3s-master bash