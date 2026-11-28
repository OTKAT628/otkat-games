# OTKAT Hide & Seek — native 3D single-player slice

Engine target: Godot 4.7.2 (GDScript), Compatibility renderer for desktop and mobile.

Open `project.godot` in Godot 4.7.2 and run the main scene.

## Current gameplay implemented in source
- Main menu, help, settings, profile, armory and exit.
- First-person and collision-aware third-person camera modes.
- Keyboard/mouse and Android touch controls.
- Walk, sprint, crouch, stamina and noise-based hunter investigation.
- Twelve-second preparation phase followed by a 150-second hunt.
- Five disguise prop forms: shopping cart, barrel, shop display, planter and suitcase. Player collision and weapon view are hidden while disguised and restored when leaving.
- Hunter patrol, line-of-sight chase, hearing, investigation, close-range capture and health/damage.
- A usable starter sidearm with ammo, reserve ammo, reload, mobile fire/reload buttons and a hunter health readout. The hunter can be defeated by landing enough hits.
- Three survivor abilities: decoy lure, temporary freeze and temporary hunter slow.
- Original modular low-poly survivor and masked hunter models assembled from procedural parts.
- Local profile persistence for wins, losses and selected weapon; wins award 100 credits and losses award 25.
- Credit-only armory for Apocalypse weapons and cosmetic weapon skins. No real-money purchases.
- Headless gameplay assertions in `tests/smoke_test.gd`, invoked by the Godot 4.7.2 GitHub Actions workflow.

## Current scope and limitations
This is one local single-player map using procedural geometry and character art, not the complete commercial game. Online multiplayer, room codes/Quick Join, the other five worlds and 72 finished maps, authored production art/animations, full survivor/hunter roster, full cosmetics for characters, achievements, cloud progression and OTKAT ID sync are not complete.

## Validation
The GitHub Actions workflow imports the project, runs gameplay assertions for scene startup, disguise/collision restoration, crouch, camera switching, weapon damage, abilities and victory rewards, then launches the main scene headlessly. Do not treat the project as verified until the workflow completes successfully and the game is also checked on an actual Android device.
