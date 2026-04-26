# Phase B Architecture — Server-Side Canonical Delivery

**Status :** Implementation complete — backend endpoints + client installer + auxiliary scripts.
**Author :** Code-F1 (Factory 1)
**Date :** 2026-04-26 (spec drafted) → updated post-apex F1.1 dispatch
**Parents :** brief F1, brief F1.1, ledger 57 (empirical Phase A audit), ledger 59 (royaume architecture)
**Scope :** client (installer) redesign + backend endpoints

This document specified the redesign of `install-laeka.sh` to fetch canonical artefacts from an authenticated server, replacing the bake-in pattern broken by Phase A strip.

**Apex decisions (brief F1.1) :**

- **Q1 — Subdomain naming :** extend existing pattern at `laeka.ai/v1/brain/canonical/*`. No new `mcp.laeka.ai` subdomain.
- **Q2 — Backend builder :** F1 extended scope to build endpoints in seahorse-legacy (existing FastAPI backend serving `laeka.ai/v1/brain/*`).
- **Q3 — Auth provider :** Custom JWT signed with shared `BRAIN_JWT_SECRET` (HS256), reusing pattern from `seahorse/brain_auth.py`. No third-party auth.
- **Q4 — Invite token rollout :** URL query in personalized links (`https://laeka.ai/download?invite=<token>`). Admin CLI in `laeka-canonical-private/admin/issue-invite.py`.
- **Q5 — `canonical-manifest.json` :** Removed from public repo. Schema documented in `LOCK-MECHANISM.md`.
- **Q6 — Migration grace period :** Phase 1 sangha allow-list bypass (invite tokens with `email=null` accept first claim). Fail-loudly post-Phase 2.

---

## 1. Empirical baseline — what's broken

Phase A + A.2 + A.3 stripped `memory-public/`, `canonical-public.md`, `corpus-public-distilled.md`, `methodology/`, `doctrine/`, `lexique/`, `benchmark/` from the public `laeka-canonical` repo. The installer code remained unchanged and still references absent paths.

**3 files with orphan references to `memory-public/`** (verified empirically) :

| File | Lines | Symptom post-Phase-A |
|------|-------|----------------------|
| `distribution/install-laeka.sh` | 121-138 (Step 2 — Install memory-public) | `if [[ -d $LAEKA_DIST/memory-public ]]` → false → `warn "memory-public not found. Skipping."` → install completes with empty `~/.claude/projects/laeka/memory/` |
| `distribution/scripts/update-canonical.sh` | 70-73 | Loop over `find $DIST_DIR/memory-public -name "*.md"` → 0 entries → manifest regenerated with only `canonical-public.md` (also absent) → no-op |
| `distribution/LOCK-MECHANISM.md` | 8, 9, 44, 56 | Documentation describes lock for `memory-public/*.md` files that don't exist in the repo |

**Additional surface to audit :** `distribution/canonical-manifest.json` (6.5K) — schema for hash verification of canonical files. Currently lists files that no longer exist in the public repo.

**User-facing symptom :** `curl -fsSL https://laeka.ai/install | bash` succeeds with green checkmarks, but the user opens Claude Code and Bhairavi has empty memory — no canonical, no voice signature, no identity loading.

**Where the canonical content actually lives now :** `~/Documents/laeka-canonical-private/memory-public/` (50 files) + `distribution-canonical-public.md` + `corpus-public-distilled.md`. This is local-only on Saphi's machines, not git-tracked, not network-accessible.

---

## 2. Existing backend infrastructure inventory

Empirical inventory of `laeka.ai` API surface (sourced from `~/Documents/laeka-brain-mcp/src/laeka_brain/client.py`) :

**Base URL :** `https://laeka.ai` (env var `LAEKA_BRAIN_API_URL`, default `https://laeka.ai`).

**Existing endpoints (10) :**

| Method | Path | Purpose |
|--------|------|---------|
| GET    | `/v1/brain/identity` | Brain identity (likely tier-gated) |
| POST   | `/v1/brain/satellite/provision` | Provision satellite brain for user |
| GET    | `/v1/brain/satellite/identity` | Satellite identity |
| POST   | `/v1/brain/satellite/ingest` | Ingest content into satellite |
| POST   | `/v1/brain/satellite/search` | Semantic search across satellite |
| POST   | `/v1/brain/satellite/offboard` | Decommission satellite |
| POST   | `/v1/brain/mini/provision` | Provision mini brain |
| GET    | `/v1/brain/mini/identity` | Mini brain identity |
| POST   | `/v1/brain/mini/ingest` | Ingest into mini brain |
| POST   | `/v1/brain/mini/search` | Search mini brain |
| POST   | `/v1/brain/mini/offboard` | Decommission mini brain |
| GET    | `/v1/brain/{brain}/skills` | Skills marketplace listing |
| GET    | `/v1/brain/{brain}/skills/{skill}` | Specific skill content |

