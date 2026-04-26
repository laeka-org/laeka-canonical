# Laeka Canonical Lock Mechanism (Phase B)

Phase B replaces the previous repo-bake-in pattern with **server-side canonical delivery**. The canonical content is no longer distributed in this public repo — it is fetched at install time from `api.laeka.ai/v1/brain/canonical/*` over an authenticated session.

## What's protected

- `~/.claude/projects/laeka/memory/canonical-public.md` — core alignment document
- `~/.claude/projects/laeka/memory/*.md` — all canonical memory files served by the manifest

Both live **on the client machine after install**, fetched from the server. The repo itself does not contain canonical artefacts.

## How it works (Phase B)

```
[Phase 1 install]
         │
         ▼
install-laeka.sh
         │
         ├─ POST /v1/brain/auth/installer-validate {email, invite_token, machine_uuid}
         │   ↳ server returns {session_token, install_token, canonical_version}
         │
         ├─ GET /v1/brain/canonical/manifest?version=<v>  (Authorization: Bearer <session_token>)
         │   ↳ server returns manifest JSON (file hashes + global_hash + signed_by)
         │
         ├─ GET /v1/brain/canonical/bundle?version=<v>    (Authorization: Bearer <session_token>)
         │   ↳ server returns tar.gz of all canonical files
         │
         ├─ Verify each file hash against manifest
         ├─ Verify global_hash (SHA256 of sorted "hash  path" lines)
         ├─ Atomic write to ~/.claude/projects/laeka/memory/
         └─ Persist install_token (0600) and local manifest copy

[Subsequent updates: bash update-canonical.sh]
         │
         ▼
update-canonical.sh
         │
         ├─ POST /v1/brain/auth/installer-refresh {install_token, machine_uuid}
         │   ↳ server returns fresh session_token
         │
         ├─ GET manifest + bundle (same as install)
         ├─ Verify hashes
         └─ Atomic memory dir swap (old backed up with timestamp)

[Each Claude Code session]
         │
         ▼
~/.claude/laeka-session-start.sh (registered hook)
         │
         ├─ Compare canonical-public.md hash vs local manifest copy
         │   ↳ warn (not block) if local edit detected
         └─ Inject canonical-public.md content into session via stdout
```

## Manifest schema

Server-issued JSON, stored locally at `~/.claude/projects/laeka/.canonical-manifest.json`:

```json
{
  "version": "1.0.0",
  "signed_by": "Laeka-Tour 2026-04-26",
  "updated_at": "2026-04-26T09:00:00Z",
  "files": {
    "canonical-public.md": "<sha256-hex>",
    "memory-public/MEMORY.md": "<sha256-hex>",
    "memory-public/project_xyz.md": "<sha256-hex>"
  },
  "global_hash": "<sha256-hex of sorted 'hash  path' lines>"
}
```

Tampering with the manifest is caught by the `global_hash` check at install/update time.

## Authentication model

**Two scoped JWTs (HS256, signed by the server with `BRAIN_JWT_SECRET`):**

| Token | Audience | TTL | Persistence | Purpose |
|-------|----------|-----|-------------|---------|
| `session_token` | `installer-fetch` | 1 hour | In-memory during install run | Authorize `/canonical/manifest` + `/canonical/bundle` |
| `install_token` | `installer-refresh` | 30 days | `~/.claude/projects/laeka/.install-token` (mode 0600) | Refresh `session_token` without re-prompting invite |

The `install_token` rotates every 30 days. When it expires, the user re-runs `install-laeka.sh` and re-validates an invite token (Phase 1: existing tokens may be replayed for the same machine_uuid via `installer_invite_store.claim` idempotency).

## Invite tokens (Phase 1 sangha)

Saphi issues invite tokens via the admin CLI in `laeka-canonical-private/admin/issue-invite.py`. Each token is :

- One-time-use bound to a single `machine_uuid` at first claim (replay allowed for same machine)
- Optionally pre-bound to an email at issue time, or claimed by first email at validate time
- TTL configurable (default 90 days)
- Revocable via `installer_invite_store.revoke()`

Token format : URL-safe hex (32 chars, 128 bits entropy via `secrets.token_hex(16)`).

Distributed in personalized download links: `https://laeka.ai/download?invite=<token>`

## Trust model (V1)

