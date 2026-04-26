#!/usr/bin/env bash
# install-laeka.sh — Laeka Claude Code Installer (Phase B + F3 local-app)
# Server-side canonical delivery via api.laeka.ai/v1/brain/canonical.
# Fetches signed manifest + bundle, verifies hashes, installs to ~/.claude/projects/laeka/memory/.
#
# Optional: install the standalone local web app (chat UI on localhost + LAN).
#
# Usage:
#   # CLI hook only (canonical + Bhairavi voice in Claude Code):
#   curl -fsSL https://laeka.ai/install | bash
#
#   # CLI hook + local web app (chat UI on http://<lan-ip>:3000/local):
#   curl -fsSL https://laeka.ai/install | bash -s -- --with-local-app
#
#   # Non-interactive with env vars:
#   LAEKA_EMAIL=alice@example.com LAEKA_INVITE=<tok> \
#   LAEKA_INSTALL_LOCAL_APP=1 bash install-laeka.sh
#
# Requirements: Claude Code, bash 4+, jq, curl, tar, sha256sum (Linux) or shasum (macOS)
# Local-app extras: Node.js 20+ (auto-install attempted via brew/apt if missing)
# Platforms: macOS, Linux  (Windows: see install-laeka.ps1)

set -euo pipefail

# ── Args ──────────────────────────────────────────────────────────────────────
INSTALL_LOCAL_APP="${LAEKA_INSTALL_LOCAL_APP:-0}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-local-app) INSTALL_LOCAL_APP=1; shift ;;
        --no-local-app)   INSTALL_LOCAL_APP=0; shift ;;
        --help|-h)
            sed -n '2,21p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) shift ;;  # ignore unknown args (forward compatibility)
    esac
done

# ── Config ────────────────────────────────────────────────────────────────────
LAEKA_API_BASE="${LAEKA_API_BASE:-https://api.laeka.ai}"
LAEKA_BUNDLE_URL="${LAEKA_BUNDLE_URL:-https://laeka.ai/laeka-local-app.tar.gz}"
LAEKA_APP_DIR="$HOME/.laeka/app"
LAEKA_LOG_DIR="$HOME/.laeka"
LOCAL_APP_PORT="${LAEKA_PORT:-3000}"
LAEKA_REPO="https://github.com/laeka-org/laeka-canonical.git"
LAEKA_REPO_TARBALL="https://github.com/laeka-org/laeka-canonical/archive/refs/heads/main.tar.gz"
LAEKA_HOME="$HOME/laeka-canonical-distribution"
LAEKA_DIST="$LAEKA_HOME/distribution"
LAEKA_SCRIPTS="$LAEKA_DIST/scripts"
MEMORY_DIR="$HOME/.claude/projects/laeka/memory"
LAEKA_STATE="$HOME/.claude/projects/laeka"
INSTALL_TOKEN_FILE="$LAEKA_STATE/.install-token"
LOCAL_MANIFEST="$LAEKA_STATE/.canonical-manifest.json"
MACHINE_UUID_FILE="$LAEKA_STATE/.machine-uuid"
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

# Cross-platform sha256
sha256() {
    if command -v sha256sum &>/dev/null; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        err "sha256sum or shasum required" && exit 1
    fi
}

# ── Step 0 — Preflight ───────────────────────────────────────────────────────
section "Laeka Installer (Phase B — early access)"
info "Target: $LAEKA_HOME"
info "Memory: $MEMORY_DIR"
info "API:    $LAEKA_API_BASE"
echo ""

command -v claude &>/dev/null || { err "Claude Code CLI not found. Install: https://claude.ai/code"; exit 1; }
ok "Claude Code: $(claude --version 2>/dev/null | head -1 || echo 'installed')"

if [[ ! -f "$CLAUDE_SETTINGS" ]]; then
    mkdir -p "$HOME/.claude"
    echo "{}" > "$HOME/.claude/settings.json"
    ok "Bootstrap empty ~/.claude/settings.json (Claude Code first-run)"
fi
ok "~/.claude/settings.json found"

command -v jq &>/dev/null || {
    err "jq is required."
    [[ "$(uname)" == "Darwin" ]] && err "  brew install jq" || err "  sudo apt-get install jq"
    exit 1
}
ok "jq found"

