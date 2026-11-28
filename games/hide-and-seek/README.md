# OTKAT Hide & Seek — separate 2D menu / 3D lobby foundation

Godot 4.7.2, GDScript. Main startup scene is a conventional 2D menu. The dedicated 3D waiting lobby is loaded only after choosing to create a room or start solo mode.

## Current structure
- `scenes/menu_2d.tscn`: ordinary 2D main menu, solo/multiplayer, create room, join entry point, quick-match entry point, skins, map catalogue, match settings.
- `scenes/lobby_3d.tscn`: separate 3D waiting area with avatar, map/item portals, skin changing, player/invite panel, round settings, and free-camera fly mode.
- The selected skin and room settings are stored before the scene transition and handed from the 2D menu to the 3D lobby through scene metadata. The lobby's free camera supports continuous WASD movement, mouse look, vertical movement, sprint and exit via F/Esc.

## Prototype status / honest limitations
- Lobby art is procedural blockout geometry, not final production character models or high-end environment assets.
- Skin choices currently recolor a shared placeholder model; unique character meshes, rigs, animations, unlocks and cosmetic inventory remain to be made.
- The player list is currently a local placeholder. Real room hosting/joining, server-authoritative player synchronization, invite codes, public matchmaking and round start orchestration are not complete in this revision.
- Portal catalogue screens are navigation/preview placeholders; map previews and full 20–60 per-map prop galleries are still to be implemented.
- Do not publish as a finished game until native builds, smoke tests and multiplayer device tests pass.

Map themes are original genre-inspired directions, not copied proprietary assets. External community maps should be separately installable packages, with licensing and compatibility validation before inclusion.
