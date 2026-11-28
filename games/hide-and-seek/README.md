# OTKAT Hide & Seek — network foundation prototype

Engine: Godot 4.7.2, GDScript.

## Menu and room flow
- Main menu: solo, multiplayer, settings, exit.
- Multiplayer: create world, join by code, quick match.
- Host: world name, open/private mode, password for private rooms, UDP port 27015 and displayed IP:port.
- Join: player name, world name, IP:port and room password.
- Direct ENet connection and player-position relay are implemented as the first networking slice.
- Escape returns to the main menu.

## Important current limits
- The arena and hide/seeker mechanics are still the earlier 2D prototype. The planned cooperative release target is 3D; this menu/network shell is not the final visual/gameplay version.
- Quick match currently shows the public-room discovery entry point, but a central public lobby/server directory has not been built. Open rooms can currently be joined only when players know the host's reachable IP:port.
- Internet hosting may require UDP port forwarding; no NAT traversal or relay service is included.
- Network movement is an early peer-position sync. Authoritative round state, synchronized hunter logic, reconnect handling, moderation, anti-cheat, server discovery, and real-device/network testing remain.
- No installable APK/EXE is published until the 3D game and networking are tested.

## Run locally
1. Open `project.godot` in Godot 4.7.2.
2. Run the project.
3. Solo mode uses WASD/arrow keys; E hides/unhides; R restarts.
