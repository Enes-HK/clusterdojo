# Throws away the exam clusters and your progress, rebuilds the images and starts a fresh environment.
# Your earlier scores in exam\results are kept. Other kind clusters (not dojo1-dojo4) are not touched.
$root = $PSScriptRoot
docker rm -f dojo-terminal *> $null
foreach ($c in 'dojo1', 'dojo2', 'dojo3', 'dojo4') { kind delete cluster --name $c }
docker image rm clusterdojo/node:v1.37.0 clusterdojo/terminal:latest *> $null
Remove-Item "$root\exam\state" -Recurse -Force -ErrorAction SilentlyContinue
& "$root\start.ps1"
