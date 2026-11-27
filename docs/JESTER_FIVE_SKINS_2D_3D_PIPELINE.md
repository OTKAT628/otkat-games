# OTKAT Jester — five official skins and 2D/3D asset pipeline

## Reference authority
The user supplied five visual references in this conversation. Treat those images as the visual source of truth. The numbered five-design sheet is especially important: design 4 is the preferred canonical unmasked hero design; design 5 is the same character wearing the mask. Preserve the distinctive jester silhouette, crown motif, black tailoring, sharp yellow/gold shapes, cyan highlights, purple accents, bells, face markings and mischievous expression. Do not redesign the mascot into a generic clown or unrelated cyberpunk character.

## Five-skin roster
The following are working production labels for the five requested variants; exact naming can be revised without changing asset IDs:
1. `jester_classic` — classic black/gold OTKAT jester look, faithful to supplied brand references.
2. `jester_neon` — same base costume and silhouette, stronger cyan/teal neon accents.
3. `jester_minimal` — simplified low-detail/casual presentation of the same character; retain signature hat, face and color blocking.
4. `jester_royal` — canonical hero skin based on design 4 in the numbered reference sheet. This is the default mentor/player skin.
5. `jester_mask` — design 5: same character and costume language, with the face mask; it is an alternate skin, not a separate character.

All five are cosmetic variants of one character rig and share body proportions, skeleton, facial controls, animation names and gameplay hitbox. No skin grants gameplay advantages.

## 2D deliverables
For each skin, produce:
- front, 3/4, side and back turnaround;
- full-body idle, explain/open palm, point left/right, lean forward, lean back, alert, angry, laugh, confused, celebrate, disappointed, thinking, sneak, welcome and farewell poses;
- face/expression atlas with neutral, grin, laugh, angry, surprised, suspicious, sad and focused;
- transparent PNG sprite exports at consistent canvas/pivot scale;
- palette swatches and material notes.
The 2D game art should retain the supplied angular anime/comic rendering style, strong black shapes, crisp highlights and yellow/cyan/purple brand palette.

## 3D deliverables
Build a real reusable 3D character asset, not just a 3D-looking illustration:
- one shared humanoid skeleton and facial rig;
- separate mesh/material variants for the five skins;
- articulated jester hat tails and bells with lightweight secondary motion;
- face/eye controls and mask toggle/variant;
- LODs and mobile-friendly material/texture budgets;
- export source in Blender format (.blend) plus glTF 2.0 (.glb) for web/game runtime;
- animation clips named consistently with the pose/emotion list above.
The 3D model must be built from the supplied references and approved turnarounds. A rendered concept image alone is not a model asset.

## Integration
- Register all five IDs in the shared cosmetic registry.
- Use `jester_royal` as the default mentor appearance; offer all five as selectable skins according to product rules.
- Reserve an owner-only entitlement for the project owner to use the mascot skin in supported games. Enforce this server-side through OTKAT ID; never trust a client flag or a display-name match.
- Tutorial runtime should select pose/emotion from events and never cover controls or block play.
- Support offline use; sync owned/equipped cosmetics when OTKAT ID is available.

## Production status and acceptance
This document is a specification only. No actual .blend, .glb, rig, sprite atlas or in-game skin integration is claimed until those files are produced, reviewed and tested. Acceptance requires: visual review against the supplied references, all five variants on the same rig, animation playback, transparent 2D exports, and a mobile performance check.
