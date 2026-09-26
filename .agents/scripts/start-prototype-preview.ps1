[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$PrototypePath,

    [string]$QueryString = "preview=1",

    [ValidateRange(1024, 65535)]
    [int]$LocalPort = 8890,

    [ValidateRange(1024, 65535)]
    [int]$TailnetPort = 8878
)

$ErrorActionPreference = "Stop"

function Test-LocalPortAvailable {
    param([int]$Port)

    $previewListener = [System.Net.Sockets.TcpListener]::new(
        [System.Net.IPAddress]::Loopback,
        $Port
    )

    try {
        $previewListener.Start()
        return $true
    }
    catch [System.Net.Sockets.SocketException] {
        return $false
    }
    finally {
        $previewListener.Stop()
    }
}

$repositoryRoot = (Get-Location).Path
$prototypeFile = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $PrototypePath))
$repositoryPrefix = $repositoryRoot.TrimEnd("\", "/") + [System.IO.Path]::DirectorySeparatorChar

if (-not $prototypeFile.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "PrototypePath must stay inside the repository."
}

if (-not (Test-Path -LiteralPath $prototypeFile -PathType Leaf)) {
    throw "Prototype file not found: $prototypeFile"
}

if ([System.IO.Path]::GetExtension($prototypeFile) -notin ".html", ".htm") {
    throw "PrototypePath must point to an HTML file."
}

$pythonCommand = @(Get-Command python -CommandType Application -ErrorAction Stop)[0]
$tailscaleCommand = @(Get-Command tailscale -CommandType Application -ErrorAction Stop)[0]
$tailnetState = & $tailscaleCommand.Source status --json | ConvertFrom-Json

if (-not $tailnetState.Self.Online) {
    throw "This machine is not connected to its tailnet."
}

$localPreviewPort = $LocalPort
while (-not (Test-LocalPortAvailable -Port $localPreviewPort)) {
    $localPreviewPort++
    if ($localPreviewPort -gt [Math]::Min($LocalPort + 99, 65535)) {
        throw "No free local preview port was found."
    }
}

$previewProcess = Start-Process `
    -FilePath $pythonCommand.Source `
    -ArgumentList @("-m", "http.server", "$localPreviewPort", "--bind", "127.0.0.1") `
    -WorkingDirectory $repositoryRoot `
    -WindowStyle Hidden `
    -PassThru

$relativePrototypePath = [System.IO.Path]::GetRelativePath($repositoryRoot, $prototypeFile).Replace("\", "/")
$encodedPrototypePath = ($relativePrototypePath.Split("/") | ForEach-Object {
    [System.Uri]::EscapeDataString($_)
}) -join "/"
$localPreviewUrl = "http://127.0.0.1:$localPreviewPort/$encodedPrototypePath"
$localPreviewReady = $false

for ($previewAttempt = 0; $previewAttempt -lt 50; $previewAttempt++) {
    try {
        $previewResponse = Invoke-WebRequest -UseBasicParsing -Uri $localPreviewUrl -TimeoutSec 1
        if ($previewResponse.StatusCode -eq 200) {
            $localPreviewReady = $true
            break
        }
    }
    catch {
        Start-Sleep -Milliseconds 100
    }
}

if (-not $localPreviewReady) {
    Stop-Process -Id $previewProcess.Id -ErrorAction SilentlyContinue
    throw "The local prototype server did not become ready."
}

$serveResult = & $tailscaleCommand.Source serve --bg --yes "--https=$TailnetPort" "http://127.0.0.1:$localPreviewPort" 2>&1
if ($LASTEXITCODE -ne 0) {
    Stop-Process -Id $previewProcess.Id -ErrorAction SilentlyContinue
    throw "Could not expose the prototype on the tailnet: $serveResult"
}

$tailnetDnsName = $tailnetState.Self.DNSName.TrimEnd(".")
$normalizedQuery = $QueryString.TrimStart("?")
if ([string]::IsNullOrWhiteSpace($normalizedQuery)) {
    $normalizedQuery = "preview=1"
}

$directPreviewUrl = "https://${tailnetDnsName}:$TailnetPort/${encodedPrototypePath}?$normalizedQuery"

$tailnetPreviewReady = $false
$tailnetPreviewError = "No response received."

for ($tailnetAttempt = 0; $tailnetAttempt -lt 50; $tailnetAttempt++) {
    try {
        $tailnetResponse = Invoke-WebRequest -UseBasicParsing -Uri $directPreviewUrl -TimeoutSec 1
        if ($tailnetResponse.StatusCode -eq 200) {
            $tailnetPreviewReady = $true
            break
        }
        $tailnetPreviewError = "Unexpected HTTP status $($tailnetResponse.StatusCode)."
    }
    catch {
        $tailnetPreviewError = $_.Exception.Message
    }
    Start-Sleep -Milliseconds 100
}

if (-not $tailnetPreviewReady) {
    & $tailscaleCommand.Source serve "--https=$TailnetPort" off *> $null
    Stop-Process -Id $previewProcess.Id -ErrorAction SilentlyContinue
    throw "The tailnet preview did not pass its HTTP check: $tailnetPreviewError"
}

Write-Output $directPreviewUrl
