#!/usr/bin/env bash
# build-mac.sh — Build Laeka.pkg for macOS (V2)
#
# V2 changes vs V1:
#   - Auto-installs Claude Code if not present (via claude.ai/install.sh)
#   - Anthropic account onboarding wizard (browser guide + AppleScript dialogs)
#   - claude login bridge (auth step in wizard)
#   - Installs LaunchAgent for auto-start at login
#   - Starts Laeka frontend (Next.js) and opens browser automatically
#
# Output: installers/Laeka.pkg  (double-click → Apple wizard → Laeka running in browser)
# Requires: macOS with Xcode Command Line Tools (pkgbuild + productbuild)
#
# Optional signing (removes "unknown developer" warning):
#   export SIGN_IDENTITY="Developer ID Installer: Your Name (XXXXXXXXXX)"
#   ./build-mac.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$SCRIPT_DIR"
PKG_VERSION="2.0.0"
PKG_IDENTIFIER="ai.laeka.installer"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"

# ── Preflight ─────────────────────────────────────────────────────────────────
for cmd in pkgbuild productbuild; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: $cmd not found. Install Xcode Command Line Tools:"
        echo "  xcode-select --install"
        exit 1
    fi
done

for f in install-laeka.sh uninstall-laeka.sh update-laeka.sh; do
    if [[ ! -f "$DIST_DIR/$f" ]]; then
        echo "ERROR: Missing $DIST_DIR/$f"
        exit 1
    fi
done

if [[ ! -f "$SCRIPT_DIR/laeka-v2-orchestrator.sh" ]]; then
    echo "ERROR: Missing $SCRIPT_DIR/laeka-v2-orchestrator.sh"
    exit 1
fi

for html in welcome.html conclusion.html onboarding-anthropic.html; do
    if [[ ! -f "$SCRIPT_DIR/resources/$html" ]]; then
        echo "ERROR: Missing $SCRIPT_DIR/resources/$html"
        exit 1
    fi
done