command -v curl &>/dev/null || { err "curl required"; exit 1; }
command -v tar &>/dev/null || { err "tar required"; exit 1; }
command -v sha256sum &>/dev/null || command -v shasum &>/dev/null || { err "sha256sum or shasum required"; exit 1; }
ok "curl, tar, sha256 utility found"

# ── Step 1 — Download installer code ─────────────────────────────────────────
section "Downloading Laeka installer code"

if [[ -d "$LAEKA_HOME/.git" ]]; then
    info "Existing git clone — updating..."
    git -C "$LAEKA_HOME" pull --quiet origin main
    ok "Updated to latest"
elif [[ -d "$LAEKA_HOME" ]]; then
    warn "Directory exists without git. Backing up..."
    mv "$LAEKA_HOME" "${LAEKA_HOME}${BACKUP_SUFFIX}"
    ok "Backed up to: ${LAEKA_HOME}${BACKUP_SUFFIX}"
fi

if [[ ! -d "$LAEKA_HOME" ]]; then
    if command -v git &>/dev/null; then
        info "Cloning..."
        git clone --quiet --depth 1 "$LAEKA_REPO" "$LAEKA_HOME"
        ok "Cloned"
    else
        info "Downloading archive..."
        TMP_TAR=$(mktemp /tmp/laeka-dist-XXXXXX.tar.gz)
        curl -fsSL "$LAEKA_REPO_TARBALL" -o "$TMP_TAR"
        mkdir -p "$LAEKA_HOME"
        tar xzf "$TMP_TAR" --strip-components=1 -C "$LAEKA_HOME"
        rm -f "$TMP_TAR"
        ok "Downloaded"
    fi
fi

