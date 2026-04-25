#!/usr/bin/env bash
# install-laeka.sh — Laeka Claude Code Installer v2
# One-click setup: downloads canonical distribution, installs identity hook + memory.
#
# Usage:
#   curl -fsSL https://laeka.ai/install | bash
#   # OR download and run locally:
#   bash install-laeka.sh
#
# Requirements: Claude Code, bash 4+, jq, git (or curl for tar.gz fallback)
# Platforms: macOS, Linux

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
LAEKA_REPO="https://github.com/laeka-org/laeka-canonical.git"
LAEKA_REPO_TARBALL="https://github.com/laeka-org/laeka-canonical/archive/refs/heads/main.tar.gz"
LAEKA_HOME="$HOME/laeka-canonical-distribution"
LAEKA_DIST="$LAEKA_HOME/distribution"
LAEKA_SCRIPTS="$LAEKA_DIST/scripts"
MEMORY_DIR="$HOME/.claude/projects/laeka/memory"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
CLIENT_HOOK="$HOME/.claude/laeka-session-start.sh"
BACKUP_SUFFIX=".laeka-backup-$(date +%Y%m%d-%H%M%S)"

# ── Output helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[laeka]${NC} $*"; }
ok()      { echo -e "${GREEN}[laeka] ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}[laeka] ⚠${NC} $*" >&2; }
err()     { echo -e "${RED}[laeka] ✗${NC} $*" >&2; }
section() { echo -e "\n${BLUE}──────────────────────────────────────${NC}"; echo -e "${BLUE}  $*${NC}"; echo -e "${BLUE}──────────────────────────────────────${NC}"; }

# ── Step 0 — Preflight ───────────────────────────────────────────────────────
section "Laeka Installer v2"
info "Target: $LAEKA_HOME"
info "Memory: $MEMORY_DIR"
echo ""

# Claude Code
if ! command -v claude &>/dev/null; then
    err "Claude Code CLI not found."
    err "Install from: https://claude.ai/code"
    exit 1
fi
ok "Claude Code: $(claude --version 2>/dev/null | head -1 || echo 'installed')"

# settings.json
if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    err "~/.claude/settings.json not found."
    err "Launch Claude Code once to initialise, then re-run."
    exit 1
fi
ok "~/.claude/settings.json found"

# jq
if ! command -v jq &>/dev/null; then
    err "jq is required."
    [[ "$(uname)" == "Darwin" ]] && err "  brew install jq" || err "  sudo apt-get install jq"
    exit 1
fi
ok "jq found"

# sha256
if ! command -v sha256sum &>/dev/null && ! command -v shasum &>/dev/null; then
    err "sha256sum or shasum required for integrity verification."
    exit 1
fi
ok "sha256 utility found"

# download method
HAS_GIT=false; HAS_CURL=false
command -v git  &>/dev/null && HAS_GIT=true
command -v curl &>/dev/null && HAS_CURL=true
if [[ "$HAS_GIT" == "false" && "$HAS_CURL" == "false" ]]; then
    err "git or curl required to download distribution."
    exit 1
fi

# ── Step 1 — Download ────────────────────────────────────────────────────────
section "Downloading Laeka distribution"

if [[ -d "$LAEKA_HOME/.git" ]]; then
    info "Existing git clone found — updating..."
    git -C "$LAEKA_HOME" pull --quiet origin main
    ok "Updated to latest"
elif [[ -d "$LAEKA_HOME" ]]; then
    warn "Directory exists without git. Backing up and reinstalling..."
    mv "$LAEKA_HOME" "${LAEKA_HOME}${BACKUP_SUFFIX}"
    ok "Backed up to: ${LAEKA_HOME}${BACKUP_SUFFIX}"
    # fall through to fresh clone
fi

if [[ ! -d "$LAEKA_HOME" ]]; then
    if [[ "$HAS_GIT" == "true" ]]; then
        info "Cloning from GitHub..."
        git clone --quiet --depth 1 "$LAEKA_REPO" "$LAEKA_HOME"
        ok "Cloned to $LAEKA_HOME"
    else
        info "Downloading archive (git not available, using curl)..."
        TMP_TAR=$(mktemp /tmp/laeka-dist-XXXXXX.tar.gz)
        curl -fsSL "$LAEKA_REPO_TARBALL" -o "$TMP_TAR"
        mkdir -p "$LAEKA_HOME"
        tar xzf "$TMP_TAR" --strip-components=1 -C "$LAEKA_HOME"
        rm -f "$TMP_TAR"
        ok "Downloaded to $LAEKA_HOME"
    fi
fi

# Validate distribution contents
if [[ ! -f "$LAEKA_SCRIPTS/verify-canonical.sh" ]]; then
    err "Distribution incomplete — verify-canonical.sh missing."
    err "Try re-running the installer."
    exit 1