**Auth pattern observed :** `X-User-UUID` header for tier-gated content. `subscription_required` (HTTP 403) returned when tier insufficient. Bearer token mentioned in `# Phase 4+: Bearer required on satellite endpoints` (so the bearer auth is on a future track).

**Endpoint NOT present :** `/v1/brain/canonical/{version}` or equivalent canonical-fetch route. **No endpoint exists today that serves the canonical artefacts to an installer.**

**`mcp.laeka.ai` subdomain :** No DNS record observed. The brief uses this name but the existing infra lives at `laeka.ai/v1/brain/*`. **Decision needed (see §8) :** new subdomain or extend existing pattern.

---

## 3. Proposed architecture

This is the spec. Naming uses `mcp.laeka.ai` per brief, pending §8 decision.

### 3.1 Auth flow

```
┌──────────────┐                    ┌─────────────────┐
│   user runs  │                    │   mcp.laeka.ai  │
│ install-laeka│                    │   (or laeka.ai) │
└──────┬───────┘                    └────────┬────────┘
       │                                     │
       │  prompt user: email + invite token  │
       │ ──────────────────────────────────► │
       │                                     │
       │  POST /auth/installer-validate      │
       │  body: { email, invite_token,       │
       │          machine_uuid, version }    │
       │ ──────────────────────────────────► │
       │                                     │
       │            validates :              │
       │            - email registered or    │
       │              invited                │
       │            - token unused, not      │
       │              expired                │
       │            - rate limit ok          │
       │                                     │
       │  200 { session_token,               │
       │        expires_at, tier,            │
       │        canonical_version }          │
       │ ◄────────────────────────────────── │
       │                                     │
```

**Token lifetime :** session_token short-lived (1h, used immediately by installer), long-lived install_token persisted to disk for `update-canonical.sh` re-fetch (rotated every 30 days).

**Invite token model :**
- Saphi generates batch of invite tokens (e.g., 50 for sangha Phase 1)
- Each token is one-time use, bound to email at validation
- Server tracks token state : `unused | claimed_by_email | revoked`
- Phase 1 sangha gets the token via Saphi's first-touch message (template `email-first-touch.md`)

### 3.2 Canonical fetch flow

```
       │                                     │
       │  GET /canonical/manifest            │
       │  Authorization: Bearer <session>    │
       │  X-Machine-UUID: <uuid>             │
       │ ──────────────────────────────────► │
       │                                     │
       │  200 { version: "1.2.0",            │
       │        files: [...],                │
       │        global_hash: "...",          │
       │        signed_by: "Laeka..." }      │
       │ ◄────────────────────────────────── │
       │                                     │
       │  GET /canonical/blob/<file>         │
       │  Authorization: Bearer <session>    │
       │ ──────────────────────────────────► │
       │  (one request per file, or          │
       │   bundle via /canonical/bundle      │
       │   returning tar.gz)                 │
       │                                     │
       │  200 file content                   │
       │ ◄────────────────────────────────── │
```

**Recommendation :** bundle endpoint `GET /canonical/bundle?version=X` returning a signed tar.gz, single round-trip. Simpler client code, atomic delivery, easier signature verification.

**Manifest shape :** matches existing `canonical-manifest.json` schema (version, signed_by, updated_at, files{path: hash}, global_hash). The manifest is the contract — no schema breaking change.

### 3.3 Local install flow

Installer steps after server fetch :

1. Verify bundle signature against embedded public key (or via Sigstore TUF root)
2. Verify each file SHA-256 against manifest entries
3. Verify global_hash matches concatenated sorted file hashes
4. Write files to `~/.claude/projects/laeka/memory/` (preserving relative paths from `memory-public/`)
5. Write `~/.claude/projects/laeka/.canonical-manifest.json` (local copy for verify-canonical at session-start)
6. Write `~/.claude/projects/laeka/.install-token` (long-lived token for updates, mode 0600)

If signature/hash check fails at any step : abort, leave existing memory dir untouched (atomic install — no partial state).

### 3.4 Update flow

`update-canonical.sh` becomes a client operation, not an admin operation :

