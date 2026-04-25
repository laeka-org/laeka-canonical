#!/usr/bin/env bash
# update-laeka.sh — Update Laeka distribution to latest canonical version
# Pulls latest from GitHub, re-verifies integrity, keeps hook in place.
#
# Usage: bash ~/laeka-canonical-distribution/distribution/update-laeka.sh

set -euo pipefail

LAEKA_HOME="$HOME/laeka-canonical-distribution"
LAEKA_DIST="$LAEKA_HOME/distribution"
LAEKA_SCRIPTS="$LAEKA_DIST/scripts"
MEMORY_DIR="$HOME/.claude/projects/laeka/memory"
CLIENT_HOOK="$HOME/.claude/laeka-session-start.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[laeka-update]${NC} $*"; }
ok()      { echo -e "${GREEN}[laeka-update] ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}[laeka-update] ⚠${NC} $*" >&2; }
err()     { echo -e "${RED}[laeka-update] ✗${NC} $*" >&2; }
section() { echo -e "\n${BLUE}──────────────────────────────────────${NC}"; echo -e "${BLUE}  $*${NC}"; echo -e "${BLUE}──────────────────────────────────────${NC}"; }

# ── Preflight ─────────────────────────────────────────────────────────────────
section "Laeka Update"

if [[ ! -d "$LAEKA_HOME" ]]; then
    err "Laeka not installed at $LAEKA_HOME"
    err "Run the installer first: bash install-laeka.sh"
    exit 1
fi

if [[ ! -d "$LAEKA_HOME/.git" ]]; then
    err "Installation was not via git clone — cannot auto-update."
    err "Re-run install-laeka.sh to reinstall."
    exit 1
fi

if ! command -v git &>/dev/null; then
    err "git required for updates."
    exit 1
fi

# ── Pull latest ───────────────────────────────────────────────────────────────
section "Pulling latest distribution"

BEFORE=$(git -C "$LAEKA_HOME" rev-parse HEAD)
git -C "$LAEKA_HOME" pull --quiet origin main
AFTER=$(git -C "$LAEKA_HOME" rev-parse HEAD)

if [[ "$BEFORE" == "$AFTER" ]]; then
    ok "Already at latest ($(git -C "$LAEKA_HOME" log -1 --format='%h %s'))"
else
    ok "Updated: $BEFORE → $AFTER"
    info "Changes:"
    git -C "$LAEKA_HOME" log --oneline "${BEFORE}..${AFTER}" | sed 's/^/    /'
fi

chmod +x "$LAEKA_SCRIPTS"/*.sh

# ── Sync memory-public ───────────────────────────────────────────────────────
section "Syncing memory"

if [[ -d "$LAEKA_DIST/memory-public" && -d "$MEMORY_DIR" ]]; then
    cp -r "$LAEKA_DIST/memory-public/." "$MEMORY_DIR/"
    COUNT=$(find "$MEMORY_DIR" -name "*.md" | wc -l | tr -d ' ')
    ok "Memory synced: ${COUNT} files"
elif [[ ! -d "$MEMORY_DIR" ]]; then
    warn "Memory directory not found ($MEMORY_DIR). Re-run install-laeka.sh to restore."
fi

# ── Verify hook still in place ───────────────────────────────────────────────
section "Checking hook"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLIENT_HOOK" ]]; then
    ok "Hook script present: $CLIENT_HOOK"
else
    warn "Hook script missing. Re-run install-laeka.sh to restore."
fi

if command -v jq &>/dev/null && [[ -f "$CLAUDE_SETTINGS" ]]; then
    if jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | test("laeka-session-start"))' "$CLAUDE_SETTINGS" &>/dev/null 2>&1; then
        ok "Hook registered in settings.json"
    else
        warn "Hook not found in settings.json. Re-run install-laeka.sh to restore."
    fi
fi

# ── Verify integrity ─────────────────────────────────────────────────────────
section "Verifying canonical integrity"

VERIFY_EXIT=0
bash "$LAEKA_SCRIPTS/verify-canonical.sh" || VERIFY_EXIT=$?

case $VERIFY_EXIT in
    0) ok "All canonical files verified" ;;
    3) warn "Lock disabled (admin override)" ;;
    2) warn "Integrity check skipped: missing dependency" ;;
    *) err "Integrity check FAILED after update."; err "Rollback: git -C $LAEKA_HOME checkout HEAD~1"; exit 1 ;;
esac

section "Update complete"
echo ""
VERSION=$(jq -r '.version // "unknown"' "$LAEKA_DIST/canonical-manifest.json" 2>/dev/null || echo "unknown")
echo -e "  Canonical version: ${GREEN}v${VERSION}${NC}"
echo -e "  Distribution:      $LAEKA_HOME"
echo ""