- **Auth integrity** : HTTPS + JWT signed with shared HS256 secret. Server-side trust = correct `BRAIN_JWT_SECRET` deployment.
- **Manifest integrity** : delivered over JWT-authed HTTPS. No body-level cryptographic signing in V1. Manifest internal `global_hash` defends against post-fetch corruption.
- **Bundle integrity** : per-file SHA-256 verified against manifest. Atomic install (old dir untouched until full verify passes).
- **Replay protection** : session_token expires in 1h. install_token bound to machine_uuid (captured token doesn't work elsewhere, server validates `sub` claim against request `machine_uuid`).

V2 roadmap : asymmetric signing (RSA or Sigstore) for offline manifest verification.

## Error codes

| HTTP | Meaning | Client action |
|------|---------|---------------|
| 200 | OK | Proceed |
| 401 | Invalid invite token, expired session/install token, wrong audience | Re-prompt invite (install) or re-install (update) |
| 403 | Tier insufficient for canonical version | Upgrade at `https://laeka.ai/pricing` |
| 404 | Version not found | Pull latest via `update-canonical.sh` |
| 409 | Invite already claimed by different machine | Request new invite |
| 429 | Rate limit exceeded | Back off and retry |
| 5xx | Server error | Retry with backoff (max 3) |

## Local files written by installer

| Path | Purpose | Mode |
|------|---------|------|
| `~/.claude/projects/laeka/memory/` | Canonical memory dir | 700 dir, 644 files |
| `~/.claude/projects/laeka/.canonical-manifest.json` | Local manifest copy for hook integrity check | 644 |
| `~/.claude/projects/laeka/.install-token` | Long-lived JWT for refresh | 600 |
| `~/.claude/projects/laeka/.machine-uuid` | Stable machine identifier | 600 |
| `~/.claude/laeka-session-start.sh` | SessionStart hook script | 755 |
| `~/laeka-canonical-distribution/` | Installer code repo clone | (default) |

## Admin operations (Saphi)

```bash
# Issue 1 invite (email pre-bound, 90-day TTL)
python3 laeka-canonical-private/admin/issue-invite.py --email alice@example.com

# Issue 50 unbound invites for sangha rollout
python3 laeka-canonical-private/admin/issue-invite.py --batch 50

# Revoke an issued token
python3 -c "from seahorse.installer_invite_store import revoke; revoke('<token>', 'reason')"

# Publish a new canonical version locally
python3 laeka-canonical-private/admin/publish-canonical.py --version 1.1.0

# Rsync to VPS
rsync -avz /tmp/laeka-canonical-build/ root@VPS:/opt/seahorse/data/canonical/
```

## FAQ

**Q: Can I run install-laeka.sh non-interactively?**
A: Yes, set `LAEKA_EMAIL` and `LAEKA_INVITE` env vars before running.

**Q: My install_token expired. What now?**
A: Re-run `install-laeka.sh` and re-enter your invite token. If your invite has been used on this machine before, it will be accepted on replay (same `machine_uuid`).

**Q: Can I edit canonical-public.md locally?**
A: You can, but the SessionStart hook will warn you on each session. Local edits are not synced upstream — the lab maintains the canonical privately.

**Q: How do I downgrade to an older canonical version?**
A: `bash update-canonical.sh --version 1.0.0` (if the version is still served by the backend).

**Q: How is my privacy protected?**
A: Server logs : timestamp, machine_uuid, IP, version requested. No PII beyond the email you provided at validate. Email is used only for token binding and revocation; not for marketing.

**Q: Multi-machine install — can I use the same invite on two computers?**
A: One invite = one machine_uuid (Phase 1). For each additional machine, request a new invite from Saphi. We may relax this in Phase 2.

## Version history

| Version | Date | Note |
|---------|------|------|
| 1.0.0 | 2026-04-25 | Initial — repo-bake-in (Phase A) |
| 2.0.0 | 2026-04-26 | Phase B — server-side delivery via JWT-authed api.laeka.ai/v1/brain/canonical/* |

## V2 roadmap

- Asymmetric manifest signing (RSA or Sigstore)
- Offline-mode caching (signed canonical persists across network outages)
- Multi-machine invite tokens (controlled — per-tier)
- Delta updates (fetch only changed files instead of full bundle)
