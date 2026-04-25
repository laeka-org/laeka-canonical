#!/usr/bin/env bash
# uninstall-laeka.sh — Remove Laeka from Claude Code
# Cleans 100% of installed artefacts. Backups preserved at original paths + .laeka-backup-* suffix.
#
# Usage: bash ~/laeka-canonical-distribution/distribution/uninstall-laeka.sh [--confirm]

set -euo pipefail

LAEKA_HOME="$HOME/laeka-canonical-distribution"
MEMORY_DIR="$HOME/.claude/projects/laeka"
CLIENT_HOOK="$HOME/.claude/laeka-session-start.sh"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
BACKUP_SUFFIX=".laeka-backup-$(date +%Y%m%d-%H%M%S)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'

info()    { echo -e "${CYAN}[laeka-uninstall]${NC} $*"; }
ok()      { echo -e "${GREEN}[laeka-uninstall] ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}[laeka-uninstall] ⚠${NC} $*"; }
err()     { echo -e "${RED}[laeka-uninstall] ✗${NC} $*" >&2; }
section() { echo -e "\n${BLUE}──────────────────────────────────────${NC}"; echo -e "${BLUE}  $*${NC}"; echo -e "${BLUE}──────────────────────────────────────${NC}"; }

section "Laeka Uninstaller"
echo ""
echo "This will remove:"
echo "  • $LAEKA_HOME"
echo "  • $MEMORY_DIR"
echo "  • $CLIENT_HOOK"
echo "  • SessionStart hook from ~/.claude/settings.json"
echo ""

# Confirm unless --confirm flag provided
if [[ "${1:-}" != "--confirm" ]]; then
    read -r -p "Proceed? [y/N]: " CONFIRM
    case "$CONFIRM" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

# ── Remove hook from settings.json ──────────────────────────────────────────
section "Removing SessionStart hook"

if [[ -f "$CLAUDE_SETTINGS" ]] && command -v jq &>/dev/null; then
    if jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | test("laeka-session-start"))' "$CLAUDE_SETTINGS" &>/dev/null 2>&1; then
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS${BACKUP_SUFFIX}"
        UPDATED=$(jq '
            if .hooks.SessionStart then
                .hooks.SessionStart[0].hooks = [
                    .hooks.SessionStart[0].hooks[] |
                    select(.command | test("laeka-session-start") | not)
                ]
            else . end
        ' "$CLAUDE_SETTINGS")
        echo "$UPDATED" > "$CLAUDE_SETTINGS"
        ok "Hook removed from settings.json"
        info "settings.json backup: $CLAUDE_SETTINGS${BACKUP_SUFFIX}"
    else
        info "Hook not found in settings.json — skipping"
    fi
else
    warn "settings.json not found or jq missing — hook not removed automatically."
    warn "Remove manually: delete the laeka-session-start entry from ~/.claude/settings.json"
fi

# ── Remove hook script ───────────────────────────────────────────────────────
section "Removing hook script"

if [[ -f "$CLIENT_HOOK" ]]; then
    rm -f "$CLIENT_HOOK"
    ok "Removed: $CLIENT_HOOK"
else
    info "Hook script not found — skipping"
fi

# ── Remove memory ────────────────────────────────────────────────────────────
section "Removing Laeka memory"

if [[ -d "$MEMORY_DIR" ]]; then
    rm -rf "$MEMORY_DIR"
    ok "Removed: $MEMORY_DIR"
else
    info "Memory directory not found — skipping"
fi

# ── Remove distribution ──────────────────────────────────────────────────────
section "Removing distribution"

if [[ -d "$LAEKA_HOME" ]]; then
    rm -rf "$LAEKA_HOME"
    ok "Removed: $LAEKA_HOME"
else
    info "Distribution not found — skipping"
fi

# ── Remove settings.json backups (offer) ────────────────────────────────────
BACKUP_COUNT=$(find "$HOME/.claude" -name "settings.json.laeka-backup-*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$BACKUP_COUNT" -gt 0 ]]; then
    warn "$BACKUP_COUNT settings.json backup(s) in ~/.claude/ — remove manually if desired."
    find "$HOME/.claude" -name "settings.json.laeka-backup-*" | sed 's/^/    /'
fi

section "Uninstall complete"
echo ""
echo -e "  Laeka has been removed from this machine."
echo -e "  Reinstall anytime: ${CYAN}curl -fsSL https://laeka.ai/install | bash${NC}"
echo ""