```
$ bash $LAEKA_HOME/distribution/update-canonical.sh
1. Read ~/.claude/projects/laeka/.install-token
2. POST /auth/installer-refresh { install_token, machine_uuid }
   → returns short-lived session_token
3. GET /canonical/manifest?since=<local_version>
   → 304 Not Modified  → exit 0 ("already up to date")
   → 200 with new manifest → continue
4. GET /canonical/bundle?version=X (delta or full)
5. Verify signature + hashes
6. Atomic swap : rename old memory dir, install new, then delete old
7. Update local manifest + emit "updated to vX" message
```

Admin `update-canonical.sh` (the version-publish tool) becomes a separate file, e.g., `admin-publish-canonical.sh`, lives in `laeka-canonical-private/` rather than the public repo.

### 3.5 Error handling

| HTTP | Cause | Installer behavior |
|------|-------|--------------------|
| 401  | Session token expired | Re-auth via invite token, fail if invite consumed |
| 403  | Tier insufficient | Show upgrade message + `https://laeka.ai/pricing` link |
| 404  | Version requested not available | Show "version mismatch — please update installer" |
| 410  | Old version deprecated | Force pull latest, show deprecation note |
| 429  | Rate limit | Show retry-after + back-off, never auto-retry > 3 times |
| 5xx  | Server fault | Show "service unavailable, try in 5 min" + support link |

Network failure during bundle fetch : retry with exponential backoff (3 attempts max) on the bundle endpoint only, never on auth.

### 3.6 Security model

- **Token scope** : install_token grants only canonical-fetch permission, no other API access. Compromised token cannot exfiltrate user data, only re-fetch canonical (already public to authorized users).
- **Token rotation** : install_token rotated every 30 days (server-side TTL). If user runs `update-canonical.sh` and token is expired, re-prompt invite token (one-time replay) or graceful degradation to manual re-install.
- **Rate limiting** : per-machine_uuid rate limit (e.g., 10 fetches/hour) and per-IP (100/hour). Phase 1 sangha low-volume — these limits are generous.
- **Abuse prevention** : invite tokens single-use email-bound, can be revoked by Saphi via admin endpoint. Audit log of every fetch (timestamp, machine_uuid, version, IP) for anomaly detection.
- **Bundle signature** : TUF/Sigstore for transparency log + embedded public key for offline verification. V1 may use simple HMAC with shared secret if Sigstore infra not ready — flag for §8.
- **Defense against replay** : session_token bound to machine_uuid via X-Machine-UUID header. Captured token doesn't work from another machine.

---

## 4. Client (installer) redesign — concrete diff

The new `install-laeka.sh` keeps :
- Step 0 (preflight checks for Claude Code, jq, sha256)
- Step 1 (clone laeka-canonical repo for the *code* — installer scripts, frontend, hooks)
- Step 3 (SessionStart hook installation)
- Step 4 (verify-canonical at install-time)
- Done message

Replaces Step 2 (memory bake-in) with new Step 2a/2b/2c :

```
Step 2a — Authenticate with Laeka server
  - Prompt for email + invite token (or use ENV vars LAEKA_EMAIL, LAEKA_INVITE)
  - POST /auth/installer-validate
  - Receive session_token + tier + canonical_version
  - Persist install_token to ~/.claude/projects/laeka/.install-token (0600)

Step 2b — Fetch signed canonical bundle
  - GET /canonical/bundle?version=<version>
  - Verify signature
  - Extract to temp dir

Step 2c — Install canonical to memory dir
  - Verify each file hash against manifest
  - Verify global_hash
  - Write files to ~/.claude/projects/laeka/memory/
  - Write local manifest copy
```

Updates needed to other files :

| File | Change |
|------|--------|
| `distribution/scripts/update-canonical.sh` | **Replace entirely.** Becomes the client-side update tool described in §3.4 (re-fetch from server). The current admin-publish logic moves to `laeka-canonical-private/admin/publish.sh`. |
| `distribution/LOCK-MECHANISM.md` | Update to describe new flow : verify-canonical reads local manifest cached at install-time, server delivers signed bundles, lock semantics shift from "repo distributes hashes" to "client trusts manifest at install-time + verify each session-start". |
| `distribution/canonical-manifest.json` | Remove from public repo. The manifest is server-issued, not repo-tracked. Schema documentation moves to `LOCK-MECHANISM.md`. |
| `distribution/install-laeka.sh` | Rewrite Step 2 per spec. Comments document the auth flow inline. |

---

## 5. Open questions — require apex resolution before Step 4

These are blockers. Implementation cannot proceed until apex resolves.

