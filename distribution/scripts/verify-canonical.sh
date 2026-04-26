#!/usr/bin/env bash
# verify-canonical.sh — Laeka canonical integrity audit (Phase B).
#
# Reads the local manifest at ~/.claude/projects/laeka/.canonical-manifest.json
# and verifies each file in ~/.claude/projects/laeka/memory/ against its hash.
#
# Exit 0: all files match
# Exit 1: integrity violation
# Exit 2: missing manifest or required tool
# Exit 3: lock disabled (admin override)
#
# Run anytime with: bash verify-canonical.sh

set -uo pipefail

LAEKA_STATE="$HOME/.claude/projects/laeka"
LOCAL_MANIFEST="$LAEKA_STATE/.canonical-manifest.json"
MEMORY_DIR="$LAEKA_STATE/memory"
DISABLE_FLAG="$LAEKA_STATE/.lock-disabled"

# Admin override
if [[ -f "$DISABLE_FLAG" ]]; then
    echo "[laeka-lock] Lock disabled by admin ($(cat "$DISABLE_FLAG")). Skipping verification." >&2
    exit 3
fi

# Tool checks
if ! command -v jq &>/dev/null; then
    echo "[laeka-lock] MISSING: jq required. Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 2
fi

if ! command -v sha256sum &>/dev/null && ! command -v shasum &>/dev/null; then
    echo "[laeka-lock] MISSING: sha256sum or shasum required" >&2
    exit 2
fi

if [[ ! -f "$LOCAL_MANIFEST" ]]; then
    echo "[laeka-lock] MISSING: local manifest at $LOCAL_MANIFEST" >&2
    echo "[laeka-lock] Run: bash install-laeka.sh (or update-canonical.sh) to install canonical." >&2
    exit 2
fi

if [[ ! -d "$MEMORY_DIR" ]]; then
    echo "[laeka-lock] MISSING: memory dir at $MEMORY_DIR" >&2
    exit 2
fi

sha256() {
    if command -v sha256sum &>/dev/null; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

VERSION=$(jq -r '.version' "$LOCAL_MANIFEST")
EXPECTED_GLOBAL=$(jq -r '.global_hash' "$LOCAL_MANIFEST")

# Verify each file
FAILS=0
TOTAL=0
while IFS= read -r entry; do
    rel=$(echo "$entry" | jq -r '.key')
    expected=$(echo "$entry" | jq -r '.value')

    # The bundle layout puts canonical-public.md at root and memory-public/* under memory-public/.
    # Locally, install-laeka.sh flattens them into MEMORY_DIR (canonical-public.md at root,
    # memory-public/*.md unpacked into MEMORY_DIR root).
    if [[ "$rel" == "canonical-public.md" ]]; then
        local_file="$MEMORY_DIR/canonical-public.md"
    elif [[ "$rel" == memory-public/* ]]; then
        local_file="$MEMORY_DIR/${rel#memory-public/}"
    else
        local_file="$MEMORY_DIR/$rel"
    fi

    TOTAL=$((TOTAL + 1))
    if [[ ! -f "$local_file" ]]; then
        echo "[laeka-lock] MISSING: $rel (expected at $local_file)" >&2
        FAILS=$((FAILS + 1))
        continue
    fi
    actual=$(sha256 "$local_file")
    if [[ "$actual" != "$expected" ]]; then
        echo "[laeka-lock] HASH MISMATCH: $rel" >&2
        echo "  expected: ${expected:0:16}..." >&2
        echo "  actual:   ${actual:0:16}..." >&2
        FAILS=$((FAILS + 1))
    fi
done < <(jq -c '.files | to_entries[]' "$LOCAL_MANIFEST")

if [[ $FAILS -gt 0 ]]; then
    echo "" >&2
    echo "[laeka-lock] LAEKA CANONICAL INTEGRITY VIOLATED — $FAILS / $TOTAL files mismatch (v$VERSION)" >&2
    echo "[laeka-lock] Restore: bash $HOME/laeka-canonical-distribution/distribution/update-canonical.sh" >&2
    exit 1
fi

echo "[laeka-lock] Verified: $TOTAL files match canonical v$VERSION"
exit 0
