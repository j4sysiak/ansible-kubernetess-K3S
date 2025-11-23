Lab 6: Secrets (Bezpieczne Hasła)
Scenariusz: 
Aplikacja potrzebuje hasła do bazy danych, ale nie wolno go wpisywać jawnym tekstem w pliku YAML Deploymentu, bo to luka bezpieczeństwa.
Rozwiązanie: Użyjemy Secret. 
Działa jak ConfigMap, ale jest przeznaczony dla danych wrażliwych (i jest kodowany base64).

1. Stwórz Sekret (z linii komend jest bezpieczniej):

# kubectl create secret generic db-passwords --from-literal=DB_PASSWORD=SuperTajneHaslo123
    secret/db-passwords created

2. Sprawdź, czy sekret został utworzony:
# kubectl get secrets
    NAME           TYPE     DATA   AGE
    db-passwords   Opaque   1      4m58s


3. Wdróż poda:
# kubectl apply -f secret-pod.yaml
    pod/secure-pod created

4. Sprawdź Pody (czy Deployment działa):
# kubectl get pods -o wide
        NAME                               READY   STATUS    RESTARTS   AGE     IP           NODE         NOMINATED NODE   READINESS GATES
        my-webapp-5f56d9f4dd-6c8pt         1/1     Running   0          4h53m   10.42.0.23   k3s-master   <none>           <none>
        my-webapp-5f56d9f4dd-sf7p7         1/1     Running   0          4h53m   10.42.0.24   k3s-master   <none>           <none>
        my-webapp-5f56d9f4dd-vfm6b         1/1     Running   0          4h53m   10.42.0.25   k3s-master   <none>           <none>
        my-webapp-custom-c6c5f6f44-78cs5   1/1     Running   0          82m     10.42.0.28   k3s-master   <none>           <none>
    --> secure-pod                         1/1     Running   0          78s     10.42.0.31   k3s-master   <none>           <none>

5. Wejdź do środka i sprawdź zmienne środowiskowe:
# kubectl exec -it secure-pod -- sh
sWewnątrz wpisz:
# echo $MOJE_HASLO_DO_BAZY
    SuperTajneHaslo123


















