#!/usr/bin/env bash
# verify-canonical.sh — Laeka canonical integrity check
# Exit 0: all files match manifest. Exit 1: corruption detected.
# Exit 2: manifest or required tool missing. Exit 3: lock disabled.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$DIST_DIR/canonical-manifest.json"
DISABLE_FLAG="$SCRIPT_DIR/.lock-disabled"

# Respect disable flag (admin override)
if [[ -f "$DISABLE_FLAG" ]]; then
    echo "[laeka-lock] Lock disabled by admin ($(cat "$DISABLE_FLAG")). Skipping verification." >&2
    exit 3
fi

# Require manifest
if [[ ! -f "$MANIFEST" ]]; then
    echo "[laeka-lock] MISSING: canonical-manifest.json not found at $MANIFEST" >&2
    echo "[laeka-lock] Cannot verify integrity. Restore from official Laeka distribution." >&2
    exit 2
fi

# Require jq
if ! command -v jq &>/dev/null; then
    echo "[laeka-lock] MISSING: jq is required. Install with: brew install jq" >&2
    exit 2
fi

# Cross-platform sha256
sha256_file() {
    local file="$1"
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo "[laeka-lock] MISSING: sha256sum or shasum required" >&2
        exit 2
    fi
}

FAILED=0
CHECKED=0
VIOLATIONS=()

# Check each file listed in manifest
while IFS= read -r relpath; do
    expected_hash=$(jq -r ".files[\"$relpath\"]" "$MANIFEST")
    fullpath="$DIST_DIR/$relpath"

    if [[ ! -f "$fullpath" ]]; then
        VIOLATIONS+=("MISSING: $relpath")
        FAILED=1
        continue
    fi

    actual_hash=$(sha256_file "$fullpath")
    ((CHECKED++)) || true

    if [[ "$actual_hash" != "$expected_hash" ]]; then
        VIOLATIONS+=("CORRUPTED: $relpath")
        FAILED=1
    fi
done < <(jq -r '.files | keys[]' "$MANIFEST")

# Verify global hash
if [[ $FAILED -eq 0 ]]; then
    # Recompute global hash using same algorithm as update-canonical.sh
    global_input=$(jq -r '.files | to_entries | sort_by(.key) | .[] | "\(.value)  \(.key)"' "$MANIFEST")
    if command -v sha256sum &>/dev/null; then
        actual_global=$(echo "$global_input" | sha256sum | awk '{print $1}')
    else
        actual_global=$(echo "$global_input" | shasum -a 256 | awk '{print $1}')
    fi
    expected_global=$(jq -r '.global_hash' "$MANIFEST")

    if [[ "$actual_global" != "$expected_global" ]]; then
        VIOLATIONS+=("CORRUPTED: canonical-manifest.json (global_hash mismatch — manifest itself tampered)")
        FAILED=1
    fi
fi

if [[ $FAILED -ne 0 ]]; then
    echo "" >&2
    echo "╔══════════════════════════════════════════════════════════╗" >&2
    echo "║         LAEKA CANONICAL INTEGRITY VIOLATED               ║" >&2
    echo "╚══════════════════════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "The following protected files have been modified or are missing:" >&2
    for v in "${VIOLATIONS[@]}"; do
        echo "  • $v" >&2
    done
    echo "" >&2
    echo "Cannot start. Restore from official Laeka distribution." >&2
    echo "Documentation: $DIST_DIR/LOCK-MECHANISM.md" >&2
    echo "" >&2
    exit 1
fi

echo "[laeka-lock] Canonical integrity verified. $CHECKED files OK." >&2
exit 0
