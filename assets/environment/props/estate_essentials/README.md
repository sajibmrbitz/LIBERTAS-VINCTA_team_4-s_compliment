# Estate essentials

Generated for LIBERTAS VINCTA on 2026-09-12 using the built-in OpenAI imagegen
tool in generate mode, without reference images. This is not part of the
Food & Drink asset pack. The original generated PNG is unchanged.

Saved asset: `assets/environment/props/estate_essentials/estate_essentials.png`.
RGBA size: 1536x1024. Six props: key, sealed letter, flashlight, tool pouch,
closed door and stair doorway. Catalog regions in `data/estate_art.json` use
individual bounds, not uniform cells, because the generated door frames extend
above the nominal second-row boundary. Godot trims transparent margins at load.

## Generation prompt

```text
Create one transparent-background 2D video game sprite atlas, landscape 1536 by 1024 pixels. Exactly six separate props in a clean invisible 3-column, 2-row grid; each 512x512 cell has one centered object with generous transparent padding. NO grid lines, captions, lettering, cast shadows, glow, scene background or floor. Style: crisp dark outlines and simple hand-painted flat shading matching cozy hand-drawn furniture sprites, slightly elevated side view, muted colors and clear silhouettes. Top-left: a bright gold antique key with a round bow and two square teeth, lying diagonally. Top-middle: an ivory paper envelope with a red wax seal. Top-right: a small dark grey handheld flashlight with a silver lens, lying diagonally, no light beam. Bottom-left: a compact closed brown leather tool pouch with a brass buckle. Bottom-middle: an upright FRONT-FACING closed wooden interior door with two recessed wood panels, brass handle, thick dark teal wooden doorframe and a grey stone threshold. Bottom-right: an upright FRONT-FACING open doorway with the same dark teal wooden frame and threshold; within the dark opening show five simple grey stone steps going upward. Architecture is tall and narrow, takes about 400px height and 230px width per cell. Smaller props take about 330px width in their cells. Complete objects fully visible within each cell, do not overlap cells. Real RGBA transparency, no painted checkerboard. This is an asset sheet for a fictional exploration game.
```
