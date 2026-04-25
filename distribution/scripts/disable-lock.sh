#!/usr/bin/env bash
# disable-lock.sh — Admin tool to temporarily disable or fully uninstall the canonical lock
# Use for debugging, canonical updates, or controlled maintenance windows.
#
# Usage:
#   ./disable-lock.sh                     # Disable lock (add .lock-disabled flag)
#   ./disable-lock.sh --enable            # Re-enable lock (remove flag)
#   ./disable-lock.sh --uninstall-hook    # Remove SessionStart hook from settings.json
#   ./disable-lock.sh --status            # Show current lock status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISABLE_FLAG="$SCRIPT_DIR/.lock-disabled"
SETTINGS="$HOME/.claude/settings.json"

show_status() {
    echo "=== Laeka Lock Status ==="
    if [[ -f "$DISABLE_FLAG" ]]; then
        echo "Lock: DISABLED (reason: $(cat "$DISABLE_FLAG"))"
    else
        echo "Lock: ENABLED"
    fi

    if command -v jq &>/dev/null && [[ -f "$SETTINGS" ]]; then
        if jq -e ".hooks.SessionStart[0].hooks[] | select(.command | contains(\"verify-canonical.sh\"))" "$SETTINGS" &>/dev/null; then
            echo "Hook: INSTALLED in ~/.claude/settings.json"
        else
            echo "Hook: NOT installed"
        fi
    fi
    echo "========================="
}

case "${1:-}" in
    --enable)
        rm -f "$DISABLE_FLAG"
        echo "Lock re-enabled. verify-canonical.sh will run on next SessionStart."
        ;;

    --uninstall-hook)
        if [[ ! -f "$SETTINGS" ]]; then
            echo "ERROR: ~/.claude/settings.json not found." >&2
            exit 1
        fi
        if ! command -v jq &>/dev/null; then
            echo "ERROR: jq required." >&2
            exit 1
        fi
        SETTINGS_BACKUP="${SETTINGS}.laeka-lock-backup"
        cp "$SETTINGS" "$SETTINGS_BACKUP"

        UPDATED=$(jq '
            if .hooks.SessionStart then
                .hooks.SessionStart[0].hooks = [
                    .hooks.SessionStart[0].hooks[] |
                    select(.command | contains("verify-canonical.sh") | not)
                ]
            else . end
        ' "$SETTINGS")
        echo "$UPDATED" > "$SETTINGS"
        echo "Hook removed from ~/.claude/settings.json"
        echo "Backup at: $SETTINGS_BACKUP"
        ;;

    --status)
        show_status
        ;;

    "")
        read -r -p "Reason for disabling lock (for audit trail): " REASON
        if [[ -z "$REASON" ]]; then
            REASON="no reason given"
        fi
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "${TIMESTAMP} — ${REASON}" > "$DISABLE_FLAG"
        echo "Lock disabled. File: $DISABLE_FLAG"
        echo "Re-enable with: bash $SCRIPT_DIR/disable-lock.sh --enable"
        ;;

    *)
        echo "Usage: $0 [--enable | --uninstall-hook | --status]" >&2
        exit 1
        ;;
esac
