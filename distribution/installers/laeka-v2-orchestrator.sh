#!/usr/bin/env bash
# laeka-v2-orchestrator.sh — Laeka V2 Setup Orchestrator
#
# Runs as the logged-in user (NOT root) — called by postinstall via su -l.
# Handles: Claude Code install, Anthropic wizard, claude login, Laeka distribution,
# frontend npm setup, LaunchAgent persistence, browser launch.
#
# Usage: bash /usr/local/laeka/laeka-v2-orchestrator.sh /path/to/logfile

set -uo pipefail

LOG="${1:-/tmp/laeka-v2-$(date +%Y%m%d-%H%M%S).log}"
LAEKA_HOME="$HOME/laeka-canonical-distribution"
FRONTEND_DIR="$LAEKA_HOME/distribution/frontend"
CLIENT_CONFIG="$FRONTEND_DIR/config/client-config.json"
LAUNCH_AGENTS="$HOME/Library/LaunchAgents"
PLIST="$LAUNCH_AGENTS/com.laeka.frontend.plist"

log()    { echo "[laeka-v2] $*" | tee -a "$LOG"; }
notify() { osascript -e "display notification \"$*\" with title \"Laeka Setup\"" 2>/dev/null || true; }

find_bin() {
    local name="$1" dir
    for dir in "$HOME/.local/bin" /usr/local/bin /opt/homebrew/bin "$HOME/bin" /usr/bin /bin; do
        [[ -x "$dir/$name" ]] && echo "$dir/$name" && return 0
    done
    return 1
}

log "=== Laeka V2 Orchestrator — $(date) ==="
log "User: $(whoami)  Home: $HOME"

# ── STEP 1: Detect / Install Claude Code ────────────────────────────────────
log "--- Step 1: Claude Code ---"
notify "Checking Claude Code..."

CLAUDE_BIN=$(find_bin "claude" 2>/dev/null || true)

if [[ -z "$CLAUDE_BIN" ]]; then
    log "Not found — installing via claude.ai/install.sh..."
    notify "Installing Claude Code (~30 seconds)..."

    if curl -fsSL https://claude.ai/install.sh | bash >> "$LOG" 2>&1; then
        CLAUDE_BIN=$(find_bin "claude" 2>/dev/null || true)
    fi

    if [[ -z "$CLAUDE_BIN" ]]; then
        log "ERROR: Auto-install failed — claude not found after install"
        osascript -e 'display dialog "Claude Code could not be installed automatically.

Please download it from claude.ai, install it manually, then double-click Laeka.pkg again." buttons {"Open claude.ai"} default button "Open claude.ai" with title "Installation Issue"' 2>/dev/null || true
        open "https://claude.ai/download" 2>/dev/null || true
        exit 1
    fi
fi

export PATH="$(dirname "$CLAUDE_BIN"):$PATH"
log "Claude Code: $CLAUDE_BIN"

# ── STEP 2: Anthropic Account Wizard ────────────────────────────────────────
log "--- Step 2: Anthropic account ---"

ONBOARDING="/usr/local/laeka/onboarding-anthropic.html"
[[ -f "$ONBOARDING" ]] && open "$ONBOARDING" 2>/dev/null || true

ACCOUNT_BTN=$(osascript << 'APPLES_ACCOUNT'
return button returned of (display dialog "Welcome to Laeka! \U0001F44B

To use Laeka, you need an Anthropic account with a Claude subscription.

• A setup guide just opened in your browser
• Go to anthropic.com to create your free account
• Subscribe to Claude Pro ($20/mo) or Max ($100+/mo)
• Return here when done

Already have an account? Click \"I Have an Account\"." buttons {"I Have an Account", "Open Anthropic.com"} default button "Open Anthropic.com" with title "Step 1 of 3 — Anthropic Account" giving up after 600)
APPLES_ACCOUNT
) 2>/dev/null || true

if [[ "$ACCOUNT_BTN" == "Open Anthropic.com" ]]; then
    open "https://anthropic.com" 2>/dev/null || true
    osascript -e 'display dialog "After creating your account and subscribing, click OK to continue." buttons {"OK"} default button "OK" with title "Step 1 of 3 — Anthropic Account" giving up after 600' 2>/dev/null || true
fi
log "Account step done (button: ${ACCOUNT_BTN:-timeout})"

# ── STEP 3: Claude Login ─────────────────────────────────────────────────────
log "--- Step 3: Claude authentication ---"

LOGIN_BTN=$(osascript << 'APPLES_LOGIN'
return button returned of (display dialog "Connect Claude Code to your Anthropic account.

• If you just created your account, click \"Log In Now\"
• If you already authorized Claude Code, click \"Already Logged In\"" buttons {"Already Logged In", "Log In Now"} default button "Log In Now" with title "Step 2 of 3 — Authorize Claude" giving up after 300)
APPLES_LOGIN
) 2>/dev/null || true

if [[ "$LOGIN_BTN" != "Already Logged In" ]]; then
    log "Starting claude login..."
    "$CLAUDE_BIN" login < /dev/null >> "$LOG" 2>&1 &
    LOGIN_PID=$!

    osascript -e 'display dialog "Complete the authorization in your browser.

