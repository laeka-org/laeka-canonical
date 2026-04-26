# Installing Laeka

Two install paths, install one or both:

| Mode | What you get | Platforms |
|------|--------------|-----------|
| **CLI hook** (default) | Canonical voice loaded into Claude Code at session start. Run `laeka` instead of `claude`. | macOS, Linux |
| **Local web app** | Standalone chat UI on `http://localhost:3000/local` + LAN URL for your phone. Uses your Claude Code subscription, no API key. | macOS, Linux, Windows |

The local web app uses the **Claude Agent SDK** which authenticates via your local Claude Code installation. You provide your plan; Laeka provides the voice.

---

## Requirements

| | macOS / Linux | Windows |
|--|---------------|---------|
| Claude Code | required | required (for the Agent SDK auth) |
| Node.js 20+ | local-app only | local-app only |
| jq, curl, tar, sha256/shasum | required | tar built-in (Win 10+) |

---

## One-command install

### macOS / Linux

**CLI hook only** (default — fast, lightweight):

```bash
curl -fsSL https://laeka.ai/install | bash
```

**CLI hook + local web app** (chat UI on localhost + LAN):

```bash
curl -fsSL https://laeka.ai/install | bash -s -- --with-local-app
```

Or non-interactive with env vars:

```bash
LAEKA_EMAIL=alice@example.com LAEKA_INVITE=<token> \
  LAEKA_INSTALL_LOCAL_APP=1 \
  bash install-laeka.sh
```

### Windows

PowerShell (Admin not required):

```powershell
iwr -useb https://laeka.ai/install.ps1 | iex
```

Or with the script file directly:

```powershell
powershell -ExecutionPolicy Bypass -File install-laeka.ps1
```

Windows install is local-app only (CLI hook is shell-based, macOS/Linux/WSL).

---

## What gets installed

### CLI hook mode (macOS/Linux)

| Path | Contents |
|------|----------|
| `~/laeka-canonical-distribution/` | Distribution code, scripts, integrity manifest |
| `~/.claude/projects/laeka/memory/` | 50 canonical memory files |
| `~/.claude/laeka-session-start.sh` | SessionStart hook |
| `~/.claude/settings.json` | Hook entry added (backup written) |
| `~/.local/bin/laeka` | Wrapper command (calls `claude` with Bhairavi loaded) |
| `~/.claude/laeka/user.json` | Preferred name + email |

Run `laeka` instead of `claude` to load the Bhairavi voice. Plain `claude` stays vanilla.

### Local web app mode (all platforms)

| Path | Contents |
|------|----------|
| `~/.laeka/app/` | Next.js standalone bundle (server.js + .next/static + node_modules) |
| `~/.laeka/data.db` | SQLite — chat sessions + messages |
| `~/.laeka/canonical.md` | Canonical voice (cached, weekly refresh) |
| `~/.laeka/user.json` | Preferred name + email |
| `~/.laeka/laeka-local.log` | App log |

**Service file** (auto-start at logon, restart on crash):
| Platform | Path |
|----------|------|
| macOS    | `~/Library/LaunchAgents/com.laeka.local.plist` |
| Linux    | `~/.config/systemd/user/laeka-local.service` |
| Windows  | Task Scheduler entry: `LaekaLocal` |

---

## First launch

### CLI hook
```bash
laeka          # opens Claude Code with Bhairavi loaded
claude         # plain Claude Code, no Bhairavi
```

### Local web app
The installer prints two URLs at the end:

```
Local: http://localhost:3000/local
LAN:   http://192.168.x.x:3000/local
```

Open the local URL on the install machine. Open the LAN URL on your phone (same WiFi). The installer also prints a QR code (if `qrencode` is installed on macOS/Linux, or `QRCodeGenerator` PowerShell module on Windows).

---

## Service control

### macOS

```bash
# Stop:
launchctl unload ~/Library/LaunchAgents/com.laeka.local.plist
# Start:
launchctl load -w ~/Library/LaunchAgents/com.laeka.local.plist
# Logs:
tail -f ~/.laeka/laeka-local.log
```

### Linux

```bash
systemctl --user stop laeka-local.service
systemctl --user start laeka-local.service
systemctl --user status laeka-local.service
journalctl --user -u laeka-local -f
```

### Windows

