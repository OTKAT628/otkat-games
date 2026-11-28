# OTKAT Godot game consolidation

All 90 legacy Mobile 100 mini-game/challenge entries are being consolidated as internal modes and level content in three standalone Godot 4 projects. They are no longer presented as separate products in the Apps catalogue.

## Project A — OTKAT Party Circuit
Local party play for 2–4 people. Planned mode families: reaction, rhythm/timing, memory, dice/card risk, quick challenges and cooperative/competitive rounds.

Legacy mechanics to migrate:
- Tide Fisher, Echo Sequence, Last Bid, Dice Route, Bubble Pop Lab, Time Keeper, Drum Code, Fox Memory, Aurora Recall, Double Recall
- Odd Parade, Prime Parade, Pulse Window, Quiet Second, Redline, Final Beat, Risk Draft, Treasure Crew, Boss Breaker, Tiny Tracker
- Pixel Echo, Northbound, Zigzag Isle, Corner Quest, River Fork, Portal Path, Moon Phase, Wild Signal, Shadow Mark, Twin Peaks

## Project B — OTKAT Mindforge
A solo logic campaign with puzzle families, progression, hints and score.

Legacy mechanics to migrate:
- Pipe Tangle, Bridge Budget, Prism Sort, Knot Escape, Paper Fold, Color Alchemy, Odd One Out, Glyph Cipher, Vault Dial, Star Loom
- Number/sequence challenges: Zero Heroes, Sum Forge, Subtraction Bay, Multiply Market, Fraction Fix, Number Bridge, Fibo Trail, Next Step, Square Yard, Word Twist
- Memory/logic challenges: Last Frequency, Locksmith Junior, Signal Vault, Deep Archive, Card Forge, Pendulum Balance, Pendulum Zero, Gyro Lab, Gravity Trim, Mimic Hunt

## Project C — OTKAT Wild Frontier
A top-down exploration/survival and resource-management game with crafting, navigation and environmental systems.

Legacy mechanics to migrate:
- Lunar Touchdown, Power Grid, Shadow Step, Wild Balance, Windwright, Magnet Crane, Fossil Brush, Rooftop Gardener, Comet Catcher, Tiny Tactician
- Canyon Courier, Cloud Shepherd, Dungeon Draft, Forest Code, Seed Vault, Water Share, Battery Plan, Fuel Convoy, Oxygen Crew, Thermal Control
- Tide Gauge, Alternator, Beacon Keeper, Shield Wall, Treasure Crew, Tiny Giants, Reverse River, Corner Quest, River Fork, Portal Path

## Current implementation status

The first source slices are present:
- Party Circuit: local 2–4 player round/score loop with reaction, arithmetic, memory and attention rounds.
- Mindforge: 30-step generated logic campaign with answers, hints and scoring.
- Wild Frontier: movement, resource gathering, hunger, health, day progression and basic shelter crafting.

This is not yet a complete port of all 90 legacy mechanics. The list above is the migration map, not a claim that every mechanic is already playable. The old HTML files are temporarily retained as migration references until each replacement mode is implemented and verified. They are no longer listed as standalone apps or games in the public catalog.

Godot runtime/export validation and Windows/Android builds are still required. Do not mark the projects production-ready before those checks pass.
