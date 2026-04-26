# uninstall-laeka.ps1 — Remove Laeka Local App from Windows.
#
# Stops + unregisters the Task Scheduler entry, removes the app dir.
# Preserves ~/.laeka/data.db + user.json by default. Pass -Purge to delete.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File uninstall-laeka.ps1
#   powershell -ExecutionPolicy Bypass -File uninstall-laeka.ps1 -Purge

param(
    [switch]$Purge,
    [switch]$Confirm
)

$ErrorActionPreference = "Stop"

$LaekaDir = Join-Path $env:USERPROFILE ".laeka"
$AppDir   = Join-Path $LaekaDir "app"
$TaskName = "LaekaLocal"

function Info($msg)    { Write-Host "[laeka-uninstall] $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "[laeka-uninstall] OK $msg" -ForegroundColor Green }
function WarnMsg($msg) { Write-Host "[laeka-uninstall] WARN $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "──────────────────────────────────────" -ForegroundColor Blue
Write-Host "  Laeka Local App Uninstaller (Windows)" -ForegroundColor Blue
Write-Host "──────────────────────────────────────" -ForegroundColor Blue
Write-Host ""
Write-Host "This will remove:"
Write-Host "  - $AppDir"
Write-Host "  - Task Scheduler entry: $TaskName"
if ($Purge) {
    Write-Host "  - $LaekaDir (chat history + user prefs)" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Preserved (pass -Purge to remove):"
    Write-Host "  - $LaekaDir\data.db"
    Write-Host "  - $LaekaDir\user.json"
}
Write-Host ""

if (-not $Confirm) {
    $resp = Read-Host "Proceed? [y/N]"
    if ($resp -notmatch '^[yY]') {
        Write-Host "Aborted."
        exit 0
    }
}

# Stop + unregister scheduled task (idempotent)
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    try { Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue } catch {}
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Success "Removed Task Scheduler entry: $TaskName"
} else {
    Info "No Task Scheduler entry found — skipping"
}

# Stop any running node processes from the app dir (best effort)
Get-Process node -ErrorAction SilentlyContinue | ForEach-Object {
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine
        if ($cmd -and $cmd -match [regex]::Escape($AppDir)) {
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Info "Stopped node process PID=$($_.Id)"
        }
    } catch {}
}

# Remove app dir
if (Test-Path $AppDir) {
    Remove-Item -Path $AppDir -Recurse -Force
    Success "Removed: $AppDir"
} else {
    Info "App dir not found — skipping"
}

# Remove wrapper script
$WrapperPath = Join-Path $LaekaDir "start-laeka-local.ps1"
if (Test-Path $WrapperPath) {
    Remove-Item -Path $WrapperPath -Force
    Success "Removed wrapper: $WrapperPath"
}

# Purge if requested
if ($Purge) {
    if (Test-Path $LaekaDir) {
        Remove-Item -Path $LaekaDir -Recurse -Force
        Success "Purged: $LaekaDir"
    }
} else {
    if (Test-Path $LaekaDir) {
        $remaining = Get-ChildItem $LaekaDir -ErrorAction SilentlyContinue
        if ($remaining) {
            WarnMsg "Preserved: $LaekaDir  (use -Purge to delete chat history + prefs)"
        }
    }
}

Write-Host ""
Write-Host "──────────────────────────────────────" -ForegroundColor Blue
Write-Host "  Uninstall complete" -ForegroundColor Blue
Write-Host "──────────────────────────────────────" -ForegroundColor Blue
Write-Host ""
Write-Host "Reinstall anytime:" -ForegroundColor Cyan
Write-Host "  iwr -useb https://laeka.ai/install.ps1 | iex"
Write-Host ""
