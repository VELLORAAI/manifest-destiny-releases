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

# --- 3b. Bundled worlds (never overwrites a world you already have) -------------------
if [[ -d "$WORK/mod/worlds" ]]; then
  WORLDS_DIR="$HOME/Library/Application Support/IronGate/Valheim/worlds_local"
  mkdir -p "$WORLDS_DIR"
  for w in "$WORK/mod/worlds/"*; do
    base="$(basename "$w")"
    if [[ -e "$WORLDS_DIR/$base" ]]; then
      bold "World file $base already present - keeping yours."
    else
      cp "$w" "$WORLDS_DIR/"
      bold "World installed: $base"
    fi
  done
fi

# --- 4. Steam Play button = modded (bundle shim) --------------------------------------
# Launch Options are the classic way in, and Steam on macOS silently drops them: they live
# in Steam's memory, flush to disk on Steam's own schedule, and a real client was observed
# executing the bare app path with options set (console_log, 2026-08-13). So the intercept
# moves inside the bundle where Steam cannot miss it: the real Mach-O becomes <name>.real
# and a /bin/sh shim execs the loader in its place. SIP strips DYLD_* across any exec into
# /bin/sh, so even a doubled-up launch chain injects exactly once. Steam's file verification
# restores vanilla binaries after game updates - re-running this installer re-applies.
# Newer macOS ships App Management protection: a terminal that has not been granted it gets
# a silent "Operation not permitted" on ANY write inside another app's bundle - no prompt,
# no dialog. So the shim is best-effort: when macOS says no, the install still finishes and
# the Desktop launcher covers playing modded; the message at the end explains the one-time
# System Settings toggle that unlocks the Play button for people who want it.
SHIM_OK=1
INNER="$(defaults read "$APP/Contents/Info" CFBundleExecutable)"
MACOS_DIR="$APP/Contents/MacOS"
if file "$MACOS_DIR/$INNER" | grep -q "Mach-O"; then
  mv "$MACOS_DIR/$INNER" "$MACOS_DIR/$INNER.real" 2>/dev/null || SHIM_OK=0
elif [[ ! -x "$MACOS_DIR/$INNER.real" ]]; then
  fail "$INNER is neither the game binary nor shimmed, and no $INNER.real exists.
Verify game files in Steam, then re-run this installer."
fi
if [[ $SHIM_OK -eq 1 ]]; then
if ! cat > "$MACOS_DIR/$INNER" 2>/dev/null <<'SHIM'
#!/bin/sh
# Manifest Destiny shim: every launch of this bundle goes through the BepInEx
# loader, so the Steam Play button starts the game modded. The real Mach-O
# binary lives beside this script as <name>.real. If Steam's file verification
# restores vanilla files (game updates do), re-run the one-line installer.
D=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
V=$(CDPATH= cd -- "$D/../../.." && pwd -P)
REAL="$D/$(basename -- "$0").real"
LOADER="$V/start_game_bepinex.sh"
[ -x "$REAL" ] || exit 1
if [ -x "$LOADER" ]; then
  exec "$LOADER" "$REAL" -console "$@"
fi
exec "$REAL" "$@"
SHIM
then
  SHIM_OK=0
  # The rename landed but the shim write was refused: put the real binary back so the
  # bundle keeps launching (vanilla) instead of being left headless.
  if [[ -x "$MACOS_DIR/$INNER.real" && ! -e "$MACOS_DIR/$INNER" ]]; then
    mv "$MACOS_DIR/$INNER.real" "$MACOS_DIR/$INNER" 2>/dev/null || true
  fi
fi
fi
if [[ $SHIM_OK -eq 1 ]]; then
  chmod 755 "$MACOS_DIR/$INNER"
  # Loader default -> the real binary, so the Desktop launcher and any direct loader run
  # stay single-hop instead of resolving CFBundleExecutable back into the shim.
  /usr/bin/sed -i '' "s|^executable_name=.*|executable_name=\"$(basename "$APP")/Contents/MacOS/$INNER.real\"|" "$LAUNCHER"
fi

# --- 5. Prove it ----------------------------------------------------------------------
[[ -f "$VALHEIM_DIR/BepInEx/plugins/ValheimWizard/ValheimWizard.dll" ]] || fail "Mod DLL missing after install - tell the host."
[[ -f "$VALHEIM_DIR/doorstop_libs/libdoorstop_x64.dylib" ]] || fail "Doorstop library missing - tell the host."
grep -q 'arch -x86_64' "$LAUNCHER" || fail "macOS launcher fix did not apply - tell the host."
if [[ $SHIM_OK -eq 1 ]]; then
  file "$MACOS_DIR/$INNER.real" | grep -q "Mach-O" || fail "Real game binary check failed - tell the host."
  head -1 "$MACOS_DIR/$INNER" | grep -q '^#!/bin/sh' || fail "Steam Play button shim check failed - tell the host."
fi

# A double-clickable launcher on the Desktop, so 'launch modded' is one click.
CMD="$HOME/Desktop/Valheim Modded.command"
printf '#!/bin/bash\nopen -a Steam\ncd "%s"\nexec ./start_game_bepinex.sh -console\n' "$VALHEIM_DIR" > "$CMD"
chmod +x "$CMD"; xattr -d com.apple.quarantine "$CMD" 2>/dev/null || true

bold ""
if [[ $SHIM_OK -eq 1 ]]; then
  bold "VERIFIED - mod, loader, macOS fixes and the Steam Play button shim are all in place."
  bold "Launch Valheim from Steam like always - the mod is part of the normal game now."
  bold "(The 'Valheim Modded' Desktop launcher works too, and the F5 console is always on.)"
else
  bold "VERIFIED - mod and loader are in place. One macOS-only step was skipped:"
  bold "your Mac's App Management protection silently blocks editing the Steam Play button."
  bold ""
  bold "EASY MODE (nothing to fix): double-click 'Valheim Modded' on your Desktop to play."
  bold ""
  bold "Want the Steam Play button modded too? One-time toggle:"
  bold "  System Settings > Privacy & Security > App Management > + > add Terminal > ON,"
  bold "  fully quit Terminal (Cmd-Q), reopen it, and re-run this installer one-liner."
fi
bold "You get a dragon and a horse: E mounts, C calls the dragon, Summon Steed is on the G wheel."
bold "The Castleheim castle world is in your Select World list. Have fun."
