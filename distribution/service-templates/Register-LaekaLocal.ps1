# Laeka Local App — Windows Task Scheduler registration.
#
# Registers a logon-triggered scheduled task that starts the Next.js standalone
# server and keeps it running. Equivalent to LaunchAgent (macOS) / systemd user
# unit (Linux) on the Windows side.
#
# Placeholders set by install-laeka.ps1 before invocation:
#   $AppDir   e.g. C:\Users\Alice\.laeka\app
#   $NodeBin  e.g. C:\Program Files\nodejs\node.exe
#
# Run with: powershell -ExecutionPolicy Bypass -File Register-LaekaLocal.ps1
param(
    [Parameter(Mandatory=$true)][string]$AppDir,
    [Parameter(Mandatory=$true)][string]$NodeBin
)

$TaskName = "LaekaLocal"
$LogDir = Join-Path $env:USERPROFILE ".laeka"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# Action: run node server.js in the app directory
$Action = New-ScheduledTaskAction `
    -Execute $NodeBin `
    -Argument "server.js" `
    -WorkingDirectory $AppDir

# Trigger: at user logon
$Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Settings: restart on failure, keep running, no idle requirement
$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries

# Principal: current user, least privilege
$Principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

# Environment vars passed via wrapper script for portability
$EnvSetup = @"
`$env:HOSTNAME = '0.0.0.0'
`$env:PORT = '3000'
`$env:NODE_ENV = 'production'
& '$NodeBin' '$AppDir\server.js' *>> '$LogDir\laeka-local.log'
"@

$WrapperPath = Join-Path $LogDir "start-laeka-local.ps1"
Set-Content -Path $WrapperPath -Value $EnvSetup -Encoding UTF8

# Re-point Action to the wrapper (so env vars + log redirection take effect)
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WrapperPath`"" `
    -WorkingDirectory $AppDir

# Unregister existing task if present (idempotent)
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Laeka Local App — Next.js standalone server" | Out-Null

Start-ScheduledTask -TaskName $TaskName

Write-Host "Registered + started Task Scheduler entry: $TaskName" -ForegroundColor Green
Write-Host "Logs: $LogDir\laeka-local.log"