Click OK once you see \"Successfully authenticated\"." buttons {"OK"} default button "OK" with title "Step 2 of 3 — Authorize Claude" giving up after 300' 2>/dev/null || true

    wait "$LOGIN_PID" 2>/dev/null || true
fi
log "Auth step done (button: ${LOGIN_BTN:-timeout})"

# ── STEP 4: Install Laeka Distribution ──────────────────────────────────────
log "--- Step 4: Laeka distribution ---"
notify "Installing Laeka knowledge base..."

INSTALL_EXIT=0
bash /usr/local/laeka/install.sh >> "$LOG" 2>&1 || INSTALL_EXIT=$?

if [[ $INSTALL_EXIT -ne 0 ]]; then
    log "WARNING: install.sh exited $INSTALL_EXIT — check log"
    notify "Laeka install warning — see log on Desktop"
else
    log "Distribution installed"
fi

# ── STEP 5: Frontend Setup ───────────────────────────────────────────────────
log "--- Step 5: Frontend ---"
notify "Preparing chat interface..."

NPM_BIN=$(find_bin "npm" 2>/dev/null || true)

if [[ -z "$NPM_BIN" ]]; then
    BREW_BIN=$(find_bin "brew" 2>/dev/null || true)
    if [[ -n "$BREW_BIN" ]]; then
        log "npm not found — installing Node.js via Homebrew..."
        notify "Installing Node.js..."
        "$BREW_BIN" install node >> "$LOG" 2>&1 || true
        NPM_BIN=$(find_bin "npm" 2>/dev/null || true)
    fi
fi

if [[ -z "$NPM_BIN" ]]; then
    log "npm unavailable — skipping frontend auto-start"
    osascript -e 'display dialog "The Laeka chat interface requires Node.js.

A download page is opening in your browser.
Install Node.js, then double-click Laeka.pkg again to complete setup." buttons {"Open nodejs.org"} default button "Open nodejs.org" with title "Node.js Required"' 2>/dev/null || true
    open "https://nodejs.org/download/" 2>/dev/null || true
else
    if [[ -d "$FRONTEND_DIR" ]]; then
        log "Running npm install in $FRONTEND_DIR..."
        cd "$FRONTEND_DIR"
        "$NPM_BIN" install >> "$LOG" 2>&1 || log "npm install had warnings — check log"
        log "npm install done"
    else
        log "WARNING: frontend dir not found at $FRONTEND_DIR (install.sh may not have run yet)"
    fi
fi

# ── STEP 6: LaunchAgent ──────────────────────────────────────────────────────
log "--- Step 6: LaunchAgent ---"

CLIENT_NAME="laeka"
PORT=8080
if [[ -f "$CLIENT_CONFIG" ]]; then
    CLIENT_NAME=$(python3 -c "import json; d=json.load(open('$CLIENT_CONFIG')); print(d.get('clientName','laeka'))" 2>/dev/null || echo "laeka")
    PORT=$(python3 -c "import json; d=json.load(open('$CLIENT_CONFIG')); print(d.get('port',8080))" 2>/dev/null || echo "8080")
fi

if [[ -n "${NPM_BIN:-}" && -d "$FRONTEND_DIR" ]]; then
    mkdir -p "$LAUNCH_AGENTS"

    # Write plist with actual runtime paths (launchd needs full paths, no env vars)
    cat > "$PLIST" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.laeka.frontend</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd "$FRONTEND_DIR" &amp;&amp; "$NPM_BIN" run dev &gt;&gt; /tmp/laeka-frontend.log 2&gt;&amp;1</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/tmp/laeka-frontend.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/laeka-frontend.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
PLIST_EOF

    launchctl load "$PLIST" >> "$LOG" 2>&1 || log "Note: launchctl load — will take effect at next login"
    log "LaunchAgent installed: $PLIST"
else
    log "Skipping LaunchAgent (npm or frontend unavailable)"
fi

# ── STEP 7: Start Frontend + Open Browser ────────────────────────────────────
log "--- Step 7: Launch ---"

if [[ -n "${NPM_BIN:-}" && -d "${FRONTEND_DIR:-}" ]]; then
    notify "Starting Laeka..."
    cd "$FRONTEND_DIR"
    nohup "$NPM_BIN" run dev >> /tmp/laeka-frontend.log 2>&1 &
    FRONTEND_PID=$!
    log "Frontend starting (PID $FRONTEND_PID) on port $PORT..."

    # Wait up to 40s for the server to accept connections
    for i in {1..20}; do
        sleep 2
        if curl -sf "http://localhost:$PORT" > /dev/null 2>&1; then
            log "Frontend up after $((i * 2))s"
            break
        fi
    done

    open "http://localhost:$PORT/$CLIENT_NAME" 2>/dev/null || true
else
    log "Skipping browser open (frontend unavailable)"
fi

osascript << 'APPLES_FINAL' 2>/dev/null || true
display dialog "✅ Laeka is installed and running!

Your chat interface is now open in your browser at:
http://localhost:8080/laeka

Laeka starts automatically each time you log in.
Enjoy!" buttons {"Finish"} default button "Finish" with title "Laeka Ready \U0001F389"
APPLES_FINAL

log "=== SETUP COMPLETE ==="