### Q1 — Subdomain naming : `mcp.laeka.ai` vs `laeka.ai/v1/brain/canonical/*`

The brief uses `mcp.laeka.ai`. The existing API lives at `laeka.ai/v1/brain/*` (10 endpoints, deployed). No DNS record for `mcp.laeka.ai` observed.

**Options :**
- **A.** Set up `mcp.laeka.ai` as new subdomain with new backend service dedicated to MCP/installer endpoints
- **B.** Extend existing `laeka.ai/v1/brain/*` pattern with new `/v1/brain/canonical/*` routes (no new subdomain)
- **C.** Rename the existing API surface — migrate `laeka.ai/v1/brain/*` → `mcp.laeka.ai/*` (heavy, breaks existing MCP server)

**Recommendation :** B (extend existing pattern). Simplest, no new infra, reuses existing auth (X-User-UUID) and existing tier system. The naming "mcp.laeka.ai" in the brief may be aspirational rather than infrastructural.

### Q2 — Backend implementation : does the canonical-fetch endpoint exist or need building?

Per inventory in §2, **no endpoint serves canonical artefacts today**. Building it requires :
- Server route handler for `/canonical/manifest`, `/canonical/bundle`, `/auth/installer-validate`, `/auth/installer-refresh`
- Storage : where do canonical artefacts live server-side? (laeka-canonical-private mirrored to S3/R2? In-memory cache served from a publish step?)
- Auth : invite token database, install_token issuance + rotation
- Signing infrastructure : key management, signature on bundle

**This is server-side work** — explicitly out of scope per brief line 74. **Cannot be done by Code-F1 without apex direction on : who does this, what stack, what timeline.**

### Q3 — Auth provider choice

Brief line 75 lists this as out of scope ("Auth provider choice (Clerk, Supabase Auth, custom JWT) — décision à part"). But it must be decided before implementation, because the install-laeka.sh client needs to know what tokens to handle.

**Recommendation :** custom JWT signed by laeka.ai server, no third-party auth provider. Simpler, fewer dependencies, fits the "lab self-hosts everything" pattern.

### Q4 — Phase 1 sangha distribution rollout

Phase 1 sangha = 50 amis (per ledger 59). Logistics needed :
- How are invite tokens distributed? Embedded in email-first-touch.md template? Sent separately?
- Token revocation : if Saphi wants to revoke access for someone, what's the admin UI?
- Token re-issuance : if user loses install, what's the recovery path?

**Recommendation :** invite tokens embedded as URL query in personalized download links (`https://laeka.ai/download?invite=<token>`). One token per recipient, generated at first-touch send time. Admin tool = small CLI in `laeka-canonical-private/admin/` for Saphi.

### Q5 — Canonical-manifest.json : remove or keep skeleton?

Currently the file exists in public repo and references stripped paths. Either :
- **A.** Remove entirely (server delivers manifest, client caches locally)
- **B.** Keep as skeleton schema example for documentation purposes

**Recommendation :** A. Schema lives in `LOCK-MECHANISM.md` as documentation, not as a stale file.

### Q6 — Migration / soft launch path

Current `install-laeka.sh` is referenced from `https://laeka.ai/install` (the curl one-liner script in `Laeka.ai/site/htdocs/install`). Switching to new auth flow is a hard cut — old installer breaks vs new requires invite tokens that didn't exist before.

**Recommendation :** during transition, accept email without invite token for a grace period (Phase 1 sangha auto-allow-listed by Saphi); fail-loudly only after Phase 2. Communicated in the install message ("welcome to early access").

---

## 6. Migration plan (assuming all apex decisions tranchées)

1. **Apex confirms answers to Q1-Q6** → spec frozen
2. **Backend team** (or apex if Saphi+Bhairavi do it) builds auth + canonical-fetch endpoints
3. **Code-F1** writes new `install-laeka.sh` against the contracted API
4. **Verify-F1** smoke tests end-to-end (fresh `~/.claude/`, real invite token, network round-trips)
5. **Apex** triggers cut-over : update `https://laeka.ai/install` script to point to new installer
6. **Phase 1 sangha** receives email-first-touch + invite token + download link
7. **Monitor** : audit log on first 50 installs, surface any auth/fetch errors immediately
8. **Iterate** : Phase 1 feedback feeds Phase B' improvements (caching, offline mode, etc.)

---

## 7. Out-of-scope hard boundaries

