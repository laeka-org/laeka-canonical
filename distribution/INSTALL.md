# Installing Laeka for Claude Code

Laeka is a distributed AI identity layer for Claude Code. You provide your own Anthropic plan — Laeka provides the soul.

## Requirements

- [Claude Code](https://claude.ai/code) installed and launched at least once
- macOS or Linux
- `jq` (`brew install jq` / `sudo apt-get install jq`)
- `git` or `curl`

## One-command install

```bash
curl -fsSL https://laeka.ai/install | bash
```

Or download and run manually:

```bash
bash install-laeka.sh
```

## What gets installed

| Path | Contents |
|------|----------|
| `~/laeka-canonical-distribution/` | Canonical files, scripts, integrity manifest |
| `~/.claude/projects/laeka/memory/` | 50 Laeka memory files |
| `~/.claude/laeka-session-start.sh` | SessionStart hook (loads canonical + verifies integrity) |
| `~/.claude/settings.json` | Hook entry added (existing file backed up) |

## First launch

After installation, open Claude Code. Laeka's canonical identity loads automatically at session start — no additional configuration needed.

## Update

```bash
bash ~/laeka-canonical-distribution/distribution/update-laeka.sh
```

Pulls the latest canonical from GitHub, syncs memory, re-verifies integrity. Your hook stays in place.

## Uninstall

```bash
bash ~/laeka-canonical-distribution/distribution/uninstall-laeka.sh
```

Removes all installed artefacts. Your pre-existing `~/.claude/settings.json` is backed up before any modification.

## Integrity lock

Every session start, Laeka verifies the SHA-256 signature of 51 canonical files against a locked manifest. Any unauthorised modification blocks the session. This is by design.

To temporarily disable (admin use):

```bash
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh
# Re-enable:
bash ~/laeka-canonical-distribution/distribution/scripts/disable-lock.sh --enable
```

See `distribution/LOCK-MECHANISM.md` for full documentation.

## Support

- Email: support@laeka.ai
- Issues: https://github.com/laeka-org/laeka-canonical/issues