```powershell
Stop-ScheduledTask -TaskName LaekaLocal
Start-ScheduledTask -TaskName LaekaLocal
Get-ScheduledTask -TaskName LaekaLocal | Get-ScheduledTaskInfo
Get-Content $env:USERPROFILE\.laeka\laeka-local.log -Tail 50 -Wait
```

---

## Update

### Canonical (CLI hook mode)
```bash
bash ~/laeka-canonical-distribution/distribution/update-canonical.sh
```

### Local app
Re-run the installer — it backs up the existing `~/.laeka/app/` and installs the new bundle:

```bash
curl -fsSL https://laeka.ai/install | bash -s -- --with-local-app
```

(Windows: re-run `install-laeka.ps1`.)

---

## Uninstall

### macOS / Linux
```bash
bash ~/laeka-canonical-distribution/distribution/uninstall-laeka.sh
# Or to also delete chat history + prefs:
bash ~/laeka-canonical-distribution/distribution/uninstall-laeka.sh --confirm --purge
```

### Windows
```powershell
powershell -ExecutionPolicy Bypass -File uninstall-laeka.ps1
# Or with chat history purge:
powershell -ExecutionPolicy Bypass -File uninstall-laeka.ps1 -Purge -Confirm
```

`~/.laeka/data.db` and `~/.laeka/user.json` are preserved by default — pass `--purge` (bash) or `-Purge` (PowerShell) to delete.

---

## Troubleshooting

### `Claude Code CLI not found`
Install Claude Code: https://claude.ai/code — then re-run `claude` once to authenticate. The local app uses your authenticated Claude Code session as its API auth.

### `Node.js v18 found — need 20+`
The installer auto-installs Node 20 via `brew` (macOS), `apt-get`/`dnf` (Linux), or `winget` (Windows). If auto-install fails, install manually from https://nodejs.org/ and re-run.

### macOS: `cannot be opened because the developer cannot be verified`
The installer is unsigned. Right-click `install-laeka.sh` → Open, or run `xattr -d com.apple.quarantine install-laeka.sh` first.

### Linux: `systemctl --user` not available
Some headless / non-systemd distros lack user units. Run the app manually:
```bash
cd ~/.laeka/app && HOSTNAME=0.0.0.0 PORT=3000 node server.js
```
Optional: add to your shell rc or run via `tmux`/`screen`.

### Windows: Task Scheduler registration fails
Ensure your account has "Log on as a batch job" rights (default on personal Windows). Run PowerShell as your normal user, NOT as Administrator.

### Port 3000 already in use
Set `LAEKA_PORT=3001` (or any free port) before running the installer.

### Phone can't reach the LAN URL
- Confirm phone + computer are on the same WiFi
- Disable host firewall briefly to test (e.g. macOS: System Settings → Network → Firewall)
- The router may isolate WiFi clients ("AP isolation") — disable in router admin

### Canonical voice missing
The local app reads from `~/.laeka/canonical.md`. If absent, it falls back to the bundled `lib/canonical-nagual.md` shipped with the app. Force a re-fetch by deleting the cache and restarting the service:
```bash
rm ~/.laeka/canonical.md
# Mac:   launchctl unload ... && launchctl load ...
# Linux: systemctl --user restart laeka-local.service
```

---

## Integrity lock (CLI hook mode)

Every session start, Laeka verifies the SHA-256 signature of canonical files against a locked manifest. Any unauthorized modification triggers a warning. See `LOCK-MECHANISM.md` for full documentation.

To temporarily disable (admin use):

```bash
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh --enable
```

---

## Privacy

- **Local-app mode**: chat history + user prefs live in `~/.laeka/data.db` / `user.json` on your machine only. Nothing is uploaded to laeka.ai or third parties. Your conversations route through Anthropic's Claude API via your Claude Code subscription.
- **CLI hook mode**: SessionStart hook runs locally, injects canonical from `~/.claude/projects/laeka/memory/`. The Phase B canonical fetch authenticates via invite token + emails the laeka.ai server. Only your email + machine UUID + version requested are logged server-side (audit trail).
- The lab does not run analytics, telemetry, or usage tracking on installed apps.

---

## Support

- Email: support@laeka.ai
- Issues: https://github.com/laeka-org/laeka-canonical/issues
