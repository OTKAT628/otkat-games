# OTKAT Godot game consolidation

Public product taxonomy:
- Games catalogue: standalone playable games only.
- Apps catalogue: standalone utility/service applications only.
- No browser mini-games, embedded HTML games, modes, levels or prototypes are listed as independent products.

The legacy Mobile 100 mechanics are being consolidated as internal modes and level content in three standalone Godot projects. They are not separate products.

## Engine and language standard

Godot 4 .NET with C# is the preferred implementation for the majority of new OTKAT games. Target native builds first: Windows and Android, then Linux/macOS/iOS where QA and platform requirements allow. Godot 4 C# currently has no Web export support; Android/iOS support is documented as experimental, so native device testing is mandatory. Do not promise a web build for a C# game. If a browser build is required, use a separate compatible implementation or choose GDScript for that specific project.

## Project A — OTKAT Party Circuit
Local party play for 2–4 people. Planned mode families: reaction, rhythm/timing, memory, dice/card risk, quick challenges and cooperative/competitive rounds.

Legacy mechanics to migrate:
- Tide Fisher, Echo Sequence, Last Bid, Dice Route, Bubble Pop Lab, Time Keeper, Drum Code, Fox Memory, Aurora Recall, Double Recall
- Odd Parade, Prime Parade, Pulse Window, Quiet Second, Redline, Final Beat, Risk Draft, Treasure Crew, Boss Breaker, Tiny Tracker
- Pixel Echo, Northbound, Zigzag Isle, Corner Quest, River Fork, Portal Path, Moon Phase, Wild Signal, Shadow Mark, Twin Peaks

## Project B — OTKAT Mindforge
A solo logic campaign with puzzle families, progression, hints and score. **C# migration pilot:** the first 30-step campaign has been ported from GDScript to Godot .NET/C#. This is an initial gameplay slice, not a finished game.

Legacy mechanics to migrate:
- Pipe Tangle, Bridge Budget, Prism Sort, Knot Escape, Paper Fold, Color Alchemy, Odd One Out, Glyph Cipher, Vault Dial, Star Loom
- Number/sequence challenges: Zero Heroes, Sum Forge, Subtraction Bay, Multiply Market, Fraction Fix, Number Bridge, Fibo Trail, Next Step, Square Yard, Word Twist
- Memory/logic challenges: Last Frequency, Locksmith Junior, Signal Vault, Deep Archive, Card Forge, Pendulum Balance, Pendulum Zero, Gyro Lab, Gravity Trim, Mimic Hunt

## Project C — OTKAT Wild Frontier
A top-down exploration/survival and resource-management game with crafting, navigation and environmental systems.

Legacy mechanics to migrate:
- Lunar Touchdown, Power Grid, Shadow Step, Wild Balance, Windwright, Magnet Crane, Fossil Brush, Rooftop Gardener, Comet Catcher, Tiny Tactician
- Canyon Courier, Cloud Shepherd, Dungeon Draft, Forest Code, Seed Vault, Water Share, Battery Plan, Fuel Convoy, Oxygen Crew, Thermal Control
- Tide Gauge, Alternator, Beacon Keeper, Shield Wall, Tiny Giants, Reverse River, Color Scout, Letter Dock, Orbit Word, Winter Note

## Current implementation status

- Party Circuit: first GDScript gameplay slice; planned C# migration.
- Mindforge: initial 30-step campaign migrated to C#/.NET.
- Wild Frontier: first GDScript gameplay slice; planned C# migration.
- The 90 legacy mechanics above are a migration inventory, not a claim that every mechanic is playable.
- Old HTML sources remain temporarily as migration references; do not present them as products or delete them until replacement modes are implemented and verified.
- Native Windows/Android export and real-device QA are required before calling any project release-ready.