[[ -f "$LAEKA_SCRIPTS/verify-canonical.sh" ]] || { err "Distribution incomplete — verify-canonical.sh missing."; exit 1; }
chmod +x "$LAEKA_SCRIPTS"/*.sh 2>/dev/null || true

# ── Step 2 — Authenticate, fetch, install canonical ─────────────────────────
mkdir -p "$LAEKA_STATE"
chmod 700 "$LAEKA_STATE"

# Generate machine UUID (stable across reinstalls)
if [[ ! -f "$MACHINE_UUID_FILE" ]]; then
    if command -v uuidgen &>/dev/null; then
        uuidgen > "$MACHINE_UUID_FILE"
    else
        # Fallback: hash hostname + a random sample
        printf "%s-%s\n" "$(hostname 2>/dev/null || echo unknown)" "$(date +%s%N)$RANDOM" \
            | sha256 /dev/stdin <(:) 2>/dev/null \
            | head -c 32 > "$MACHINE_UUID_FILE" || \
            echo "fallback-$(date +%s)-$$" > "$MACHINE_UUID_FILE"
    fi
    chmod 600 "$MACHINE_UUID_FILE"
fi
MACHINE_UUID=$(cat "$MACHINE_UUID_FILE")

# 2a — Authenticate
section "Authenticating with Laeka (early access)"

# Try install_token first (returning user)
SESSION_TOKEN=""
CANONICAL_VERSION=""
TIER=""

if [[ -f "$INSTALL_TOKEN_FILE" ]]; then
    info "Existing install token found — refreshing session..."
    INSTALL_TOKEN=$(cat "$INSTALL_TOKEN_FILE")
    REFRESH_RESP=$(curl -fsS -X POST "$LAEKA_API_BASE/v1/brain/auth/installer-refresh" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg t "$INSTALL_TOKEN" --arg m "$MACHINE_UUID" '{install_token: $t, machine_uuid: $m}')" \
        2>/dev/null) || REFRESH_RESP=""

    if [[ -n "$REFRESH_RESP" ]]; then
        SESSION_TOKEN=$(echo "$REFRESH_RESP" | jq -r '.session_token // empty')
        CANONICAL_VERSION=$(echo "$REFRESH_RESP" | jq -r '.canonical_version // empty')
        if [[ -n "$SESSION_TOKEN" ]]; then
            ok "Refreshed session via install token"
        fi
    fi

    if [[ -z "$SESSION_TOKEN" ]]; then
        warn "Install token refresh failed — re-authentication needed"
    fi
fi

# Fall back to invite-token flow
if [[ -z "$SESSION_TOKEN" ]]; then
    if [[ -z "${LAEKA_EMAIL:-}" ]]; then
        echo ""
        info "Phase 1 early access — invite required."
        info "Get yours at: https://laeka.ai/early-access"
        echo ""
        read -rp "  Email: " LAEKA_EMAIL < /dev/tty
    fi
    if [[ -z "${LAEKA_INVITE:-}" ]]; then
        read -rp "  Invite token: " LAEKA_INVITE < /dev/tty
    fi

    info "Validating invite..."
    VALIDATE_RESP=$(curl -fsS -X POST "$LAEKA_API_BASE/v1/brain/auth/installer-validate" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg e "$LAEKA_EMAIL" \
            --arg t "$LAEKA_INVITE" \
            --arg m "$MACHINE_UUID" \
            '{email: $e, invite_token: $t, machine_uuid: $m}')") || {
        err "Auth failed. Check email + invite token."
        err "If you don't have an invite, request one at https://laeka.ai/early-access"
        exit 1
    }

    SESSION_TOKEN=$(echo "$VALIDATE_RESP" | jq -r '.session_token')
    NEW_INSTALL_TOKEN=$(echo "$VALIDATE_RESP" | jq -r '.install_token')
    CANONICAL_VERSION=$(echo "$VALIDATE_RESP" | jq -r '.canonical_version // "latest"')
    TIER=$(echo "$VALIDATE_RESP" | jq -r '.tier // "phase1"')

    [[ -n "$SESSION_TOKEN" && "$SESSION_TOKEN" != "null" ]] || { err "No session token in response"; exit 1; }

    # Persist install token (long-lived, used for re-fetch by update-canonical.sh)
    echo "$NEW_INSTALL_TOKEN" > "$INSTALL_TOKEN_FILE"
    chmod 600 "$INSTALL_TOKEN_FILE"

    ok "Authenticated (tier: $TIER)"
fi

# 2b — Fetch manifest + bundle
section "Fetching canonical bundle (v${CANONICAL_VERSION:-latest})"

TMP_DIR=$(mktemp -d /tmp/laeka-fetch-XXXXXX)
trap "rm -rf $TMP_DIR" EXIT

info "Fetching manifest..."
curl -fsS "$LAEKA_API_BASE/v1/brain/canonical/manifest?version=${CANONICAL_VERSION:-latest}" \
    -H "Authorization: Bearer $SESSION_TOKEN" \
    -o "$TMP_DIR/manifest.json" || { err "Manifest fetch failed"; exit 1; }
ok "Manifest received"

REMOTE_VERSION=$(jq -r '.version' "$TMP_DIR/manifest.json")
EXPECTED_GLOBAL=$(jq -r '.global_hash' "$TMP_DIR/manifest.json")
info "Version: $REMOTE_VERSION  (signed by: $(jq -r '.signed_by' "$TMP_DIR/manifest.json"))"

info "Fetching bundle..."
curl -fsS "$LAEKA_API_BASE/v1/brain/canonical/bundle?version=$REMOTE_VERSION" \
    -H "Authorization: Bearer $SESSION_TOKEN" \
    -o "$TMP_DIR/bundle.tar.gz" || { err "Bundle fetch failed"; exit 1; }
BUNDLE_SIZE=$(stat -c%s "$TMP_DIR/bundle.tar.gz" 2>/dev/null || stat -f%z "$TMP_DIR/bundle.tar.gz" 2>/dev/null)
ok "Bundle received ($BUNDLE_SIZE bytes)"

# 2c — Verify + install
section "Verifying + installing canonical"

mkdir -p "$TMP_DIR/extract"
tar xzf "$TMP_DIR/bundle.tar.gz" -C "$TMP_DIR/extract"

# Verify each file hash against manifest
FAILS=0
while IFS= read -r entry; do
    rel=$(echo "$entry" | jq -r '.key')
    expected=$(echo "$entry" | jq -r '.value')
    file="$TMP_DIR/extract/$rel"
    if [[ ! -f "$file" ]]; then
        err "Manifest references missing file: $rel"
        FAILS=$((FAILS + 1))
        continue
    fi
    actual=$(sha256 "$file")
    if [[ "$actual" != "$expected" ]]; then
        err "Hash mismatch on $rel: expected ${expected:0:16}, got ${actual:0:16}"
        FAILS=$((FAILS + 1))
    fi
done < <(jq -c '.files | to_entries[]' "$TMP_DIR/manifest.json")

if [[ $FAILS -gt 0 ]]; then
    err "Bundle verification FAILED ($FAILS errors). Aborting install. Memory dir untouched."
    exit 1
fi
ok "All file hashes verified"

# Recompute global hash
GLOBAL_INPUT=$(jq -r '.files | to_entries | sort_by(.key) | map("\(.value)  \(.key)") | join("\n")' "$TMP_DIR/manifest.json")
COMPUTED_GLOBAL=$(printf "%s\n" "$GLOBAL_INPUT" | { command -v sha256sum &>/dev/null && sha256sum || shasum -a 256; } | awk '{print $1}')
if [[ "$COMPUTED_GLOBAL" != "$EXPECTED_GLOBAL" ]]; then
    err "Global hash mismatch. Manifest may be tampered. Aborting."
    exit 1
fi
ok "Global hash verified"

# Atomic write to memory dir
mkdir -p "$MEMORY_DIR"

# Backup existing if non-Laeka
if [[ -f "$MEMORY_DIR/MEMORY.md" ]] && ! grep -qi "laeka" "$MEMORY_DIR/MEMORY.md" 2>/dev/null; then
    cp "$MEMORY_DIR/MEMORY.md" "$MEMORY_DIR/MEMORY.md${BACKUP_SUFFIX}"
    warn "Non-Laeka MEMORY.md backed up: MEMORY.md${BACKUP_SUFFIX}"
fi

# Copy extracted files (preserving subdir structure: memory-public/* → MEMORY_DIR/*)
if [[ -d "$TMP_DIR/extract/memory-public" ]]; then
    cp -r "$TMP_DIR/extract/memory-public/." "$MEMORY_DIR/"
fi
# canonical-public.md → MEMORY_DIR/canonical-public.md (used by hook to inject)
if [[ -f "$TMP_DIR/extract/canonical-public.md" ]]; then
    cp "$TMP_DIR/extract/canonical-public.md" "$MEMORY_DIR/canonical-public.md"
fi

COUNT=$(find "$MEMORY_DIR" -name "*.md" | wc -l | tr -d ' ')
ok "Installed ${COUNT} canonical files → $MEMORY_DIR"

# Persist manifest for verify-canonical.sh
cp "$TMP_DIR/manifest.json" "$LOCAL_MANIFEST"
chmod 644 "$LOCAL_MANIFEST"

# ── Step 3 — Install SessionStart hook ──────────────────────────────────────
section "Installing SessionStart hook"

cat > "$CLIENT_HOOK" << 'HOOK_SCRIPT'
#!/usr/bin/env bash
# laeka-session-start.sh — Auto-generated by Laeka Installer (Phase B)
# Loads canonical identity into session context. Phase B: canonical-public.md
# lives in ~/.claude/projects/laeka/memory/ (server-delivered, not repo-bake-in).
set -uo pipefail

# Only fire if invoked via 'laeka' wrapper (LAEKA_SESSION env var set)
[[ -z "${LAEKA_SESSION:-}" ]] && exit 0

CANONICAL="$HOME/.claude/projects/laeka/memory/canonical-public.md"
LOCAL_MANIFEST="$HOME/.claude/projects/laeka/.canonical-manifest.json"

# Lightweight integrity: verify canonical-public.md hash against local manifest
if [[ -f "$LOCAL_MANIFEST" && -f "$CANONICAL" ]]; then
    if command -v sha256sum &>/dev/null; then
        ACTUAL=$(sha256sum "$CANONICAL" | awk '{print $1}')
    elif command -v shasum &>/dev/null; then
        ACTUAL=$(shasum -a 256 "$CANONICAL" | awk '{print $1}')
    else
        ACTUAL=""
    fi
    if [[ -n "$ACTUAL" ]]; then
        EXPECTED=$(jq -r '.files["canonical-public.md"] // empty' "$LOCAL_MANIFEST" 2>/dev/null || echo "")
        if [[ -n "$EXPECTED" && "$ACTUAL" != "$EXPECTED" ]]; then
            echo "[laeka] WARN: canonical-public.md hash mismatch — was it edited locally?" >&2
        fi
    fi
fi

# Inject canonical into session context via stdout
if [[ -f "$CANONICAL" ]]; then
    echo ""
    cat "$CANONICAL"
    echo ""
fi

# Inject user preferred name if provided
if [[ -f "$HOME/.claude/laeka/user.json" ]]; then
    PREFERRED_NAME=$(jq -r '.preferred_name // ""' "$HOME/.claude/laeka/user.json" 2>/dev/null)
    if [[ -n "$PREFERRED_NAME" ]]; then
        echo ""
        echo "## User preferred name"
        echo ""
        echo "L'user humain de cette session se nomme **$PREFERRED_NAME**. Utilise ce nom dans le vocative quand approprié (chaleur, intimité). Sinon, adresse directe sans vocative."
    fi
fi
HOOK_SCRIPT

chmod +x "$CLIENT_HOOK"
ok "Hook script: $CLIENT_HOOK"

# Inject into settings.json (idempotent)
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

# ── Step 4 — Capture preferred name → user.json ─────────────────────────────
section "Personalisation (optionnel)"

echo ""
echo "Bhairavi peut t'appeler par ton nom préféré quand le vocative apporte de la chaleur."
echo "(Laisse vide pour adresse directe sans nom — toujours acceptable.)"
echo ""

if [[ -z "${LAEKA_PREFERRED_NAME:-}" ]]; then
    if [[ -e /dev/tty ]]; then
        read -rp "  Comment veux-tu que Bhairavi t'appelle ? (Enter = pas de vocative) : " LAEKA_PREFERRED_NAME < /dev/tty
    fi
fi

mkdir -p "$HOME/.claude/laeka"
cat > "$HOME/.claude/laeka/user.json" <<JSON
{
  "preferred_name": "${LAEKA_PREFERRED_NAME:-}",
  "email": "${LAEKA_EMAIL:-}",
  "installed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON
chmod 600 "$HOME/.claude/laeka/user.json"
ok "User config written: ~/.claude/laeka/user.json"

# ── Step 5 — Install 'laeka' wrapper command ─────────────────────────────────
section "Installing 'laeka' wrapper command"

LAEKA_BIN_DIR="$HOME/.local/bin"
LAEKA_WRAPPER="$LAEKA_BIN_DIR/laeka"

mkdir -p "$LAEKA_BIN_DIR"

cat > "$LAEKA_WRAPPER" << 'WRAPPER'
#!/usr/bin/env bash
# laeka — invoke Claude Code with Laeka Bhairavi voice loaded
export LAEKA_SESSION=1
exec claude "$@"
WRAPPER

chmod +x "$LAEKA_WRAPPER"
ok "Wrapper installed: ~/.local/bin/laeka"

# Check if ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$LAEKA_BIN_DIR"; then
    # Detect active rc file
    RC_FILE=""
    if [[ -f "$HOME/.zshrc" ]]; then
        RC_FILE="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        RC_FILE="$HOME/.bashrc"
    fi

    if [[ -n "$RC_FILE" ]] && ! grep -q 'local/bin' "$RC_FILE" 2>/dev/null; then
        echo '' >> "$RC_FILE"
        echo '# Added by Laeka installer' >> "$RC_FILE"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC_FILE"
        info "Added ~/.local/bin to PATH in $RC_FILE"
        info "Run: source $RC_FILE  (or open a new terminal)"
    else
        info "Add to your shell rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

info "Lance 'laeka' pour Bhairavi voice. 'claude' reste vanilla."

# ── Step 6 — Optional: install local web app ────────────────────────────────
LOCAL_APP_URL=""
LOCAL_APP_LAN_URL=""
if [[ "$INSTALL_LOCAL_APP" == "1" ]]; then
    section "Installing Laeka Local Web App"

    OS="$(uname -s)"

    # 6a — Verify Node.js 20+ (auto-install attempt if missing)
    NODE_BIN=""
    if command -v node &>/dev/null; then
        NODE_VERSION=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
        if [[ "$NODE_VERSION" =~ ^[0-9]+$ ]] && [[ $NODE_VERSION -ge 20 ]]; then
            NODE_BIN="$(command -v node)"
            ok "Node.js $(node --version) found at $NODE_BIN"
        else
            warn "Node.js v$NODE_VERSION found — need 20+. Attempting upgrade..."
        fi
    fi

    if [[ -z "$NODE_BIN" ]]; then
        info "Installing Node.js 20+..."
        if [[ "$OS" == "Darwin" ]]; then
            if command -v brew &>/dev/null; then
                brew install node@20 2>&1 | tail -5 || warn "brew install node@20 returned non-zero"
                # Homebrew on Apple Silicon → /opt/homebrew/bin, Intel → /usr/local/bin
                for candidate in /opt/homebrew/opt/node@20/bin/node /opt/homebrew/bin/node /usr/local/bin/node; do
                    [[ -x "$candidate" ]] && NODE_BIN="$candidate" && break
                done
            else
                err "Homebrew not found. Install Node 20+ manually: https://nodejs.org/"
                exit 1
            fi
        elif [[ "$OS" == "Linux" ]]; then
            if command -v apt-get &>/dev/null; then
                # NodeSource setup script for Node 20.x
                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - 2>&1 | tail -5
                sudo apt-get install -y nodejs 2>&1 | tail -3
                NODE_BIN="$(command -v node)"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y nodejs 2>&1 | tail -3
                NODE_BIN="$(command -v node)"
            else
                err "Unknown package manager. Install Node 20+ manually: https://nodejs.org/"
                exit 1
            fi
        else
            err "Unsupported OS: $OS. Install Node 20+ manually."
            exit 1
        fi
    fi

    [[ -n "$NODE_BIN" && -x "$NODE_BIN" ]] || { err "Node.js install failed"; exit 1; }
    ok "Node.js: $NODE_BIN ($($NODE_BIN --version))"

    # 6b — Download standalone bundle
    section "Downloading Laeka Local App bundle"
    info "URL: $LAEKA_BUNDLE_URL"

    APP_TMP=$(mktemp -d /tmp/laeka-app-XXXXXX)
    trap "rm -rf $APP_TMP" EXIT

    if ! curl -fsSL "$LAEKA_BUNDLE_URL" -o "$APP_TMP/bundle.tar.gz"; then
        err "Bundle download failed."
        err "Set LAEKA_BUNDLE_URL to override the source URL, or check network connectivity."
        exit 1
    fi
    BUNDLE_BYTES=$(stat -c%s "$APP_TMP/bundle.tar.gz" 2>/dev/null || stat -f%z "$APP_TMP/bundle.tar.gz" 2>/dev/null)
    ok "Downloaded ($BUNDLE_BYTES bytes)"

    # 6c — Extract to $LAEKA_APP_DIR (atomic — backup existing if present)
    if [[ -d "$LAEKA_APP_DIR" ]]; then
        mv "$LAEKA_APP_DIR" "${LAEKA_APP_DIR}${BACKUP_SUFFIX}"
        warn "Existing app dir backed up: ${LAEKA_APP_DIR}${BACKUP_SUFFIX}"
    fi
    mkdir -p "$LAEKA_APP_DIR"
    tar xzf "$APP_TMP/bundle.tar.gz" -C "$LAEKA_APP_DIR" --strip-components=1 2>/dev/null \
        || tar xzf "$APP_TMP/bundle.tar.gz" -C "$LAEKA_APP_DIR"
    [[ -f "$LAEKA_APP_DIR/server.js" ]] || { err "Bundle missing server.js — invalid Next.js standalone output"; exit 1; }
    ok "Extracted to $LAEKA_APP_DIR"

    # 6d — Install service file (LaunchAgent on Mac, systemd user on Linux)
    section "Setting up auto-start service"

    SERVICE_TPL_DIR="$LAEKA_DIST/service-templates"

    if [[ "$OS" == "Darwin" ]]; then
        PLIST_DIR="$HOME/Library/LaunchAgents"
        PLIST_PATH="$PLIST_DIR/com.laeka.local.plist"
        mkdir -p "$PLIST_DIR"

        # Render template
        sed -e "s|__APP_DIR__|$LAEKA_APP_DIR|g" \
            -e "s|__NODE_BIN__|$NODE_BIN|g" \
            -e "s|__HOME__|$HOME|g" \
            "$SERVICE_TPL_DIR/com.laeka.local.plist" > "$PLIST_PATH"

        # Reload (idempotent)
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        launchctl load -w "$PLIST_PATH"
        ok "LaunchAgent installed: $PLIST_PATH"
    elif [[ "$OS" == "Linux" ]]; then
        UNIT_DIR="$HOME/.config/systemd/user"
        UNIT_PATH="$UNIT_DIR/laeka-local.service"
        mkdir -p "$UNIT_DIR"

        sed -e "s|__APP_DIR__|$LAEKA_APP_DIR|g" \
            -e "s|__NODE_BIN__|$NODE_BIN|g" \
            "$SERVICE_TPL_DIR/laeka-local.service" > "$UNIT_PATH"

        systemctl --user daemon-reload
        systemctl --user enable --now laeka-local.service
        ok "systemd user unit installed: $UNIT_PATH"
    fi

    # 6e — Wait for ready (poll port)
    info "Waiting for app to become ready on port $LOCAL_APP_PORT..."
    READY=0
    for i in {1..20}; do
        if curl -sf -o /dev/null --max-time 1 "http://127.0.0.1:$LOCAL_APP_PORT/local" 2>/dev/null; then
            READY=1
            break
        fi
        sleep 1
    done

    if [[ $READY -eq 1 ]]; then
        ok "App is responding on http://127.0.0.1:$LOCAL_APP_PORT/local"
    else
        warn "App not yet responding after 20s — check logs: $LAEKA_LOG_DIR/laeka-local.log"
    fi

    # 6f — Detect LAN IP + print URL + QR code
    section "Local app ready"

    LAN_IP=""
    if [[ "$OS" == "Darwin" ]]; then
        LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
    elif [[ "$OS" == "Linux" ]]; then
        LAN_IP=$(ip -4 -o addr show scope global 2>/dev/null \
                  | awk '{print $4}' | cut -d/ -f1 | head -1)
    fi

    LOCAL_APP_URL="http://localhost:$LOCAL_APP_PORT/local"
    if [[ -n "$LAN_IP" ]]; then
        LOCAL_APP_LAN_URL="http://$LAN_IP:$LOCAL_APP_PORT/local"
    fi

    echo ""
    echo -e "  ${CYAN}Local:${NC}  $LOCAL_APP_URL"
    if [[ -n "$LOCAL_APP_LAN_URL" ]]; then
        echo -e "  ${CYAN}LAN:${NC}    $LOCAL_APP_LAN_URL  (use from your phone on the same WiFi)"
    fi

    # QR code (mobile access) — best effort via qrencode
    if command -v qrencode &>/dev/null && [[ -n "$LOCAL_APP_LAN_URL" ]]; then
        echo ""
        echo -e "  ${CYAN}QR (LAN URL):${NC}"
        qrencode -t ANSIUTF8 "$LOCAL_APP_LAN_URL" 2>/dev/null || true
    elif [[ -n "$LOCAL_APP_LAN_URL" ]]; then
        info "Install qrencode for terminal QR code:"
        if [[ "$OS" == "Darwin" ]]; then
            info "  brew install qrencode"
        else
            info "  sudo apt-get install qrencode  (or your distro equivalent)"
        fi
    fi

    echo ""
    echo -e "  ${GREEN}✓${NC} App dir       $LAEKA_APP_DIR"
    echo -e "  ${GREEN}✓${NC} Logs          $LAEKA_LOG_DIR/laeka-local.log"
    if [[ "$OS" == "Darwin" ]]; then
        echo -e "  ${CYAN}Stop:${NC}  launchctl unload ~/Library/LaunchAgents/com.laeka.local.plist"
        echo -e "  ${CYAN}Start:${NC} launchctl load -w ~/Library/LaunchAgents/com.laeka.local.plist"
    elif [[ "$OS" == "Linux" ]]; then
        echo -e "  ${CYAN}Stop:${NC}  systemctl --user stop laeka-local.service"
        echo -e "  ${CYAN}Start:${NC} systemctl --user start laeka-local.service"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
section "Installation complete"
echo ""
echo -e "  ${GREEN}✓${NC} Canonical    v$REMOTE_VERSION ($COUNT files)"
echo -e "  ${GREEN}✓${NC} Distribution $LAEKA_HOME"
echo -e "  ${GREEN}✓${NC} Memory       $MEMORY_DIR"
echo -e "  ${GREEN}✓${NC} Hook         $CLIENT_HOOK"
if [[ -n "$LOCAL_APP_URL" ]]; then
    echo -e "  ${GREEN}✓${NC} Local app    $LOCAL_APP_URL"
fi
echo ""
echo -e "  ${CYAN}Next:${NC} Launch Claude Code — Laeka loads automatically at session start."
if [[ -n "$LOCAL_APP_URL" ]]; then
    echo -e "         Or open ${CYAN}$LOCAL_APP_URL${NC} for the web chat UI."
fi
echo ""
echo -e "  Update:     bash $LAEKA_DIST/update-laeka.sh"
echo -e "  Uninstall:  bash $LAEKA_DIST/uninstall-laeka.sh"
echo -e "  Support:    https://laeka.ai/support"
echo ""
