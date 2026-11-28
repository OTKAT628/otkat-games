# OTKAT Hide & Seek — implementation status

## Native project baseline
- Engine: Godot 4.7.2 target.
- Project path: `games/hide-and-seek-3d/`.
- First vertical slice: abandoned shopping mall, first-person movement, touchscreen look/move, disguise interaction, basic hunter AI, prep/hunt timer and round outcome.

## Explicitly not complete
The six world themes and 72-map minimum remain a production target, not completed content. Multiplayer room hosting, authoritative server validation, 12-player and 30-player modes, final hunter/survivor models, animation, weapon systems, customization, achievements, persistent progression and OTKAT ID integration remain unimplemented.

## Next development gates
1. Run/import the project in Godot 4.7.2 and fix all parser/runtime issues.
2. Replace procedural blockout props with authored optimized assets and improve lighting/material quality.
3. Build map data registry and production layouts for all 72 maps.
4. Implement proper prop selection/settling, hide spots and hunter perception/search.
5. Add multiplayer transport, authoritative match server, room codes, quick join and reconnect.
6. Implement combat, progression, customization, achievements and save integration.
7. Only after game-complete criteria and device testing: create Android / Windows packages.