echo "[laeka-build] Building Laeka.pkg v${PKG_VERSION}..."
WORK_DIR=$(mktemp -d /tmp/laeka-pkg-build-XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT

# ── Payload: /usr/local/laeka/ ────────────────────────────────────────────────
PAYLOAD_DIR="$WORK_DIR/payload"
mkdir -p "$PAYLOAD_DIR/usr/local/laeka"

cp "$DIST_DIR/install-laeka.sh"   "$PAYLOAD_DIR/usr/local/laeka/install.sh"
cp "$DIST_DIR/uninstall-laeka.sh" "$PAYLOAD_DIR/usr/local/laeka/uninstall.sh"
cp "$DIST_DIR/update-laeka.sh"    "$PAYLOAD_DIR/usr/local/laeka/update.sh"
cp "$SCRIPT_DIR/laeka-v2-orchestrator.sh" "$PAYLOAD_DIR/usr/local/laeka/laeka-v2-orchestrator.sh"

# Onboarding HTML served from payload so postinstall can open it
cp "$SCRIPT_DIR/resources/onboarding-anthropic.html" "$PAYLOAD_DIR/usr/local/laeka/onboarding-anthropic.html"

chmod 755 "$PAYLOAD_DIR/usr/local/laeka/"*.sh
chmod 644 "$PAYLOAD_DIR/usr/local/laeka/"*.html
echo "[laeka-build] Payload: /usr/local/laeka/ with install/uninstall/update/orchestrator/onboarding"

# ── postinstall script ────────────────────────────────────────────────────────
# Runs as root — detects logged-in user, delegates to orchestrator as that user.
SCRIPTS_DIR="$WORK_DIR/scripts"
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL'
#!/usr/bin/env bash
set -euo pipefail

LOG="/tmp/laeka-v2-install-$(date +%Y%m%d-%H%M%S).log"

# Detect the currently logged-in user (pkg runs as root)
CURRENT_USER=$(stat -f "%Su" /dev/console 2>/dev/null || true)
if [[ -z "$CURRENT_USER" || "$CURRENT_USER" == "root" ]]; then
    CURRENT_USER=$(who | awk '/console/{print $1; exit}')
fi
if [[ -z "$CURRENT_USER" ]]; then
    echo "[laeka] ERROR: Cannot detect logged-in user." | tee -a "$LOG"
    exit 1
fi

echo "[laeka] V2 — Installing for user: $CURRENT_USER" | tee -a "$LOG"
echo "[laeka] Log: $LOG" | tee -a "$LOG"

# Delegate all user-space work to the orchestrator
su -l "$CURRENT_USER" -c "bash /usr/local/laeka/laeka-v2-orchestrator.sh '$LOG'" >> "$LOG" 2>&1
EXIT_CODE=$?

USER_HOME=$(eval echo "~$CURRENT_USER")
cp "$LOG" "$USER_HOME/Desktop/laeka-v2-install.log" 2>/dev/null || true

if [[ $EXIT_CODE -ne 0 ]]; then
    echo "[laeka] Setup had issues. See: $USER_HOME/Desktop/laeka-v2-install.log" | tee -a "$LOG"
fi

exit 0
POSTINSTALL
chmod +x "$SCRIPTS_DIR/postinstall"
echo "[laeka-build] postinstall script written"

# ── Component package ─────────────────────────────────────────────────────────
PKG_COMPONENT="$WORK_DIR/Laeka-component.pkg"
PKGBUILD_ARGS=(
    --root "$PAYLOAD_DIR"
    --scripts "$SCRIPTS_DIR"
    --identifier "$PKG_IDENTIFIER"
    --version "$PKG_VERSION"
    --install-location "/"
)
if [[ -n "$SIGN_IDENTITY" ]]; then
    PKGBUILD_ARGS+=(--sign "$SIGN_IDENTITY")
fi
pkgbuild "${PKGBUILD_ARGS[@]}" "$PKG_COMPONENT"
echo "[laeka-build] Component package built"

# ── Resources (welcome/conclusion HTML for installer GUI) ─────────────────────
RESOURCES_DIR="$WORK_DIR/resources"
mkdir -p "$RESOURCES_DIR"
cp "$SCRIPT_DIR/resources/welcome.html"    "$RESOURCES_DIR/welcome.html"
cp "$SCRIPT_DIR/resources/conclusion.html" "$RESOURCES_DIR/conclusion.html"

# ── Distribution XML (GUI wizard config) ──────────────────────────────────────
cat > "$WORK_DIR/distribution.xml" << DISTXML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Laeka</title>
    <organization>ai.laeka</organization>
    <domains enable_localSystem="true" enable_currentUserHome="false"/>
    <options customize="never" require-scripts="false" rootVolumeOnly="true"/>
    <welcome    file="welcome.html"    mime-type="text/html"/>
    <conclusion file="conclusion.html" mime-type="text/html"/>
    <pkg-ref id="${PKG_IDENTIFIER}"/>
    <choices-outline>
        <line choice="default">
            <line choice="${PKG_IDENTIFIER}"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="${PKG_IDENTIFIER}" visible="false">
        <pkg-ref id="${PKG_IDENTIFIER}"/>
    </choice>
    <pkg-ref id="${PKG_IDENTIFIER}"
             version="${PKG_VERSION}"
             onConclusion="none">Laeka-component.pkg</pkg-ref>
</installer-gui-script>
DISTXML
echo "[laeka-build] distribution.xml written"

# ── Final package ─────────────────────────────────────────────────────────────
OUT_PKG="$OUT_DIR/Laeka.pkg"
PRODUCTBUILD_ARGS=(
    --distribution "$WORK_DIR/distribution.xml"
    --resources "$RESOURCES_DIR"
    --package-path "$WORK_DIR"
)
if [[ -n "$SIGN_IDENTITY" ]]; then
    PRODUCTBUILD_ARGS+=(--sign "$SIGN_IDENTITY")
fi
productbuild "${PRODUCTBUILD_ARGS[@]}" "$OUT_PKG"

echo ""
echo "✓ Built: $OUT_PKG  (v${PKG_VERSION})"
echo ""
echo "  V2 flow: Claude Code auto-install → Anthropic wizard → claude login → Laeka → frontend"
echo "  Distribute: share Laeka.pkg directly (GitHub release, laeka.ai/download)"
echo "  Install:    double-click Laeka.pkg (no terminal required)"
if [[ -z "$SIGN_IDENTITY" ]]; then
    echo ""
    echo "  ⚠ Not signed — users must allow in System Settings → Privacy & Security"
    echo "  OR: right-click → Open to bypass Gatekeeper"
fi
echo ""
