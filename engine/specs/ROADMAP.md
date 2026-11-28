# OTKAT Engine roadmap

| Milestone | Deliverable | Acceptance gate |
|---|---|---|
| M0 | C# runtime foundation | .NET build, smoke sample, CI |
| M1 | Desktop host + input + 2D renderer | visible window, input tests, frame capture |
| M2 | 2D game systems | sprites, cameras, tilemaps, audio, UI |
| M3 | Editor alpha | hierarchy, inspector, viewport, assets, save/load |
| M4 | 3D foundation | mesh/material/camera/light pipeline |
| M5 | Physics and animation | collision suite, skeletal animation samples |
| M6 | Android host/export | APK build, lifecycle, touch, device matrix |
| M7 | Production readiness | profiling, crash reporting, docs, sample game release |

Godot remains the production engine for OTKAT games until OTKAT Engine meets the relevant acceptance gates. Existing Godot projects are not to be rewritten prematurely.

## Product quality loop

The engine and products built with it should support reference-led research without cloning: document user problems, review public feedback, prioritize repeated pain points, design original workflows and assets, then validate improvements with tests and users.
