# chmod +x docker-entrypoint.sh
# chmod +x Dockerfile

# docker build -t k3s-master-image .

# run it in WSL terminal:
docker run -d \
--name k3s-master \
--hostname k3s-master \
--privileged -v /dev:/dev \
--cgroupns=host \
-p 6443:6443 \
-p 8081:80 \
-p 2222:22 \
k3s-master-image


Kroki diagnostyczne:
# docker ps -a
# docker logs k3s-master
# docker inspect k3s-master
# docker inspect -f '{{.State.ExitCode}}' k3s-master