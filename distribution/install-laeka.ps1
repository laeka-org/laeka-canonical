# install-laeka.ps1 — Laeka Local App installer for Windows
#
# Installs the Laeka local web app (Next.js standalone) and registers a
# Windows Task Scheduler entry that auto-starts it at logon. Web UI accessible
# at http://localhost:3000/local and on the LAN at http://<your-ip>:3000/local.
#
# Usage:
#   iwr -useb https://laeka.ai/install.ps1 | iex
#   # OR:
#   powershell -ExecutionPolicy Bypass -File install-laeka.ps1
#
# Note: this script installs ONLY the local web app on Windows. The Claude Code
# CLI hook (canonical injection) is macOS/Linux/WSL only — Windows users access
# Laeka via the web UI.
#
# Requirements: Windows 10+, PowerShell 5+, Node.js 20+ (auto-install via winget)

$ErrorActionPreference = "Stop"

# ── Config ───────────────────────────────────────────────────────────────────
$LaekaDir       = Join-Path $env:USERPROFILE ".laeka"
$AppDir         = Join-Path $LaekaDir "app"
$LogDir         = $LaekaDir
$BundleUrl      = if ($env:LAEKA_BUNDLE_URL) { $env:LAEKA_BUNDLE_URL } else { "https://github.com/laeka-org/laeka-canonical/releases/latest/download/laeka-local-app.tar.gz" }
$Port           = if ($env:LAEKA_PORT) { $env:LAEKA_PORT } else { "3000" }
$BackupSuffix   = ".laeka-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$RegisterScript = Join-Path $PSScriptRoot "service-templates\Register-LaekaLocal.ps1"

function Info($msg)    { Write-Host "[laeka] $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[laeka] OK $msg" -ForegroundColor Green }
function WarnMsg($msg) { Write-Host "[laeka] WARN $msg" -ForegroundColor Yellow }
function Fail($msg)    { Write-Host "[laeka] FAIL $msg" -ForegroundColor Red; exit 1 }

function Section($title) {
    Write-Host ""
    Write-Host "──────────────────────────────────────" -ForegroundColor Blue
    Write-Host "  $title" -ForegroundColor Blue
    Write-Host "──────────────────────────────────────" -ForegroundColor Blue
}

# ── Step 0 — Preflight ───────────────────────────────────────────────────────
Section "Laeka Local App Installer (Windows)"
Info "Target: $AppDir"
Info "Logs:   $LogDir"
Info "Port:   $Port"

# tar (built into Windows 10+)
if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Fail "tar.exe not found. Requires Windows 10 1803+ or install bsdtar."
}

# ── Step 1 — Verify / install Node.js 20+ ───────────────────────────────────
Section "Verifying Node.js 20+"

$NodeBin = $null
$existing = Get-Command node -ErrorAction SilentlyContinue
if ($existing) {
    $version = (& node --version) -replace '^v',''
    $major = [int]($version.Split('.')[0])
    if ($major -ge 20) {
        $NodeBin = $existing.Source
        Success "Node.js v$version found at $NodeBin"
    } else {
        WarnMsg "Node.js v$version found — need 20+. Will install."
    }
}

if (-not $NodeBin) {
    Info "Installing Node.js 20 LTS via winget..."
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail "winget not found. Install Node.js 20+ manually: https://nodejs.org/"
    }
    winget install --id OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Fail "winget install failed with exit code $LASTEXITCODE"
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")

    $existing = Get-Command node -ErrorAction SilentlyContinue
    if ($existing) {
        $NodeBin = $existing.Source
        Success "Node.js installed at $NodeBin"
    } else {
        Fail "Node.js install reported success but 'node' not on PATH. Open a new shell and re-run."
    }
}

# ── Step 2 — Download standalone bundle ─────────────────────────────────────
Section "Downloading Laeka Local App bundle"
Info "URL: $BundleUrl"

New-Item -ItemType Directory -Force -Path $LaekaDir | Out-Null
$TmpBundle = Join-Path $env:TEMP ("laeka-bundle-" + [guid]::NewGuid().ToString() + ".tar.gz")

try {
    Invoke-WebRequest -Uri $BundleUrl -OutFile $TmpBundle -UseBasicParsing
} catch {
    Fail "Bundle download failed: $($_.Exception.Message)"
}

$BundleBytes = (Get-Item $TmpBundle).Length
Success "Downloaded ($BundleBytes bytes)"

