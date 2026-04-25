# Laeka Canonical Lock Mechanism

Cryptographic integrity protection for the Laeka distributed canonical. Prevents unauthorized modification of core alignment files.

## What it protects

- `canonical-public.md` — core alignment canonical
- `memory-public/MEMORY.md` — memory index
- `memory-public/*.md` — all 49 core memory files

Any single-character change to any protected file triggers a hard block at session start.

## How it works

```
[SessionStart]
      │
      ▼
verify-canonical.sh
      │
      ├─ Read canonical-manifest.json (hashes + global_hash)
      ├─ Recompute SHA-256 for each protected file
      ├─ Compare file hashes + global_hash
      │
      ├─ All match → exit 0 → session starts normally
      └─ Any mismatch → exit 1 → session blocked, error shown
```

The manifest stores: individual SHA-256 per file + a global hash (SHA-256 of all sorted `hash  filepath` lines). Tampering with the manifest itself is caught by the global_hash check.

## Installation (client)

```bash
bash /path/to/distribution/scripts/install-hook.sh
```

This adds `verify-canonical.sh` to the `SessionStart` hooks in `~/.claude/settings.json`. Runs before every Claude Code session.

**Requirements:** `jq`, `shasum` (macOS) or `sha256sum` (Linux).

## Publishing a canonical update (Saphi / admin)

```bash
# Edit canonical-public.md or memory-public/*.md as needed, then:
bash scripts/update-canonical.sh --version 1.1.0 --signed-by "Laeka-Tour 2026-05-01"

# Verify the new manifest is valid
bash scripts/verify-canonical.sh

# Commit and tag
git add canonical-manifest.json
git commit -m "chore(lock): update canonical manifest v1.1.0"
git tag canonical-v1.1.0
```

The update script auto-detects all `memory-public/*.md` files and recomputes everything.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | All files match — proceed |
| 1 | Integrity violation — session blocked |
| 2 | Missing dependency (jq, shasum) or missing manifest |
| 3 | Lock disabled by admin |

## Admin operations

```bash
# Temporarily disable (for maintenance)
bash scripts/disable-lock.sh
# → prompts for reason, writes .lock-disabled flag

# Re-enable
bash scripts/disable-lock.sh --enable

# Remove hook from settings.json entirely
bash scripts/disable-lock.sh --uninstall-hook

# Check current status
bash scripts/disable-lock.sh --status
```

## Error messages

**"LAEKA CANONICAL INTEGRITY VIOLATED"** — One or more protected files differ from their recorded hashes. Either: (a) a file was modified accidentally, (b) a deliberate fork attempt, or (c) a legitimate update was not re-signed with `update-canonical.sh`.

**Resolution:** Restore from the official Laeka distribution, then run `verify-canonical.sh` to confirm.

## FAQ

**Q: A legitimate update was pushed but clients are blocked?**
A: The update must be published via `update-canonical.sh` which regenerates the manifest. Clients then need to pull the new manifest before their next session.

**Q: Can the attacker bypass by modifying verify-canonical.sh itself?**
A: Yes — this is the bootstrap problem. V1 trust model: the script and manifest are distributed together and version-controlled. An attacker who can write to the distribution directory already owns the machine. V2 target: GPG-sign the manifest so the public key (hardcoded in verify-canonical.sh) can authenticate it.

**Q: Can the attacker bypass by modifying settings.json to remove the hook?**
A: Yes — same machine-ownership assumption. V1 is protection against accidental corruption and casual forks, not against a fully compromised host.

**Q: Cross-platform compatibility?**
A: Scripts detect `sha256sum` (Linux) vs `shasum -a 256` (macOS) automatically. Tested on both.

**Q: The .lock-disabled flag is itself unprotected?**
A: By design — it's an admin escape hatch. It writes a timestamp + reason for audit trail. Remove it to re-enable.

## Version history

| Version | Date | Note |
|---------|------|------|
| 1.0.0 | 2026-04-25 | Initial — 51 files, trust-based V1 |

## V2 roadmap

- GPG signing of manifest (verify with embedded public key)
- Sigstore transparency log for public auditability
- Client auto-pull of manifest updates via signed channel
