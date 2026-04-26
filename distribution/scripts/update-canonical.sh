#!/usr/bin/env bash
# update-canonical.sh — Phase B client tool: refresh canonical from server.
#
# Replaces the previous admin-publish version (which now lives in
# laeka-canonical-private/admin/publish-canonical.py).
#
# Reads the persisted install_token, refreshes session, fetches manifest+bundle,
# verifies hashes, atomically swaps the local memory dir.
#
# Usage:
#   bash update-canonical.sh
#   # or with explicit version:
#   bash update-canonical.sh --version 1.2.0
#
# Requires: jq, curl, tar, sha256sum (Linux) or shasum (macOS).

set -euo pipefail

LAEKA_API_BASE="${LAEKA_API_BASE:-https://laeka.ai}"
LAEKA_STATE="$HOME/.claude/projects/laeka"
INSTALL_TOKEN_FILE="$LAEKA_STATE/.install-token"
LOCAL_MANIFEST="$LAEKA_STATE/.canonical-manifest.json"
MACHINE_UUID_FILE="$LAEKA_STATE/.machine-uuid"
MEMORY_DIR="$LAEKA_STATE/memory"

# ── Output helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${CYAN}[laeka]${NC} $*"; }
ok()   { echo -e "${GREEN}[laeka] ✓${NC} $*"; }
warn() { echo -e "${YELLOW}[laeka] ⚠${NC} $*" >&2; }
err()  { echo -e "${RED}[laeka] ✗${NC} $*" >&2; }

sha256() {
    if command -v sha256sum &>/dev/null; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        err "sha256sum or shasum required" && exit 1
    fi
}

# ── Args ──────────────────────────────────────────────────────────────────────
TARGET_VERSION="latest"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) TARGET_VERSION="$2"; shift 2 ;;
        --help) echo "Usage: bash update-canonical.sh [--version X.Y.Z]"; exit 0 ;;
        *) err "Unknown arg: $1"; exit 1 ;;
    esac
done

# ── Preflight ─────────────────────────────────────────────────────────────────
[[ -f "$INSTALL_TOKEN_FILE" ]] || { err "No install token found. Re-run install-laeka.sh."; exit 1; }
[[ -f "$MACHINE_UUID_FILE" ]] || { err "No machine UUID. Re-run install-laeka.sh."; exit 1; }
command -v jq &>/dev/null || { err "jq required"; exit 1; }
command -v curl &>/dev/null || { err "curl required"; exit 1; }

INSTALL_TOKEN=$(cat "$INSTALL_TOKEN_FILE")
MACHINE_UUID=$(cat "$MACHINE_UUID_FILE")

# ── Refresh session ───────────────────────────────────────────────────────────
info "Refreshing session..."
REFRESH_RESP=$(curl -fsS -X POST "$LAEKA_API_BASE/v1/brain/auth/installer-refresh" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg t "$INSTALL_TOKEN" --arg m "$MACHINE_UUID" '{install_token: $t, machine_uuid: $m}')") || {
    err "Refresh failed. Install token may be expired (>30 days). Re-run install-laeka.sh to re-authenticate."
    exit 1
}

SESSION_TOKEN=$(echo "$REFRESH_RESP" | jq -r '.session_token')
SERVER_VERSION=$(echo "$REFRESH_RESP" | jq -r '.canonical_version // "latest"')
[[ -n "$SESSION_TOKEN" && "$SESSION_TOKEN" != "null" ]] || { err "No session token"; exit 1; }

# ── Compare local vs server version ───────────────────────────────────────────
LOCAL_VERSION=""
if [[ -f "$LOCAL_MANIFEST" ]]; then
    LOCAL_VERSION=$(jq -r '.version // empty' "$LOCAL_MANIFEST")
fi

if [[ "$TARGET_VERSION" == "latest" ]]; then
    TARGET_VERSION="$SERVER_VERSION"
fi

if [[ -n "$LOCAL_VERSION" && "$LOCAL_VERSION" == "$TARGET_VERSION" ]]; then
    ok "Already at version $LOCAL_VERSION — nothing to do."
    exit 0