# ── Step 3 — Extract to app dir ─────────────────────────────────────────────
Section "Extracting bundle"

if (Test-Path $AppDir) {
    $BackupDir = "$AppDir$BackupSuffix"
    Move-Item -Path $AppDir -Destination $BackupDir
    WarnMsg "Existing app dir backed up: $BackupDir"
}

New-Item -ItemType Directory -Force -Path $AppDir | Out-Null

# tar handles .tar.gz natively on Windows 10+
& tar -xzf $TmpBundle -C $AppDir --strip-components=1
if ($LASTEXITCODE -ne 0) {
    # Some bundles ship without a single root dir — try without strip
    & tar -xzf $TmpBundle -C $AppDir
    if ($LASTEXITCODE -ne 0) {
        Fail "tar extract failed with exit code $LASTEXITCODE"
    }
}

Remove-Item $TmpBundle -Force -ErrorAction SilentlyContinue

$ServerJs = Join-Path $AppDir "server.js"
if (-not (Test-Path $ServerJs)) {
    Fail "Bundle missing server.js — invalid Next.js standalone output."
}
Success "Extracted to $AppDir"

# ── Step 4 — Register Task Scheduler entry ───────────────────────────────────
Section "Registering auto-start (Task Scheduler)"

if (-not (Test-Path $RegisterScript)) {
    Fail "Register-LaekaLocal.ps1 not found at $RegisterScript. Make sure you ran the installer from the laeka-canonical/distribution/ folder."
}

& $RegisterScript -AppDir $AppDir -NodeBin $NodeBin
if ($LASTEXITCODE -ne 0) {
    Fail "Task Scheduler registration failed."
}

# ── Step 5 — Wait for ready ─────────────────────────────────────────────────
Section "Waiting for app to start"

$Ready = $false
for ($i = 0; $i -lt 20; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/local" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $Ready = $true
            break
        }
    } catch { }
    Start-Sleep -Seconds 1
}

if ($Ready) {
    Success "App responding on http://127.0.0.1:$Port/local"
} else {
    WarnMsg "App not yet responding after 20s — check logs: $LogDir\laeka-local.log"
}

# ── Step 6 — Detect LAN IP + print URL ──────────────────────────────────────
Section "Local app ready"

$LanIp = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp,Manual `
            -ErrorAction SilentlyContinue |
          Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' } |
          Select-Object -First 1).IPAddress

$LocalUrl = "http://localhost:$Port/local"
$LanUrl = if ($LanIp) { "http://${LanIp}:$Port/local" } else { $null }

Write-Host ""
Write-Host "  Local: $LocalUrl" -ForegroundColor Cyan
if ($LanUrl) {
    Write-Host "  LAN:   $LanUrl  (use from your phone on the same WiFi)" -ForegroundColor Cyan
}

# QR code: rely on PowerShell QRCodeGenerator module if present, else skip with hint
if ($LanUrl) {
    if (Get-Module -ListAvailable -Name QRCodeGenerator) {
        Write-Host ""
        Write-Host "  QR (LAN URL):" -ForegroundColor Cyan
        Import-Module QRCodeGenerator
        New-PSOneQRCodeText -Text $LanUrl -OutPath (Join-Path $LogDir "qr.png") -Width 5
        Info "QR saved to $LogDir\qr.png"
    } else {
        Info "Install QRCodeGenerator for inline QR: Install-Module -Name QRCodeGenerator -Scope CurrentUser"
    }
}

Write-Host ""
Write-Host "  OK  App dir       $AppDir" -ForegroundColor Green
Write-Host "  OK  Logs          $LogDir\laeka-local.log" -ForegroundColor Green
Write-Host ""
Write-Host "  Stop:  Stop-ScheduledTask -TaskName LaekaLocal" -ForegroundColor Cyan
Write-Host "  Start: Start-ScheduledTask -TaskName LaekaLocal" -ForegroundColor Cyan
Write-Host ""

# ── Done ─────────────────────────────────────────────────────────────────────
Section "Installation complete"
Write-Host ""
Write-Host "  Open $LocalUrl in your browser to chat with Laeka." -ForegroundColor Cyan
Write-Host ""
Write-Host "  Uninstall: powershell -ExecutionPolicy Bypass -File uninstall-laeka.ps1"
Write-Host "  Support:   https://laeka.ai/support"
Write-Host ""
