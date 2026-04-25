# Laeka Native Installers

One-click installers for non-technical users. No terminal required.

## macOS — Laeka.pkg (V1 — priority)

### What it does
Double-click → Apple Installer wizard → Laeka installed and active in Claude Code.

### Build

```bash
cd distribution/installers
chmod +x build-mac.sh
./build-mac.sh
# Output: distribution/installers/Laeka.pkg
```

**Requirements:** macOS with Xcode Command Line Tools (`xcode-select --install`)

### Sign (recommended, removes security warning)

```bash
# List your available identities:
security find-identity -v -p basic

# Build signed package:
export SIGN_IDENTITY="Developer ID Installer: Your Name (XXXXXXXXXX)"
./build-mac.sh
```

**Without signing:** Users see a Gatekeeper warning. Fix: right-click `Laeka.pkg` → Open, or allow in System Settings → Privacy & Security → "Open Anyway".

### Distribute

1. Upload `Laeka.pkg` to GitHub Releases or `laeka.ai/download`
2. User downloads, double-clicks
3. Apple Installer wizard runs
4. Installation log appears on their Desktop

### What gets installed

| Path | Content |
|------|---------|
| `/usr/local/laeka/install.sh` | Main install script |
| `/usr/local/laeka/uninstall.sh` | Uninstaller |
| `/usr/local/laeka/update.sh` | Updater |
| `~/laeka-canonical-distribution/` | Canonical distribution (downloaded) |
| `~/.claude/projects/laeka/memory/` | Laeka memory files |
| `~/.claude/laeka-session-start.sh` | SessionStart hook |

### Uninstall

Users open Terminal and run:
```bash
bash /usr/local/laeka/uninstall.sh
```

---

## Windows — Laeka-Installer.exe (V1.5)

### Option A: PowerShell (no wizard, but functional)

```powershell
# User runs as Administrator:
PowerShell -ExecutionPolicy Bypass -File build-windows.ps1
```

### Option B: GUI .exe wizard via Inno Setup

1. Download [Inno Setup 6+](https://jrsoftware.org/isinfo.php)
2. Open `build-windows-inno.iss` in Inno Setup Compiler
3. Build → `Output/Laeka-Installer.exe`

**Note:** Claude Code for Windows uses the `claude.exe` CLI. Verify PATH after Claude Code install.

---

## Linux — Laeka.AppImage (V1.5)

```bash
chmod +x build-linux.sh
./build-linux.sh
# Output: distribution/installers/Laeka.AppImage
```

**AppImage install (user side):**
```bash
chmod +x Laeka.AppImage
./Laeka.AppImage       # runs in terminal
# OR double-click in GNOME/KDE file manager (requires libfuse2)
```

**Ubuntu/Debian alternative:** A `.deb` package is a cleaner fit for apt-managed systems — scope for V2.

---

## Security notes

- macOS unsigned pkg: first launch requires user approval (one-time, standard macOS Gatekeeper flow)
- Windows: SmartScreen may warn on unsigned `.exe` — user clicks "More info" → "Run anyway"
- Linux AppImage: no signing infrastructure by default; users already expect `chmod +x`
- The underlying `install-laeka.sh` is the source of truth — installers wrap it, not replace it