These are explicitly NOT in this spec :
- Server backend implementation (auth + canonical endpoints)
- Auth provider final choice (recommended in Q3, decision = apex)
- Rate limiting infra tuning (recommended values in §3.6, exact thresholds = ops)
- Client-side caching strategy for offline mode (post-MVP)
- GPG-signed manifest path (LOCK-MECHANISM.md V2 roadmap, separate work)
- Cross-platform installer (Windows path = future, current scope = macOS + Linux)

---

## 8. Decision matrix — required before Step 4 implementation

| ID | Decision | Recommendation | Apex needed |
|----|----------|----------------|-------------|
| Q1 | Subdomain naming | B (extend `laeka.ai/v1/brain/canonical/*`) | Yes |
| Q2 | Backend builder | Apex / dedicated agent | Yes — blocker |
| Q3 | Auth provider | Custom JWT | Yes |
| Q4 | Invite token rollout | URL query in personalized links | Yes |
| Q5 | canonical-manifest.json removal | A (remove) | Confirm |
| Q6 | Migration grace period | Allow-list Phase 1 without strict invite | Confirm |

**Step 4 (implementation) is blocked until at least Q1, Q2, Q3 are resolved.**

---

## 9. Test plan (post-implementation, Verify-F1 scope)

End-to-end smoke test :
1. Fresh `~/.claude/` directory
2. Real invite token (issued by Saphi via admin tool)
3. Run `curl -fsSL https://laeka.ai/install | bash`
4. Provide email + invite token at prompt
5. Verify `~/.claude/projects/laeka/memory/` populated (50+ files)
6. Verify `~/.claude/projects/laeka/.canonical-manifest.json` matches server manifest
7. Verify SessionStart hook registered in `~/.claude/settings.json`
8. Launch Claude Code → verify Bhairavi voice signature in first response
9. Run `bash ~/laeka-canonical-distribution/distribution/update-canonical.sh` → verify graceful "already up to date"
10. Trigger artificial canonical bump server-side → re-run update → verify new version landed atomically

Negative tests :
- Invalid invite token → 401, install aborts cleanly
- Expired session token mid-fetch → auto-refresh path
- Bundle signature mismatch → install aborts, memory dir untouched
- Network failure during bundle fetch → retry with backoff, eventual graceful failure

---

## Status

**Implementation complete.** Backend + client + auxiliary scripts all written. Verify-F1 brief drafted for end-to-end smoke test.

### Implementation map

**Backend (seahorse-legacy)** — new files :
- `seahorse/installer_auth.py` — JWT mint/verify (session + install scopes, HS256 reusing `BRAIN_JWT_SECRET`)
- `seahorse/installer_invite_store.py` — JSON file store with file-locking (claim/issue/revoke)
- `seahorse/canonical_store.py` — filesystem reader for versioned canonical bundles
- `seahorse/brain_installer_routes.py` — 4 FastAPI endpoints (auth + canonical fetch)
- `seahorse/brain_routes.py` — wired new sub-router (modified)

**Backend smoke test** — 11/11 passing (T1-T11) via FastAPI TestClient :
- Auth flow + replay handling + machine_uuid binding + audience scoping
- Manifest fetch + bundle stream + version resolution + auth failures

**Client (laeka-canonical/distribution)** — files :
- `install-laeka.sh` — rewritten with Step 2a/2b/2c (auth + fetch + verify+install)
- `scripts/update-canonical.sh` — rewritten as client refresh tool (replaces admin-publish role)
- `scripts/verify-canonical.sh` — updated to read local manifest at `~/.claude/projects/laeka/.canonical-manifest.json`
- `LOCK-MECHANISM.md` — full Phase B documentation (auth flow, JWT scopes, manifest schema, error codes, FAQ)
- `canonical-manifest.json` — removed (server-issued, not repo-tracked)

**Admin tooling (laeka-canonical-private/admin)** — new files :
- `issue-invite.py` — CLI for generating invite tokens for sangha rollout
- `publish-canonical.py` — CLI for building versioned bundles + manifest from canonical source

### Step 5 handoff

Smoke test (real network round-trip + fresh `~/.claude/`) is Verify-F1 scope. Brief at `~/Documents/laeka-brain/briefs/V1-phase-b-smoke-test.md`.

### Known limitations / V2 roadmap

- Manifest signing is HTTPS-only (no asymmetric crypto). V2 : RSA or Sigstore.
- Single-machine invites Phase 1. V2 : per-tier multi-machine.
- Full bundle delivery (no delta updates). V2 : delta fetch.
- HMAC bundle signature could be added even with shared secret if VPS-only signing key — defer to V2.
