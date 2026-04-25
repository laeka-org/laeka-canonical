# Laeka Troubleshooting

## Install fails: "Claude Code CLI not found"

Claude Code must be installed and on your PATH before running the installer.

1. Install Claude Code: https://claude.ai/code
2. Launch it once to initialise `~/.claude/`
3. Re-run the installer

## Install fails: "~/.claude/settings.json not found"

Claude Code creates this file on first launch. Launch the app, then re-run the installer.

## Install fails: "jq required"

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# RHEL/Fedora
sudo yum install jq
```

## Laeka doesn't load at session start

**Check 1 — Hook registered?**

```bash
jq '.hooks.SessionStart' ~/.claude/settings.json
```

Should contain an entry with `laeka-session-start` in the command. If missing, re-run:

```bash
bash ~/laeka-canonical-distribution/distribution/install-laeka.sh
```

**Check 2 — Hook script exists?**

```bash
ls -la ~/.claude/laeka-session-start.sh
```

If missing, re-run the installer.

**Check 3 — Hook executes?**

```bash
bash ~/.claude/laeka-session-start.sh
```

This should print the canonical content to stdout. Errors indicate missing files or permissions.

## Integrity check fails at session start

The session is blocked because one or more canonical files were modified or are missing.

**Option A — Restore from latest distribution:**

```bash
bash ~/laeka-canonical-distribution/distribution/update-laeka.sh
```

**Option B — Temporarily disable for debugging:**

```bash
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh
# When done:
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh --enable
```

**Option C — Full reinstall:**

```bash
bash ~/laeka-canonical-distribution/distribution/uninstall-laeka.sh --confirm
curl -fsSL https://laeka.ai/install | bash
```

## "Integrity check skipped: missing dependency"

Exit code 2 from verify-canonical.sh. Install `jq` (see above), then:

```bash
bash ~/laeka-canonical-distribution/distribution/scripts/verify-canonical.sh
```

## Memory files not loading

Claude Code memory is project-scoped. Laeka memory files are installed at:

```
~/.claude/projects/laeka/memory/
```

To use them in a specific project, copy them:

```bash
cp -r ~/.claude/projects/laeka/memory/. ~/.claude/projects/<your-project>/memory/
```

Or reference the MEMORY.md index manually in your project.

## Update fails: "not a git clone"

If you installed via tar.gz (no git), `update-laeka.sh` cannot auto-update. Re-run the installer:

```bash
bash ~/laeka-canonical-distribution/distribution/install-laeka.sh
```

The installer is idempotent — existing installations are updated in-place.

## Settings.json was corrupted by the install

The installer backs up your settings before any modification:

```bash
ls ~/.claude/settings.json.laeka-backup-*
```

Restore with:

```bash
cp ~/.claude/settings.json.laeka-backup-YYYYMMDD-HHMMSS ~/.claude/settings.json
```

## Still stuck?

- Email: support@laeka.ai
- Issues: https://github.com/laeka-org/laeka-canonical/issues
