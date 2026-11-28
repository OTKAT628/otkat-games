# OTKAT Hide & Seek — implementation status

## Native project
- Engine target: Godot 4.7.2.
- Project: `games/hide-and-seek-3d/`.
- Main scene: `scenes/main.tscn`.
- Renderer: Compatibility, intended to support Android and desktop.

## Implemented in the current source branch
- Procedural abandoned shopping mall with atrium, closed shop fronts, columns, debris, damaged fixtures, mold, hanging vines, broken glass and fog.
- First-person survivor controller with keyboard/mouse and two-zone touchscreen movement/look.
- Walk, sprint, crouch and stamina; sprinting creates noise events that the hunter can investigate.
- Start menu, controls screen, preparation phase, timed hunt phase, pause/resume, result screen, replay and return-to-menu.
- Five matching disguise prop forms: cart, barrel, shop display, planter and suitcase. Player collision is disabled while disguised and restored when leaving the prop.
- Hunter patrol, line-of-sight chase, noise investigation, decoy lure, freeze and temporary slow effects.
- Three active abilities wired into the round: decoy, freeze and bag/slow, with cooldown handling.
- Weapon/cosmetic data registry and local inventory prototype; these are not yet fully integrated into the match.
- Headless gameplay smoke assertions in `tests/smoke_test.gd`.
- GitHub Actions workflow imports the project, runs gameplay smoke tests and launches the main scene headlessly: `.github/workflows/hide-and-seek-godot-check.yml`.

## Not yet verified
The assistant environment does not have Godot installed, so no local Godot parser or runtime test has been performed. GitHub Actions has not yet returned a completed run for the current source revision. The project still needs an actual Android device test. No APK/EXE is being presented as ready.

## Still not complete
- Online multiplayer, room codes, Quick Join, reconnect and authoritative server validation.
- Six finished worlds and the 72-map target.
- Final authored survivor/hunter models, animations, optimized production props and final materials.
- Complete weapon combat, armory UI, finished ability effects and in-match cosmetic integration.
- Progression, achievements, persistent online inventory and OTKAT ID integration.

## Next gates
1. Get the Godot 4.7.2 import and gameplay smoke tests passing; fix every parser/runtime error.
2. Test touch controls, camera, collisions, hunter navigation and round completion on Android.
3. Replace blockout character/prop art with original production-quality assets.
4. Complete the single-player game loop and its content before starting online multiplayer or packaging.
