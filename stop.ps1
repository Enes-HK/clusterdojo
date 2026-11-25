# Pauses ClusterDojo to free RAM/CPU. start.ps1 resumes it with your progress intact.
docker rm -f dojo-terminal *> $null
foreach ($c in 'dojo1', 'dojo2', 'dojo3', 'dojo4') {
    docker ps -q --filter "label=io.x-k8s.kind.cluster=$c" | ForEach-Object { docker stop $_ *> $null }
}
Write-Host "Stopped."
