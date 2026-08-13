# Manifest Destiny - one-line installer for Windows friends.
#
# Open PowerShell and paste:
#   irm https://raw.githubusercontent.com/VELLORAAI/manifest-destiny-releases/main/install.ps1 | iex
#
# It finds your Steam Valheim, installs the BepInEx loader, installs the newest
# Manifest Destiny release, and you launch Valheim from Steam like always.
# On Windows the loader hooks in by itself (winhttp.dll) - no launch options needed.

$ErrorActionPreference = "Stop"
function Say($m) { Write-Host $m -ForegroundColor Cyan }
function Die($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

# --- 1. Find Valheim ------------------------------------------------------------------
Say "Looking for Valheim..."
$steam = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
if (-not $steam) { Die "Steam not found. Install Steam and Valheim first." }

$libraries = @($steam)
$vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
if (Test-Path $vdf) {
    (Get-Content $vdf) | Select-String '"path"\s+"([^"]+)"' | ForEach-Object {
        $libraries += $_.Matches[0].Groups[1].Value.Replace('\\','\')
    }
}

$valheim = $null
foreach ($lib in $libraries) {
    $candidate = Join-Path $lib "steamapps\common\Valheim"
    if (Test-Path (Join-Path $candidate "valheim.exe")) { $valheim = $candidate; break }
}
if (-not $valheim) { Die "Valheim not found in any Steam library. Install it via Steam first." }
Say "Valheim: $valheim"

# --- 2. BepInEx loader ----------------------------------------------------------------
$work = Join-Path $env:TEMP "manifestdestiny-install"
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $work | Out-Null

if (-not (Test-Path (Join-Path $valheim "BepInEx"))) {
    Say "Installing the BepInEx loader..."
    $packZip = Join-Path $work "bepinex.zip"
    Invoke-WebRequest "https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2333/" -OutFile $packZip
    Expand-Archive $packZip -DestinationPath (Join-Path $work "pack") -Force
    $inner = Join-Path $work "pack\BepInExPack_Valheim"
    if (-not (Test-Path $inner)) { $inner = Join-Path $work "pack" }
    Copy-Item (Join-Path $inner "*") $valheim -Recurse -Force
} else {
    Say "BepInEx already installed - leaving it alone."
}

# --- 3. Manifest Destiny --------------------------------------------------------------
Say "Fetching the newest Manifest Destiny release..."
$release = Invoke-RestMethod "https://api.github.com/repos/VELLORAAI/manifest-destiny-releases/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "ManifestDestiny-*.zip" } | Select-Object -First 1
if (-not $asset) { Die "No release zip found - tell the host." }
Say "Installing $($asset.name)..."

$modZip = Join-Path $work "mod.zip"
Invoke-WebRequest $asset.browser_download_url -OutFile $modZip
Expand-Archive $modZip -DestinationPath (Join-Path $work "mod") -Force

New-Item -ItemType Directory -Path (Join-Path $valheim "BepInEx\plugins") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $valheim "BepInEx\config") -Force | Out-Null
if (Test-Path (Join-Path $work "mod\plugins")) {
    Copy-Item (Join-Path $work "mod\plugins\*") (Join-Path $valheim "BepInEx\plugins") -Recurse -Force
}
if (Test-Path (Join-Path $work "mod\config")) {
    Copy-Item (Join-Path $work "mod\config\*") (Join-Path $valheim "BepInEx\config") -Recurse -Force
}
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

# --- 4. Prove it ----------------------------------------------------------------------
$dll = Join-Path $valheim "BepInEx\plugins\ValheimWizard\ValheimWizard.dll"
if (-not (Test-Path $dll)) { Die "Install finished but the mod DLL is missing at $dll - tell the host." }
$loader = Join-Path $valheim "winhttp.dll"
if (-not (Test-Path $loader)) { Die "BepInEx loader (winhttp.dll) missing from $valheim - tell the host." }

Say ""
Say "VERIFIED: mod and loader are in place."
Say "DONE. Launch Valheim from Steam like always and join your friend's world."
Say "You get your OWN dragon: E mounts it, hold click pours fire, C calls it. Have fun."
Say "(Optional: add -console to Steam launch options for the F5 console spells.)"
