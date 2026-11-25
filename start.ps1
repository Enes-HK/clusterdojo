# Starts ClusterDojo: images, 4 kind clusters, the terminal container, then opens the exam UI.
# Usage:  start.cmd   (or: powershell -ExecutionPolicy Bypass -File start.ps1)
# Not 'Stop': Windows PowerShell turns progress text that docker/kind write to stderr into errors once output is
# redirected. Every native call checks $LASTEXITCODE instead.
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$clusters = 'dojo1', 'dojo2', 'dojo3', 'dojo4'
$nodeImage = 'clusterdojo/node:v1.37.0'
$termImage = 'clusterdojo/terminal:latest'
$terminal = 'dojo-terminal'
$uiPort = 8484

function Test-Docker { docker info --format '{{.ServerVersion}}' *> $null; return $LASTEXITCODE -eq 0 }

foreach ($tool in 'docker', 'kind') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool not found. See README.md -> Requirements." }
}
if (-not (Test-Docker)) {
    $dd = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (-not (Test-Path $dd)) { throw "Docker isn't running. Start it and run start.cmd again." }
    Write-Host "Starting Docker Desktop..."
    Start-Process $dd
    for ($i = 0; $i -lt 60 -and -not (Test-Docker); $i++) { Start-Sleep 5 }
    if (-not (Test-Docker)) { throw "Docker didn't start. Open Docker Desktop and check for an error dialog." }
}

# SSH key shared by the terminal and all nodes: created on the first start, never committed
$keys = "$root\images\keys"
$rebuild = $false
if (-not (Test-Path "$keys\id_ed25519")) {
    Write-Host "Creating the SSH key for the exam machines..."
    New-Item -ItemType Directory -Force $keys | Out-Null
    docker run --rm -v "${keys}:/k" alpine:3.20 sh -c "apk add -q --no-cache openssh-keygen && ssh-keygen -q -t ed25519 -N '' -C clusterdojo -f /k/id_ed25519"
    if ($LASTEXITCODE -ne 0) { throw "Couldn't create the SSH key." }
    $rebuild = $true
}

foreach ($img in @(@($nodeImage, 'node'), @($termImage, 'terminal'))) {
    docker image inspect $img[0] *> $null
    if ($rebuild -or $LASTEXITCODE -ne 0) {
        Write-Host "Building the $($img[1]) image..."
        docker build -q -f "$root\images\$($img[1])\Dockerfile" -t $img[0] "$root\images"
        if ($LASTEXITCODE -ne 0) { throw "Building the $($img[1]) image failed." }
    }
}

$existing = @(kind get clusters 2>$null)
$fresh = $false
foreach ($c in $clusters) {
    if ($existing -notcontains $c) {
        Write-Host "Creating cluster $c..."
        kind create cluster --name $c --config "$root\clusters\$c.yaml" --image $nodeImage --wait 120s
        if ($LASTEXITCODE -ne 0) { throw "Creating cluster $c failed." }
        $fresh = $true
    } else {
        docker ps -a --filter "label=io.x-k8s.kind.cluster=$c" --format '{{.Names}}' | ForEach-Object { docker start $_ *> $null }
    }
    kind get kubeconfig --internal --name $c | Set-Content -Encoding ascii "$root\exam\kubeconfigs\$c"
    if ($LASTEXITCODE -ne 0) { throw "Couldn't read the kubeconfig of cluster $c." }
}
if ($fresh) { Remove-Item "$root\exam\state\setup-done" -ErrorAction SilentlyContinue }

# Local time in the exam UI and score files: the host's current UTC offset as a POSIX TZ string (UTC+1 -> <+0100>-01:00)
$off = [TimeZoneInfo]::Local.GetUtcOffset((Get-Date))
$sign = if ($off -lt [TimeSpan]::Zero) { '-' } else { '+' }
$hhmm = '{0:hh}{0:mm}' -f $off.Duration()
$tz = "<$sign$hhmm>" + $(if ($sign -eq '+') { '-' } else { '+' }) + ('{0:hh}:{0:mm}' -f $off.Duration())

docker rm -f $terminal *> $null
docker run -d --name $terminal --hostname terminal --network kind -e "TZ=$tz" `
    --network-alias charts.acme `
    -p "127.0.0.1:${uiPort}:8080" -p 127.0.0.1:7681:7681 -v "$root\exam:/root/exam" $termImage | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Starting the terminal container failed (is port $uiPort or 7681 already in use?)." }

if (-not (Test-Path "$root\exam\state\setup-done")) {
    Write-Host "Preparing the clusters and the mock (first start takes ~10 minutes)..."
    docker exec $terminal bash /root/exam/bin/setup-all.sh
}

Start-Process "http://localhost:$uiPort"
Write-Host "Exam UI: http://localhost:$uiPort"
