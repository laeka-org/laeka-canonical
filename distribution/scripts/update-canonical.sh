#!/usr/bin/env bash
# update-canonical.sh — Admin tool to publish a new canonical version
# Recomputes all hashes and updates canonical-manifest.json
# V1: trust-based (no GPG). V2 target: GPG/Sigstore signing.
#
# Usage: ./update-canonical.sh [--version X.Y.Z] [--signed-by "Author YYYY-MM-DD"]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST="$DIST_DIR/canonical-manifest.json"

# Parse args
VERSION=""
SIGNED_BY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --signed-by) SIGNED_BY="$2"; shift 2 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# Require jq
if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required. Install with: brew install jq" >&2
    exit 1
fi

# Cross-platform sha256
sha256_file() {
    local file="$1"
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo "ERROR: sha256sum or shasum required" >&2
        exit 1
    fi
}

# Determine version (bump patch if not specified)
if [[ -z "$VERSION" ]]; then
    if [[ -f "$MANIFEST" ]]; then
        current=$(jq -r '.version' "$MANIFEST")
        major=$(echo "$current" | cut -d. -f1)
        minor=$(echo "$current" | cut -d. -f2)
        patch=$(echo "$current" | cut -d. -f3)
        VERSION="${major}.${minor}.$((patch + 1))"
    else
        VERSION="1.0.0"
    fi
fi

# Default signed-by
if [[ -z "$SIGNED_BY" ]]; then
    SIGNED_BY="Laeka-Tour $(date +%Y-%m-%d)"
fi

echo "Publishing canonical v${VERSION} (signed by: ${SIGNED_BY})"
echo ""

# Collect protected files
PROTECTED=()
PROTECTED+=("canonical-public.md")

# All .md files in memory-public, sorted
while IFS= read -r fn; do
    PROTECTED+=("memory-public/$(basename "$fn")")
done < <(find "$DIST_DIR/memory-public" -name "*.md" | sort)

# Build file hashes JSON and global input
FILE_JSON="{"
GLOBAL_LINES=()
FIRST=1

for relpath in $(echo "${PROTECTED[@]}" | tr ' ' '\n' | sort); do
    fullpath="$DIST_DIR/$relpath"
    if [[ ! -f "$fullpath" ]]; then
        echo "WARNING: File not found, skipping: $relpath" >&2
        continue
    fi
    hash=$(sha256_file "$fullpath")
    echo "  hashed: $relpath"
    GLOBAL_LINES+=("${hash}  ${relpath}")

    if [[ $FIRST -eq 0 ]]; then
        FILE_JSON+=","
    fi
    FILE_JSON+="\"${relpath}\": \"${hash}\""
    FIRST=0
done
FILE_JSON+="}"

# Global hash
global_input=$(printf '%s\n' "${GLOBAL_LINES[@]}" | sort)
if command -v sha256sum &>/dev/null; then
    GLOBAL_HASH=$(echo "$global_input" | sha256sum | awk '{print $1}')
else
    GLOBAL_HASH=$(echo "$global_input" | shasum -a 256 | awk '{print $1}')
fi

UPDATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Write manifest (using python3 for clean JSON output)
python3 -c "
import json, sys

files_raw = sys.argv[1]
global_hash = sys.argv[2]
version = sys.argv[3]
signed_by = sys.argv[4]
updated_at = sys.argv[5]

files = json.loads('{' + files_raw + '}')

manifest = {
    'version': version,
    'signed_by': signed_by,
    'updated_at': updated_at,
    'files': dict(sorted(files.items())),
    'global_hash': global_hash
}

with open('$MANIFEST', 'w') as f:
    json.dump(manifest, f, indent=2)
    f.write('\n')

print(f'Manifest written: {len(files)} files, global_hash={global_hash[:16]}...')
" "${FILE_JSON:1:-1}" "$GLOBAL_HASH" "$VERSION" "$SIGNED_BY" "$UPDATED_AT"

echo ""
echo "Done. canonical-manifest.json updated to v${VERSION}."
echo ""
echo "Next steps:"
echo "  1. Verify: bash $SCRIPT_DIR/verify-canonical.sh"
echo "  2. Commit: git add canonical-manifest.json && git commit -m 'chore(lock): update canonical manifest v${VERSION}'"
echo "  3. Tag:    git tag canonical-v${VERSION}"
