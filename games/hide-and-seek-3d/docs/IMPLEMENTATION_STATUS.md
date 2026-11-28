# OTKAT Hide & Seek — implementation status

## Native project
- Engine target: Godot 4.7.2.
- Project: `games/hide-and-seek-3d/`.
- Main scene: `scenes/main.tscn`.
- Renderer: Compatibility, intended for Android and desktop.

## Implemented in the current source branch
- Procedural abandoned shopping mall with atrium, closed shop fronts, columns, debris, damaged fixtures, mold, hanging vines, broken glass and fog.
- First-person survivor movement with keyboard/mouse and two-zone touchscreen look/move.
- Walk, sprint, crouch and stamina; sprinting creates noise events that the hunter investigates.
- First- and third-person camera switching with camera collision handling.
- Start menu, controls, settings, profile, armory, exit, preparation phase, timed hunt, pause/resume, result screen and replay.
- Five disguise prop forms. Collision and first-person weapon view are disabled while hidden and restored when leaving disguise.
- Original modular low-poly survivor and masked hunter visuals.
- Hunter patrol, line-of-sight chase, noise investigation, decoy lure, freeze, temporary slow, health and defeat.
- Usable Apocalypse starter sidearm with firing, ammo, reserve, reload, mobile controls, raycast hits and hunter damage.
- Three active survivor abilities: decoy, freeze and bag/slow, with cooldown handling.
- Local profile save for wins, losses and selected weapon. Win/loss credit rewards.
- Credit-only Apocalypse armory with weapon unlocks and cosmetic weapon skins; no real-money store.
- Headless gameplay smoke assertions in `tests/smoke_test.gd`.
- GitHub Actions workflow imports the project, runs gameplay smoke tests and launches the main scene headlessly.

## Not yet verified
The assistant environment does not have Godot installed, so no local Godot parser or runtime test has been performed. GitHub Actions has not yet returned a completed run for the current source revision. The project still needs an actual Android device test. No APK/EXE is being presented as ready.

## Still not complete
- Online multiplayer, room codes, Quick Join, reconnect and authoritative server validation.
- Six finished worlds and the 72-map target.
- Final authored survivor/hunter models, animation sets, optimized production props and final materials.
- Full roster of weapons across all worlds, weapon animations, hit effects and finished combat balancing.
- Character cosmetics, achievements, cloud progression, persistent online inventory and OTKAT ID integration.

## Next gates
1. Get the Godot 4.7.2 import and gameplay smoke tests passing; fix every parser/runtime error.
2. Test mobile controls, camera, collisions, hunter navigation, weapon combat and round completion on Android.
3. Replace blockout character/prop art with original production-quality assets.
4. Complete and balance the single-player mode before online multiplayer or packaging.
