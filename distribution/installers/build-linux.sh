#!/usr/bin/env bash
# build-linux.sh — Build Laeka.AppImage for Linux (V1.5)
#
# Status: V1.5 — scaffold present, requires appimagetool to build
# Ref: https://github.com/AppImage/AppImageKit
#
# Usage:
#   ./build-linux.sh
#   # Output: installers/Laeka.AppImage (chmod +x + double-click to install)
#
# Prerequisites:
#   - appimagetool in PATH, or set APPIMAGETOOL=/path/to/appimagetool-x86_64.AppImage
#   - FUSE installed (most modern distros already have it)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$SCRIPT_DIR"
APPIMAGETOOL="${APPIMAGETOOL:-appimagetool}"

# Fallback: auto-download appimagetool if not found
if ! command -v "$APPIMAGETOOL" &>/dev/null; then
    echo "[laeka-build] appimagetool not found — downloading..."
    APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    curl -fsSL "$APPIMAGETOOL_URL" -o /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
    echo "[laeka-build] Downloaded appimagetool"
fi

# ── AppDir structure ──────────────────────────────────────────────────────────
WORK_DIR=$(mktemp -d /tmp/laeka-appimage-XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
APPDIR="$WORK_DIR/Laeka.AppDir"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/laeka"

# Copy scripts
cp "$DIST_DIR/install-laeka.sh"   "$APPDIR/usr/share/laeka/install.sh"
cp "$DIST_DIR/uninstall-laeka.sh" "$APPDIR/usr/share/laeka/uninstall.sh"
cp "$DIST_DIR/update-laeka.sh"    "$APPDIR/usr/share/laeka/update.sh"
chmod 755 "$APPDIR/usr/share/laeka/"*.sh

# AppRun — entrypoint when AppImage is executed
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/usr/bin/env bash
# AppRun — entrypoint for Laeka AppImage
set -euo pipefail
APPIMAGE_DIR="$(dirname "$(readlink -f "$0")")"
echo ""
echo "  Laeka Installer"
echo "  ───────────────"
echo ""
bash "$APPIMAGE_DIR/usr/share/laeka/install.sh"
EXIT_CODE=$?
echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "  Installation complete. Launch Claude Code to start Laeka."
else
    echo "  Installation failed (exit $EXIT_CODE)."
    echo "  See output above for details."
fi
echo ""
# Keep terminal open if run via double-click (GUI file manager)
if [[ "${TERM:-}" == "" ]]; then
    read -r -p "Press Enter to close..." || true
fi
exit $EXIT_CODE
APPRUN
chmod +x "$APPDIR/AppRun"

# .desktop file (required by AppImageKit)
cat > "$APPDIR/Laeka.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Laeka Installer
Exec=AppRun
Icon=laeka
Type=Application
Categories=Utility;
Terminal=true
DESKTOP

# Icon placeholder (512x512 PNG required for proper AppImage)
# Copy real icon if available, else create a minimal one
if [[ -f "$SCRIPT_DIR/resources/laeka-icon.png" ]]; then
    cp "$SCRIPT_DIR/resources/laeka-icon.png" "$APPDIR/laeka.png"
else
    # Minimal 1x1 pixel PNG (transparent) — replace with real icon before distribution
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82' > "$APPDIR/laeka.png"
    echo "[laeka-build] WARN: Using placeholder icon. Replace resources/laeka-icon.png before distribution."
fi

# ── Build AppImage ────────────────────────────────────────────────────────────
OUT_APPIMAGE="$OUT_DIR/Laeka.AppImage"
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$OUT_APPIMAGE"

chmod +x "$OUT_APPIMAGE"

echo ""
echo "✓ Built: $OUT_APPIMAGE"
echo ""
echo "  Distribute: share Laeka.AppImage directly"
echo "  Install:    chmod +x Laeka.AppImage && ./Laeka.AppImage"
echo "              (or double-click in a GUI file manager with AppImage support)"
echo ""
echo "  For auto-open in GUI file managers, install:"
echo "    sudo apt install libfuse2  # Ubuntu 22.04+"
echo ""