fi

info "Local: ${LOCAL_VERSION:-none} → server: $TARGET_VERSION"

# ── Fetch + verify ────────────────────────────────────────────────────────────
TMP_DIR=$(mktemp -d /tmp/laeka-update-XXXXXX)
trap "rm -rf $TMP_DIR" EXIT

info "Fetching manifest..."
curl -fsS "$LAEKA_API_BASE/v1/brain/canonical/manifest?version=$TARGET_VERSION" \
    -H "Authorization: Bearer $SESSION_TOKEN" \
    -o "$TMP_DIR/manifest.json" || { err "Manifest fetch failed"; exit 1; }

EXPECTED_GLOBAL=$(jq -r '.global_hash' "$TMP_DIR/manifest.json")

info "Fetching bundle..."
curl -fsS "$LAEKA_API_BASE/v1/brain/canonical/bundle?version=$TARGET_VERSION" \
    -H "Authorization: Bearer $SESSION_TOKEN" \
    -o "$TMP_DIR/bundle.tar.gz" || { err "Bundle fetch failed"; exit 1; }

mkdir -p "$TMP_DIR/extract"
tar xzf "$TMP_DIR/bundle.tar.gz" -C "$TMP_DIR/extract"

# Verify each file
FAILS=0
while IFS= read -r entry; do
    rel=$(echo "$entry" | jq -r '.key')
    expected=$(echo "$entry" | jq -r '.value')
    file="$TMP_DIR/extract/$rel"
    [[ -f "$file" ]] || { err "Missing: $rel"; FAILS=$((FAILS + 1)); continue; }
    actual=$(sha256 "$file")
    [[ "$actual" == "$expected" ]] || { err "Hash mismatch on $rel"; FAILS=$((FAILS + 1)); }
done < <(jq -c '.files | to_entries[]' "$TMP_DIR/manifest.json")

[[ $FAILS -eq 0 ]] || { err "Verification FAILED ($FAILS errors). Aborting. Memory dir untouched."; exit 1; }

# Verify global hash
GLOBAL_INPUT=$(jq -r '.files | to_entries | sort_by(.key) | map("\(.value)  \(.key)") | join("\n")' "$TMP_DIR/manifest.json")
COMPUTED_GLOBAL=$(printf "%s\n" "$GLOBAL_INPUT" | { command -v sha256sum &>/dev/null && sha256sum || shasum -a 256; } | awk '{print $1}')
[[ "$COMPUTED_GLOBAL" == "$EXPECTED_GLOBAL" ]] || { err "Global hash mismatch — manifest tampered"; exit 1; }

ok "Verified ($(jq -r '.files | length' "$TMP_DIR/manifest.json") files)"

# ── Atomic swap ───────────────────────────────────────────────────────────────
info "Installing v$TARGET_VERSION..."

# Build new memory dir in temp, then swap
NEW_MEM="$TMP_DIR/new-memory"
mkdir -p "$NEW_MEM"
[[ -d "$TMP_DIR/extract/memory-public" ]] && cp -r "$TMP_DIR/extract/memory-public/." "$NEW_MEM/"
[[ -f "$TMP_DIR/extract/canonical-public.md" ]] && cp "$TMP_DIR/extract/canonical-public.md" "$NEW_MEM/"

# Swap (preserves any non-canonical user files in the old dir? No — old gets renamed first)
OLD_MEM_BAK="$LAEKA_STATE/.memory-backup-$(date +%Y%m%d-%H%M%S)"
if [[ -d "$MEMORY_DIR" ]]; then
    mv "$MEMORY_DIR" "$OLD_MEM_BAK"
fi
mv "$NEW_MEM" "$MEMORY_DIR"

# Update local manifest
cp "$TMP_DIR/manifest.json" "$LOCAL_MANIFEST"

ok "Updated to v$TARGET_VERSION"
info "Old memory backed up at: $OLD_MEM_BAK"
info "Restart Claude Code to load the new canonical."
