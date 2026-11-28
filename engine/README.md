# OTKAT Engine

Independent in-house cross-platform game engine project. This is not a renamed Godot or Unity distribution.

**Status: foundation prototype, not production-ready.** First milestone: C# runtime core, scene graph, component model, fixed-step loop, renderer/input contracts, JSON scene format, CLI inspector and smoke sample.

## Technology
- C#/.NET 8: runtime, editor services and game scripting.
- C++: optional native modules after profiling.
- Python: asset/build/content tools where portable packaging is practical.
- GDScript: existing Godot projects during migration, not the primary OTKAT Engine language.
- Godot remains the production game engine until this engine passes feature, performance, platform and release gates.

## Build
`dotnet build engine/OTKAT.Engine.sln -c Release`
`dotnet run --project engine/src/Otkat.Engine.Editor -- --help`
`dotnet run --project engine/samples/StarterGame`

## Roadmap
1. Runtime core and CI.
2. Desktop host, input and 2D renderer.
3. Sprites, cameras, tilemaps, audio and UI.
4. Visual editor: viewport, hierarchy, inspector, asset browser, debugger.
5. 3D rendering, materials, lighting, animation and physics.
6. Windows/Android export and real-device QA; then Linux/macOS and others.

No platform support is claimed until native builds and device tests exist.