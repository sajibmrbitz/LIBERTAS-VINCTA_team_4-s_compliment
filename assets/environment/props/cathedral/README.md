# Cathedral Props Atlas

`cathedral_props.png` was generated with OpenAI's built-in image generation tool for this project on 2026-09-13.

Prompt summary: a transparent 3-by-2 atlas of six hand-painted, slightly elevated side-view game props for the Sunken Cathedral: collapsed rubble, a stone sarcophagus, a blood altar, a sigil forge, a ley-nexus anchor, and a cracked ritual seal. The requested palette was cold charcoal, oxidized teal, muted bone, restrained crimson, and cyan, with no characters, text, religious symbols, floor shadows, or watermark.

The atlas is sliced at runtime through `data/estate_art.json` and is intended only for LIBERTAS VINCTA's cathedral zones.

`survival_pickups.png` was generated with the same built-in tool on 2026-09-13. Its prompt requested a transparent 2-by-2 atlas containing a weathered teal battery, corked green bottle, brass wind-up clock, and steel lockpick set in a leather sleeve, using the same hand-painted game-sprite style. It is also sliced through `data/estate_art.json`.

## Final prompts

### Cathedral props

```text
Use case: stylized-concept
Asset type: transparent 2D video game prop atlas for LIBERTAS VINCTA's Sunken Cathedral levels
Primary request: create exactly six separate environmental props in an invisible 3-column by 2-row grid on a 1536x1024 RGBA canvas.
Subjects, left to right: top row (1) collapsed grey cathedral rubble with broken carved stone and roots, (2) ancient closed stone sarcophagus with restrained funerary carving, (3) waist-high dark stone blood altar with a shallow empty red-stained basin; bottom row (4) compact gothic sigil forge with iron stand and dim crimson runes, (5) tall freestanding ley-nexus anchor made of cracked stone rings around a muted cyan crystal, (6) circular cracked ritual seal stone with four empty key sockets and one still-sealed ward.
Style/medium: crisp hand-painted 2D game sprites, dark outlines, simple flat shading, slightly elevated side view, matching cozy hand-drawn furniture sprites but made eerie and weathered.
Composition: one complete centered object per 512x512 cell with generous transparent padding, bottom-center ground contact, no overlap across cells.
Color palette: cold charcoal stone, oxidized teal, muted bone, restrained crimson and cyan accents.
Constraints: genuine transparent background, all objects fully visible, consistent perspective and scale, no characters, no blood or gore, no text, no captions, no symbols resembling real-world religions, no grid lines, no glow haze, no cast floor shadows, no watermark.
```

### Survival pickups

```text
Use case: stylized-concept
Asset type: transparent 2D pickup atlas for LIBERTAS VINCTA
Primary request: create exactly four separate, immediately recognizable survival-game pickups in an invisible 2-column by 2-row grid on a square RGBA canvas.
Subjects, left to right: top row (1) compact vintage flashlight battery with brass contacts and muted teal casing, (2) single empty dark green glass bottle with a small cork; bottom row (3) palm-sized antique brass wind-up alarm clock with two bells and a winding key, (4) slim two-piece steel lockpick set in a small open worn leather sleeve.
Style/medium: crisp hand-painted 2D game sprites, dark brown-grey outlines, simple flat shading, matching the existing cozy hand-drawn furniture props but slightly eerie and weathered.
Composition/framing: one complete centered object per equal square cell, generous transparent padding, consistent slightly elevated side view, bottom-center ground contact, no overlap across cells.
Color palette: weathered brass, oxidized teal, dark bottle green, worn brown leather, cool steel.
Constraints: genuine transparent background, all four objects fully visible, consistent scale, no characters, no text, no labels, no grid lines, no glow haze, no cast floor shadows, no watermark.
```
