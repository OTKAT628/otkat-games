# OTKAT Hide & Seek — implementation status

## Native project
- Engine target: Godot 4.7.2.
- Project: `games/hide-and-seek-3d/`.
- Main scene: `scenes/main.tscn`.
- Renderer: Compatibility, intended to support Android and desktop.

## Implemented in the current source branch
- Procedural abandoned shopping mall with atrium, closed shop fronts, columns, debris, damaged fixtures, mold, hanging vines, broken glass and fog.
- First-person survivor controller with keyboard/mouse and two-zone touchscreen movement/look.
- Start menu, controls screen, preparation phase, timed hunt phase, pause/resume, result screen, replay and return-to-menu.
- Five matching disguise prop forms: cart, barrel, shop display, planter and suitcase.
- Basic hunter patrol, chase and investigation; close-range discovery of a disguised survivor ends the round.
- Weapon/cosmetic data registry and local inventory prototype; these are not yet fully integrated into the match.
- GitHub Actions smoke-test workflow for Godot 4.7.2 import and headless main-scene launch: `.github/workflows/hide-and-seek-godot-check.yml`.

## Not yet verified
The assistant environment does not have Godot installed, so no local Godot parser or runtime test has been performed. The new GitHub Actions workflow must complete successfully, followed by an actual Android device test. No APK/EXE is being presented as ready.

## Still not complete
- Online multiplayer, room codes, Quick Join, reconnect and authoritative server validation.
- Six finished worlds and the 72-map target.
- Final authored survivor/hunter models, animations, optimized production props and final materials.
- Complete weapon combat, armory UI, ability effects and in-match cosmetic integration.
- Progression, achievements, persistent online inventory and OTKAT ID integration.

## Next gates
1. Fix every parser/runtime issue reported by the Godot smoke test.
2. Test touch controls, camera, collisions, hunter navigation and round completion on Android.
3. Replace blockout character/prop art with original production-quality assets.
4. Complete the single-player game loop and its content before starting online multiplayer or packaging.
