#!/usr/bin/env bash
#
# Manifest Destiny - one-line installer for macOS friends.
#
#   curl -fsSL https://raw.githubusercontent.com/VELLORAAI/manifest-destiny-releases/main/install.sh | bash
#
# Self-contained: finds your Steam Valheim, installs the BepInEx loader WITH the two macOS
# launcher fixes (the stock Thunderstore pack silently fails on Mac without them), installs the
# newest Manifest Destiny release, verifies everything, and tells you exactly how to launch.

set -euo pipefail

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
fail() { printf '\033[31mERROR: %s\033[0m\n' "$1" >&2; exit 1; }

VALHEIM_DIR="${VALHEIM_DIR:-$HOME/Library/Application Support/Steam/steamapps/common/Valheim}"
[[ -d "$VALHEIM_DIR" ]] || fail "Valheim not found at: $VALHEIM_DIR
Install Valheim through Steam first (or set VALHEIM_DIR and re-run)."

APP=""
for c in "$VALHEIM_DIR/valheim.app" "$VALHEIM_DIR/Valheim.app"; do [[ -d "$c" ]] && APP="$c" && break; done
[[ -n "$APP" ]] || fail "No valheim.app inside $VALHEIM_DIR - is this the macOS build?"
bold "Valheim: $VALHEIM_DIR"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# --- 1. Loader (skipped if present) ---------------------------------------------------
if [[ ! -d "$VALHEIM_DIR/BepInEx" ]]; then
  bold "Installing the BepInEx loader..."
  curl -fsSL "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/" -o "$WORK/pack.zip"
  unzip -q "$WORK/pack.zip" -d "$WORK/pack"
  SRC="$WORK/pack"; [[ -d "$WORK/pack/BepInExPack_Valheim" ]] && SRC="$WORK/pack/BepInExPack_Valheim"
  cp -R "$SRC/BepInEx" "$VALHEIM_DIR/"
  for item in doorstop_libs doorstop_config.ini start_game_bepinex.sh winhttp.dll; do
    [[ -e "$SRC/$item" ]] && cp -R "$SRC/$item" "$VALHEIM_DIR/"
  done
else
  bold "BepInEx already installed - leaving it alone."
fi

# --- 2. The two macOS fixes (idempotent) ----------------------------------------------
# The stock launcher targets Linux (executable_name=valheim.x86_64) and loses the injection
# variables across SIP-protected `arch`. Both fail SILENTLY - the game starts unmodded.
LAUNCHER="$VALHEIM_DIR/start_game_bepinex.sh"
[[ -f "$LAUNCHER" ]] || fail "Loader launcher missing - reinstall failed?"
/usr/bin/sed -i '' "s|^executable_name=.*|executable_name=\"$(basename "$APP")\"|" "$LAUNCHER"
if grep -q '^exec "\$executable_path" "\$@"' "$LAUNCHER"; then
  /usr/bin/sed -i '' 's|^exec "\$executable_path" "\$@"|exec arch -x86_64 -e DYLD_INSERT_LIBRARIES="$DYLD_INSERT_LIBRARIES" -e DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH" "$executable_path" "$@"|' "$LAUNCHER"
fi
xattr -dr com.apple.quarantine "$VALHEIM_DIR/BepInEx" "$VALHEIM_DIR/doorstop_libs" "$LAUNCHER" 2>/dev/null || true
chmod +x "$LAUNCHER"

# --- 3. Newest Manifest Destiny -------------------------------------------------------
bold "Fetching the newest Manifest Destiny release..."
URL="$(curl -fsSL "https://api.github.com/repos/VELLORAAI/manifest-destiny-releases/releases/latest" \
  | /usr/bin/python3 -c "import sys,json; d=json.load(sys.stdin); print(next(a['browser_download_url'] for a in d['assets'] if a['name'].startswith('ManifestDestiny-')))")"
bold "Installing $(basename "$URL")..."
curl -fsSL "$URL" -o "$WORK/mod.zip"
unzip -q "$WORK/mod.zip" -d "$WORK/mod"
mkdir -p "$VALHEIM_DIR/BepInEx/plugins" "$VALHEIM_DIR/BepInEx/config"
[[ -d "$WORK/mod/plugins" ]] && cp -R "$WORK/mod/plugins/"* "$VALHEIM_DIR/BepInEx/plugins/"
[[ -d "$WORK/mod/config" ]] && cp -R "$WORK/mod/config/"* "$VALHEIM_DIR/BepInEx/config/"
xattr -dr com.apple.quarantine "$VALHEIM_DIR/BepInEx/plugins" 2>/dev/null || true

# --- 4. Prove it ----------------------------------------------------------------------
[[ -f "$VALHEIM_DIR/BepInEx/plugins/ValheimWizard/ValheimWizard.dll" ]] || fail "Mod DLL missing after install - tell the host."
[[ -f "$VALHEIM_DIR/doorstop_libs/libdoorstop_x64.dylib" ]] || fail "Doorstop library missing - tell the host."
grep -q 'arch -x86_64' "$LAUNCHER" || fail "macOS launcher fix did not apply - tell the host."

# A double-clickable launcher on the Desktop, so 'launch modded' is one click.
CMD="$HOME/Desktop/Valheim Modded.command"
printf '#!/bin/bash\nopen -a Steam\ncd "%s"\nexec ./start_game_bepinex.sh -console\n' "$VALHEIM_DIR" > "$CMD"
chmod +x "$CMD"; xattr -d com.apple.quarantine "$CMD" 2>/dev/null || true

bold ""
bold "VERIFIED - mod, loader and macOS fixes all in place."
bold "Launch: double-click 'Valheim Modded' on your Desktop (Steam must be signed in)."
bold "Then join your friend's world. E mounts your dragon; hold click pours fire. Have fun."
