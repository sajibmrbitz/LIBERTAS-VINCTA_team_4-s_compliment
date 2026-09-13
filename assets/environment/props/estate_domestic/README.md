# Estate Domestic Props Atlas

`estate_domestic_props_alpha.png` was generated with OpenAI's built-in image generation tool for this project on 2026-09-13. It supplies the upper-floor bed, toy chest, washstand, and bathtub used by `data/estate_art.json`.

The generated RGB output included a baked checkerboard even though transparent output was requested. A deterministic edge-connected background extraction converted only the surrounding neutral checker pixels to alpha; the four illustrated props were not redrawn or altered.

## Final Prompt Set

### Prop Sheet

```text
Use case: stylized-concept
Asset type: transparent 2D game prop sprite sheet for the existing LIBERTAS VINCTA top-down/three-quarter pixel-art horror game
Primary request: Create one clean 2-by-2 sprite sheet containing exactly four separate antique domestic furniture props: top-left a full wooden four-poster bed with muted burgundy bedding; top-right a large open wooden toy chest with a few simple cloth toys visible; bottom-left a Victorian washstand with porcelain basin and oval mirror; bottom-right a white claw-foot bathtub.
Style/medium: hand-painted pixel art matching the attached in-game furniture, crisp nearest-neighbor edges, subdued late-Victorian horror palette, readable at roughly 120-180 pixels wide in game
Composition/framing: each prop fully visible in a consistent front three-quarter/top-down game perspective, grounded at its own bottom-center foot point, centered inside one quadrant with generous transparent spacing; no prop touches another
Lighting/mood: dim neutral ambient light, subtle warm wood, no cast scene background
Constraints: genuinely transparent background; no floor, walls, shadows extending outside each prop, labels, letters, UI, characters, text, watermark, borders, grid lines, or decorative framing; exact 2-by-2 arrangement; preserve clear separation for atlas cropping
```

### Transparency Retry

```text
Use case: background-extraction
Asset type: transparent 2D game prop sprite sheet
Primary request: Remove the gray-and-white checkerboard background completely and replace it with genuine transparent alpha.
Input images: Image 1 is the edit target.
Constraints: change only the background; preserve the bed, open toy chest and toys, washstand and mirror, and claw-foot bathtub exactly as drawn, at the same size, pixel-art style, positions, spacing, colors, and 2-by-2 arrangement; retain crisp edges and interior details; no checkerboard pixels, no replacement background, no floor, no labels, no grid, no border, no text, no watermark. The exported PNG must have a real alpha channel with alpha 0 in every background area.
```
