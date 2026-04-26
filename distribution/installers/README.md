# Laeka Native Installers

One-click installers for non-technical users. No terminal required.

## macOS — Laeka.pkg (V2)

### What it does
Double-click → Apple Installer wizard → **full no-terminal setup**:
Claude Code auto-install → Anthropic account wizard → claude login → Laeka knowledge base → frontend auto-launch in browser.

### Build environment

**`Laeka.pkg` can only be built on macOS.** The build relies on `pkgbuild` and `productbuild`, which are Apple-only tools shipped with Xcode Command Line Tools. They have no Linux equivalent.

Practical implications:
- The `Laeka.pkg` artifact in this repo was built on macOS and is carried with the repo as a binary. Linux clones of this repo cannot rebuild it.
- For Phase 1 sangha distribution (mostly Mac recipients), the existing committed `Laeka.pkg` artifact is sufficient. Verify checksum before publishing to `laeka.ai/download`.
- Before any public-facing rebuild (signed release, version bump), run `build-mac.sh` from a Mac with the signing identity configured.
- Linux users get `Laeka.AppImage` (built via `build-linux.sh`) — see Linux section below. A `.deb` is V2 scope.

### Build (must run on macOS)

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
| `/usr/local/laeka/install.sh` | Laeka distribution installer |
| `/usr/local/laeka/uninstall.sh` | Uninstaller |
| `/usr/local/laeka/update.sh` | Updater |
| `/usr/local/laeka/laeka-v2-orchestrator.sh` | V2 setup orchestrator |
| `/usr/local/laeka/onboarding-anthropic.html` | Anthropic signup guide |
| `~/laeka-canonical-distribution/` | Canonical distribution (downloaded) |
| `~/.claude/projects/laeka/memory/` | Laeka memory files |
| `~/.claude/laeka-session-start.sh` | SessionStart hook |
| `~/Library/LaunchAgents/com.laeka.frontend.plist` | Auto-start frontend at login |

### V2 Setup Flow (end-user)

1. User double-clicks `Laeka.pkg`
2. Apple Installer welcome screen explains the flow
3. Installer runs — no terminal required:
   - Detects / installs Claude Code silently
   - Opens Anthropic signup guide in browser + dialog prompt
   - Runs `claude login` (opens browser OAuth)
   - Downloads and installs Laeka canonical distribution
   - Runs `npm install` in the frontend directory
   - Installs LaunchAgent for auto-start at login
   - Starts Next.js frontend + opens `http://localhost:8080/laeka`
4. User sees Laeka chat ready in browser

### Uninstall

Users open Terminal and run:
```bash
bash /usr/local/laeka/uninstall.sh
launchctl unload ~/Library/LaunchAgents/com.laeka.frontend.plist
rm ~/Library/LaunchAgents/com.laeka.frontend.plist
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
