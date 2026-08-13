# Playing Manifest Destiny with friends

## The zero-effort way (recommended first session)

**Friends install NOTHING.** The host (the person with the mod) starts their world with
**Start server** ticked and a password. Friends run plain vanilla Valheim and use
**Join Game** → Steam friends (or right-click the host in Steam → **Join Game**).

They will see everything the wizard does — the dragon and its wingbeats, red fire, buildings
burning and collapsing, castles rising, roads, villagers, warcamps. Only the host casts.

## Friends who want their OWN dragon

Download the newest `ManifestDestiny-X.Y.Z.zip` from **https://github.com/VELLORAAI/manifest-destiny-releases/releases/latest** (public - no account needed). Every wizard gets their own
familiar and their own Keeper — dragons are stamped with their owner, so nobody steals anybody's
mount. Castles, villages, the treasury and the war are shared: one empire, several wizards.

### Windows (easiest: ONE LINE, nothing else)

Open PowerShell (Start menu → type "powershell") and paste:

```powershell
irm https://raw.githubusercontent.com/VELLORAAI/manifest-destiny-releases/main/install.ps1 | iex
```

It finds your Steam Valheim, installs the loader, installs the newest release, and you launch
Valheim from Steam like always. Done.

### Windows (alternative: r2modman)
1. Install [r2modman](https://thunderstore.io/c/valheim/p/ebkr/r2modman/), pick Valheim.
2. Install **BepInExPack Valheim** (denikson) from the online list.
3. Settings → **Import local mod** → choose the `ManifestDestiny-X.Y.Z.zip`.
4. Launch modded from r2modman. Done.

### Windows (manual)
1. Install BepInExPack Valheim (unzip its contents into the Valheim folder next to `valheim.exe`).
2. From the ManifestDestiny zip: copy `plugins/ValheimWizard` into `BepInEx/plugins/`, and
   `config/ValheimWizard` into `BepInEx/config/`.
3. Launch from Steam like always. (The mod turns the F5 console on by itself.)

### macOS (ONE LINE — tested end-to-end on a real Mac)
Open Terminal and paste:
```bash
curl -fsSL https://raw.githubusercontent.com/VELLORAAI/manifest-destiny-releases/main/install.sh | bash
```
It finds your Steam Valheim, installs the loader **with the macOS fixes** (the stock pack fails
silently on Mac without them), installs the newest release, and wires **the Steam Play button
itself** to launch modded — Launch Options are skipped entirely because Steam on macOS silently
drops them. It verifies everything and also puts a double-clickable **Valheim Modded** launcher
on your Desktop as a spare. Steam signed in → click Play → play. After a Valheim game update,
re-run the same one-liner once.

Note for guests: spells marked as needing cheats (godmode, free-build) only work for the world's
host — Valheim doesn't allow clients to enable devcommands on a friend-hosted world. Your dragon,
its fire, and all its orders work everywhere.

## House rules worth agreeing on
- `killall`, bombing runs and dragonfire don't check ownership — pets and wooden builds burn,
  whoever they belong to. `wizard_douse` is the fire brigade.
- The empire ledger (conquest count, war tier, capital growth) lives on the host's treasury.
- In-game, `wizard_friends` prints the short version of this file; `wizard` lists every spell.
