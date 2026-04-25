; build-windows-inno.iss — Inno Setup script for Laeka Windows .exe installer
;
; Status: V1.5 — requires Inno Setup 6+ to compile
; Download: https://jrsoftware.org/isinfo.php
;
; To build:
;   1. Install Inno Setup 6+
;   2. Open this file in Inno Setup Compiler
;   3. Build → creates Laeka-Installer.exe in Output/
;
; The .exe bundles build-windows.ps1 and runs it silently with elevated privileges.

[Setup]
AppName=Laeka for Claude Code
AppVersion=1.0.0
AppPublisher=Laeka AI
AppPublisherURL=https://laeka.ai
AppSupportURL=https://laeka.ai/support
AppUpdatesURL=https://laeka.ai/install
DefaultDirName={autopf}\Laeka
DisableDirPage=yes
DefaultGroupName=Laeka
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=Laeka-Installer
SetupIconFile=resources\laeka-icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=commandline

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Bundle the PowerShell installer script
Source: "build-windows.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; Run the PowerShell installer after extraction
Filename: "powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NonInteractive -File ""{tmp}\build-windows.ps1"""; \
    StatusMsg: "Installing Laeka..."; \
    Flags: runhidden waituntilterminated

[UninstallRun]
; Run uninstall when user removes via Programs & Features
Filename: "powershell.exe"; \
    Parameters: "-ExecutionPolicy Bypass -NonInteractive -File ""{app}\build-windows.ps1"" -Uninstall"; \
    Flags: runhidden waituntilterminated

[Code]
{ Check that Claude Code is installed before proceeding }
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  if not FileExists(ExpandConstant('{localappdata}\Claude\Claude.exe')) then begin
    if MsgBox('Claude Code does not appear to be installed.' + #13#10 +
              'Install it from claude.ai/code before continuing.' + #13#10#13#10 +
              'Continue anyway?',
              mbConfirmation, MB_YESNO) = IDNO then
      Result := False;
  end;
end;
