# Architecture

Principles: independent runtime; explicit backend boundaries; serializable/diff-friendly scenes; small core with optional modules; stable APIs; no premature feature claims.

Layers: Core (IDs/time/diagnostics), Scene (entities/components/transforms), Runtime (fixed and variable updates), Platform (window/input/files), Rendering (commands and resource handles), Content (scene serialization/assets), Editor (project and scene inspection).

Current boundaries: renderer is an interface only; sample is headless. No GPU backend, physics solver, audio mixer, 3D importer, Android host or visual editor exists yet. Those are future milestones.