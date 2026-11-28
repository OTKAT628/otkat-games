# OTKAT Hide & Seek — native 3D single-player slice

Engine target: Godot 4.7.2 (GDScript), Compatibility renderer for desktop and mobile.

Open `project.godot` in Godot 4.7.2 and run the main scene.

## Playable loop implemented in source
- Main menu with start and controls/help screens.
- One first-person survivor in an abandoned shopping mall.
- Keyboard/mouse controls and two-zone Android touch movement/look controls.
- Twelve-second preparation phase followed by a 150-second hunt phase.
- Five disguise prop types matching the map's prop categories: shopping cart, barrel, shop display, planter and suitcase.
- Hunter patrol, chase and investigate behavior; a survivor can be caught when the hunter reaches their disguise.
- Win/lose result screen, pause/resume, restart and return-to-menu flow.

## Current scope and limitations
This is a local single-player vertical slice, not the complete commercial game. The map and characters still use procedural blockout geometry. There is no online multiplayer, room code/Quick Join, second hunter, finished character art/animation, complete combat and weapon UI, production cosmetic shop, six finished worlds or 72 finished maps yet. The weapon/cosmetic catalog is a data prototype and is not yet integrated into the match loop.

## Validation
A GitHub Actions smoke-test workflow is included at `.github/workflows/hide-and-seek-godot-check.yml`. It imports the project and launches the main scene headlessly with Godot 4.7.2. Do not treat the project as verified until that workflow completes successfully and the game is also checked on an actual Android device.
