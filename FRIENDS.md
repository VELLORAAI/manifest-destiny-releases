# Playing Manifest Destiny with friends

## The zero-effort way (recommended first session)

**Friends install NOTHING.** The host (the person with the mod) starts their world with
**Start server** ticked and a password. Friends run plain vanilla Valheim and use
**Join Game** → Steam friends (or right-click the host in Steam → **Join Game**).

They will see everything the wizard does — the dragon and its wingbeats, red fire, buildings
burning and collapsing, castles rising, roads, villagers, warcamps. Only the host casts.

## Friends who want their OWN dragon

Install the mod from the release zip (`ManifestDestiny-X.Y.Z.zip`). Every wizard gets their own
familiar and their own Keeper — dragons are stamped with their owner, so nobody steals anybody's
mount. Castles, villages, the treasury and the war are shared: one empire, several wizards.

### Windows (easiest: r2modman)
1. Install [r2modman](https://thunderstore.io/c/valheim/p/ebkr/r2modman/), pick Valheim.
2. Install **BepInExPack Valheim** (denikson) from the online list.
3. Settings → **Import local mod** → choose the `ManifestDestiny-X.Y.Z.zip`.
4. Launch modded from r2modman. Done.

### Windows (manual)
1. Install BepInExPack Valheim (unzip its contents into the Valheim folder next to `valheim.exe`).
2. From the ManifestDestiny zip: copy `plugins/ValheimWizard` into `BepInEx/plugins/`, and
   `config/ValheimWizard` into `BepInEx/config/`.
3. Add `-console` to Steam Launch Options. Launch.

### macOS
Clone/copy this repo, then:
```bash
scripts/install-friend.sh path/to/ManifestDestiny-X.Y.Z.zip
```
It installs the loader (with the macOS launcher fixes this repo carries) and unpacks the mod.
Launch with `scripts/play.sh`.

## House rules worth agreeing on
- `killall`, bombing runs and dragonfire don't check ownership — pets and wooden builds burn,
  whoever they belong to. `wizard_douse` is the fire brigade.
- The empire ledger (conquest count, war tier, capital growth) lives on the host's treasury.
- In-game, `wizard_friends` prints the short version of this file; `wizard` lists every spell.
