Lab 10: Resources & Limits (Ochrona Klastra)
Scenariusz: Programista napisał kod z wyciekiem pamięci. Aplikacja zjada cały RAM, zawieszając cały serwer (i inne aplikacje).
Rozwiązanie: Limity zasobów.
1. Stwórz plik:   greedy-pod.yaml


Zauważ: Aplikacja będzie próbowała użyć 150MB (--vm-bytes 150M), ale limit ustawiliśmy na 100MB.
2. Zadanie dla Ciebie:
# kubectl apply -f greedy-pod.yaml
    pod/memory-demo created

   Obserwuj co się stanie:
# kubectl get pod memory-demo -w
    NAME          READY   STATUS             RESTARTS      AGE
    memory-demo   0/1     CrashLoopBackOff   1 (11s ago)   32s
    memory-demo   0/1     OOMKilled          2 (19s ago)   40s   <-- Tutaj powinieneś zobaczyć OOMKilled
    memory-demo   0/1     CrashLoopBackOff   2 (13s ago)   52s   <-- I tak dalej...
    memory-demo   1/1     Running            3 (28s ago)   67s
    memory-demo   0/1     OOMKilled          3 (29s ago)   68s
    memory-demo   0/1     CrashLoopBackOff   3 (10s ago)   77s
    memory-demo   0/1     OOMKilled          4 (51s ago)   118s

Czego szukamy:
Powinieneś zobaczyć status OOMKilled (Out Of Memory Killed).
Kubernetes zauważył, że pod przekroczył limit i go zabił, ratując resztę systemu.
To kluczowa mechanika w pracy administratora K8s.