fi
chmod +x "$LAEKA_SCRIPTS"/*.sh
ok "Scripts executable"

# ── Step 2 — Install memory-public ──────────────────────────────────────────
section "Installing Laeka memory"

mkdir -p "$MEMORY_DIR"

if [[ -d "$LAEKA_DIST/memory-public" ]]; then
    # Backup existing MEMORY.md if it's not already Laeka-managed
    if [[ -f "$MEMORY_DIR/MEMORY.md" ]] && ! grep -qi "laeka" "$MEMORY_DIR/MEMORY.md" 2>/dev/null; then
        cp "$MEMORY_DIR/MEMORY.md" "$MEMORY_DIR/MEMORY.md${BACKUP_SUFFIX}"
        warn "Non-Laeka MEMORY.md backed up: MEMORY.md${BACKUP_SUFFIX}"
    fi

    cp -r "$LAEKA_DIST/memory-public/." "$MEMORY_DIR/"
    COUNT=$(find "$MEMORY_DIR" -name "*.md" | wc -l | tr -d ' ')
    ok "Installed ${COUNT} memory files → $MEMORY_DIR"
else
    warn "memory-public not found in distribution. Skipping."
fi

# ── Step 3 — Install SessionStart hook ──────────────────────────────────────
section "Installing SessionStart hook"

# Write client hook (uses literal $HOME so it expands at runtime, not install time)
cat > "$CLIENT_HOOK" << 'HOOK_SCRIPT'
#!/usr/bin/env bash
# laeka-session-start.sh — Auto-generated by Laeka Installer v2
# Loads Laeka canonical identity into session context + verifies integrity.
set -uo pipefail

LAEKA_DIST="$HOME/laeka-canonical-distribution/distribution"
VERIFY="$LAEKA_DIST/scripts/verify-canonical.sh"
CANONICAL="$LAEKA_DIST/canonical-public.md"

# Integrity check (non-fatal: warn on exit 2/3, block on exit 1)
if [[ -f "$VERIFY" ]]; then
    bash "$VERIFY" 2>&1
    VERIFY_EXIT=$?
    if [[ $VERIFY_EXIT -eq 1 ]]; then
        echo "[laeka] Session blocked: canonical integrity violated." >&2
        exit 1
    fi
fi

# Load canonical into session context via stdout
if [[ -f "$CANONICAL" ]]; then
    echo ""
    cat "$CANONICAL"
    echo ""
fi
HOOK_SCRIPT

chmod +x "$CLIENT_HOOK"
ok "Hook script: $CLIENT_HOOK"

# Inject into settings.json (idempotent check)
if jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | test("laeka-session-start"))' "$CLAUDE_SETTINGS" &>/dev/null 2>&1; then
    ok "Hook already registered in settings.json — skipping"
else
    cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS${BACKUP_SUFFIX}"
    NEW_HOOK=$(jq -n --arg cmd "bash $CLIENT_HOOK" '{type: "command", command: $cmd, timeout: 15}')
    UPDATED=$(jq --argjson hook "$NEW_HOOK" '
        if .hooks.SessionStart then
            .hooks.SessionStart[0].hooks = [$hook] + (.hooks.SessionStart[0].hooks // [])
        else
            .hooks.SessionStart = [{"hooks": [$hook]}]
        end
    ' "$CLAUDE_SETTINGS")
    echo "$UPDATED" > "$CLAUDE_SETTINGS"
    ok "Hook registered in ~/.claude/settings.json"
    info "settings.json backup: $CLAUDE_SETTINGS${BACKUP_SUFFIX}"
fi

# ── Step 4 — Verify integrity ────────────────────────────────────────────────
section "Verifying canonical integrity"

VERIFY_EXIT=0
bash "$LAEKA_SCRIPTS/verify-canonical.sh" || VERIFY_EXIT=$?

case $VERIFY_EXIT in
    0) ok "All canonical files verified" ;;
    3) warn "Lock disabled (admin override) — skipping verification" ;;
    2) warn "Integrity check skipped: missing dependency (jq/shasum). Install and re-run to verify." ;;
    *) err "Integrity check FAILED. Distribution may be corrupted."; err "Re-run installer or contact support@laeka.ai"; exit 1 ;;
esac

# ── Done ─────────────────────────────────────────────────────────────────────
section "Installation complete"
echo ""
echo -e "  ${GREEN}✓${NC} Distribution  $LAEKA_HOME"
echo -e "  ${GREEN}✓${NC} Memory        $MEMORY_DIR"
echo -e "  ${GREEN}✓${NC} Hook          $CLIENT_HOOK"
echo ""
echo -e "  ${CYAN}Next:${NC} Launch Claude Code — Laeka loads automatically at session start."
echo ""
echo -e "  Update:     bash $LAEKA_HOME/distribution/update-laeka.sh"
echo -e "  Uninstall:  bash $LAEKA_HOME/distribution/uninstall-laeka.sh"
echo -e "  Support:    https://laeka.ai/support"
echo ""
