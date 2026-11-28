# OTKAT Hide & Seek — arsenal and cosmetic system

## Scope

The first catalog is authored for six distinct world themes. Each world owns its own equipment collection; an item from one world does not automatically appear in another world's loot pool. The catalog is original OTKAT content. Hide Zone is used only as a broad genre/reference point for a realistic hunter arsenal, not as a source of copied models, textures, names, animations, or weapon skins.

## World collections

| World | Original equipment | Style |
|---|---|---|
| Apocalypse | Rivet-12, Scout-9 | Salvaged metal, field repairs, wasteland finish |
| Cartoon | Popper Blaster, Squeak-двойка | Toy-like silhouettes, comic and candy finishes |
| Anime | Kitsune-6, Ronin Edge | Stylized energy sidearm and energy blade |
| Realistic | Vanguard-12, Sentinel-45 | Grounded modern tactical equipment and restrained finishes |
| Sci-fi | ARC-Vector, Pulse Hammer | Plasma technology and futuristic stun equipment |
| Mystery | Реликварий, Warden Bell | Arcane focus and sonic relic |

Each weapon entry contains an ID, display name, category, base rarity, credit value and gameplay tuning fields. Each has three individual skins with their own IDs, rarity and value.

## Rarity and value

Rarity is assigned independently to the base weapon and to each skin:
- Common — 1.0 value factor
- Uncommon — 1.35
- Rare — 1.8
- Epic — 2.7
- Legendary — 4.5
- Mythic — 8.0

The current registry stores explicit credit values per item. Values are balancing placeholders for an in-game, earnable credit economy; they are not real-money prices and do not imply cash trading. Rarity must not create a pay-to-win damage advantage. Weapon combat stats are tuned separately from cosmetics.

## Inventory rules

- A weapon must be owned before its skin can be equipped.
- A skin must be owned before it can be equipped.
- Each weapon has one active skin at a time.
- The prototype inventory stores credits, owned weapon IDs, owned skin IDs and equipped skin IDs in the local Godot user data directory.
- Local saves are for offline prototyping only. Online ownership, purchases, rewards and currency changes must be validated by an authoritative server and later linked to OTKAT ID/Supabase.
- No paid loot boxes, cash value, player-to-player trading or randomized real-money purchases are part of this prototype.

## Files added

- `scripts/arsenal_registry.gd` — six world collections, weapon/skin metadata, rarity labels and lookup/value helpers.
- `scripts/cosmetic_inventory.gd` — local prototype ownership, equip and credit-save operations.
- `scripts/mall_builder.gd` — darker mall dressing: floor/wall mold, hanging vines, glass shards, fallen ceiling pieces and light fog.

## Not yet wired or verified

This commit adds the data layer and local inventory prototype. It does not yet provide final 3D weapon models, skin textures, firing/reload animations, a complete armory UI, combat integration, loot/reward screens, multiplayer server validation or OTKAT ID sync. The Godot project has not been run in this environment; parser and device testing are still required before calling this playable.
