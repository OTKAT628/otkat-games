# OTKAT Hide & Seek — native 3D single-player slice

Engine target: Godot 4.7.2 (GDScript), Compatibility renderer for desktop and mobile.

Open `project.godot` in Godot 4.7.2 and run the main scene.

## Current playable loop in source
- Main menu and controls/help screen.
- First-person survivor movement with keyboard/mouse and two-zone Android touch controls.
- Walk, sprint and crouch movement; sprint consumes stamina and loud footsteps can attract the hunter.
- Twelve-second preparation phase followed by a 150-second hunt.
- Five disguise prop forms matching the mall prop set: cart, barrel, shop display, planter and suitcase.
- Hunter patrol/chase/investigation with line-of-sight checks, hearing for sprinting and close-range discovery of a disguised player.
- Three active survivor abilities: decoy lure, temporary freeze and temporary hunter slow.
- Pause/resume, win/lose result screen, replay and return-to-menu flow.
- Headless gameplay smoke test in `tests/smoke_test.gd`, invoked by the Godot 4.7.2 GitHub Actions workflow.

## Current scope and limitations
This is a local single-player vertical slice, not the complete commercial game. The map and characters still use procedural blockout geometry. There is no online multiplayer, room code/Quick Join, second hunter, finished character art/animation, complete weapon combat and armory UI, production cosmetic shop, six finished worlds or 72 finished maps yet. The weapon/cosmetic catalog is a data prototype and is not yet integrated into the match loop.

## Validation
The GitHub Actions smoke test imports the project, runs gameplay assertions for round start, disguise/collision restoration and all three abilities, then launches the main scene headlessly. Do not treat the project as verified until the workflow completes successfully and the game is also checked on an actual Android device.
