# OTKAT Jester — only owner-supplied image assets

## Binding direction (supersedes earlier concept-art suggestions)
Use ONLY the five image files supplied by the project owner in the conversation as the mascot art source. Do not generate, search for, substitute, or commission new mascot images. Do not use stock images or image-query results. Do not redraw, restyle, repaint, or alter the character design.

The numbered five-skin reference sheet defines the five appearances. In that sheet, design 4 is the primary unmasked look and design 5 is the masked look. Other owner-supplied images contain the character sheet, brand compositions, expression examples and pose examples. Preserve the owner's selected five variants exactly as depicted; do not invent new costumes or rename a visual variant based on an AI interpretation.

## Asset ingestion
The original uploaded files must be copied byte-for-byte into the repository by an owner-approved binary upload step. Keep originals and record SHA-256 checksums. Do not crop, recompress, vectorize, or split them unless the owner separately approves derived crops. For immediate prototype integration, display the supplied images as-is in the mascot gallery/guide panels. If the source files are not yet in the repository, do not create broken paths or claim they are integrated.

## Reactions for every skin
All five mascot skins must expose the same reaction vocabulary and event mapping. Where a specific supplied expression/pose exists, use the corresponding image as-is. Where no supplied image exists, do not fabricate a new expression image: use a restrained UI reaction (caption, speech bubble, small shake/tilt/scale/slide) over the unchanged supplied character image, and clearly treat it as a presentation effect rather than a new drawing.

Required reaction keys:
- `idle` — neutral/default
- `welcome` — welcome / greeting
- `explain` — explain / open gesture
- `point` — point at UI or target
- `thinking` — thinking / considering
- `curious` — curious / question
- `surprised` — surprise
- `angry` — angry / enemy alert
- `laugh` — laugh / playful
- `happy` — happy / success
- `celebrate` — victory
- `confused` — confused
- `sad` — sad / disappointment
- `disappointed` — failed attempt, supportive not shaming
- `suspicious` — suspicious / stealth
- `scared` — danger / incoming threat
- `sneak` — sneak / quiet movement
- `farewell` — goodbye

Every skin must implement every key, with explicit fallback to its own unchanged base image. A missing reaction must never silently show another skin. Keep the image aspect ratio and avoid covering game controls. Provide accessible alt text and reduced-motion behavior.

## Runtime contract
- Single shared `JesterGuide` component and reaction registry.
- API: `setSkin(skinId)`, `playReaction(reactionId, {caption, duration})`, `setVisible(boolean)`.
- Skin IDs: `jester_1` through `jester_5` until the owner confirms exact names.
- Persist selected skin and tutorial preferences locally first; sync through OTKAT ID only after that service is actually connected.
- In all game pages and app collections, tutorial events use the same reaction IDs.
- Do not claim 3D models or 3D animation exist. These are owner-provided 2D image assets with lightweight UI motion only.

## Current status
This document records the approved direction. The supplied binary image files have not yet been committed to the GitHub repository or wired into the live site by this text-only repository action. The next required step is binary asset upload, then implementation and browser verification.
