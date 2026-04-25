#!/usr/bin/env bash
# install-hook.sh — Install Laeka canonical integrity check as Claude Code SessionStart hook
# Adds verify-canonical.sh to ~/.claude/settings.json SessionStart hooks
#
# Usage: ./install-hook.sh [--dist-dir /path/to/distribution]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${1:-$(dirname "$SCRIPT_DIR")}"
VERIFY_SCRIPT="$SCRIPT_DIR/verify-canonical.sh"
SETTINGS="$HOME/.claude/settings.json"
SETTINGS_BACKUP="${SETTINGS}.laeka-lock-backup"

# Validate
if [[ ! -f "$VERIFY_SCRIPT" ]]; then
    echo "ERROR: verify-canonical.sh not found at $VERIFY_SCRIPT" >&2
    exit 1
fi

if [[ ! -f "$SETTINGS" ]]; then
    echo "ERROR: ~/.claude/settings.json not found. Install Claude Code first." >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq required. Install with: brew install jq" >&2
    exit 1
fi

chmod +x "$VERIFY_SCRIPT"

# Backup current settings
cp "$SETTINGS" "$SETTINGS_BACKUP"
echo "Backed up settings to: $SETTINGS_BACKUP"

# Check if hook already installed
if jq -e ".hooks.SessionStart[0].hooks[] | select(.command | contains(\"verify-canonical.sh\"))" "$SETTINGS" &>/dev/null; then
    echo "Hook already installed. Nothing to do."
    exit 0
fi

# Build the new hook entry
NEW_HOOK=$(jq -n --arg cmd "bash $VERIFY_SCRIPT" '{type: "command", command: $cmd, timeout: 10}')

# Inject into SessionStart[0].hooks array (prepend so it runs first)
UPDATED=$(jq --argjson hook "$NEW_HOOK" '
    if .hooks.SessionStart then
        .hooks.SessionStart[0].hooks = [$hook] + (.hooks.SessionStart[0].hooks // [])
    else
        .hooks.SessionStart = [{"hooks": [$hook]}]
    end
' "$SETTINGS")

echo "$UPDATED" > "$SETTINGS"

echo ""
echo "Hook installed successfully."
echo "  Command: bash $VERIFY_SCRIPT"
echo "  Runs at: SessionStart (before any Claude Code session)"
echo ""
echo "To uninstall: bash $SCRIPT_DIR/disable-lock.sh --uninstall-hook"
echo "Documentation: $(dirname "$SCRIPT_DIR")/LOCK-MECHANISM.md"
