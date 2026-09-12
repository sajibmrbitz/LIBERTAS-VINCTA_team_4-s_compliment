# Environment assets

The imported furniture is enabled by default on all four floors. Run the project
with F5, then start a new game from the menu. No manual texture assignments are
needed. Room contents are generated at runtime, so use the Remote scene tree to
inspect them while playing.

## Placement

| Area | Installed artwork |
| --- | --- |
| Cold Foyer | Patterned tiles, wood paneling, framed windows, benches, coat stand, flower table and screen |
| Music Room | Grand piano and bench at `piano_seal`, seating, bookshelves and candle tables |
| Dining Hall | Dining tables and chairs, place settings, water jug, serving carts and sideboards |
| Servant's Pantry | Tiled walls, serving hatch, pots, pans, plates, trays and dishes; the Custodian book has its own table |
| Portrait Gallery / Master Bedroom | Paneling, carpet treatment, reading furniture, folding screens and a framed tabletop vanity seal |
| Nursery / Linen Passage | High chair, wooden chair, bookshelves, bench and screen at `linen_hide` |
| Flooded Cellar / Wine Cellar | Brick walls, dark floorboards, water overlay, bottle crates, wine racks and bottle cabinets |
| Ritual Chamber | Candle tables, screens and a book-bearing lectern; the original ritual interaction remains at x=4090 |

40 source PNGs supply 45 catalog textures, including a generated atlas for keys,
letters, flashlight, tool pouch, doors and stairs. Modern cafe equipment, neon signs, takeaway packaging,
fresh desserts and unrelated bar equipment remain unused. Existing character,
footstep and ambience integrations are preserved. The warm piano music is not
assigned as horror ambience.

## Editing placements

`data/estate_art.json` contains the texture catalog and per-floor dressing:

- `textures`: original file paths, with optional atlas regions in source pixels.
- `surfaces`: `[start_x, end_x, wall_asset, floor_asset]` bands.
- `furniture`: artwork, explicit foot position and footprint for named collision bodies.
- `interactables`: artwork attached to the existing progression IDs.
- `decorations`: `[asset, foot_x, foot_y, display_width, optional_details]`.
- `details`: `[asset, local_foot_x, local_foot_y, display_width]` on parent furniture.
- `footprint`: explicit collision width/depth for furniture and supported interactions.
- `furniture_scale`, `decoration_scale`: visual scales relative to catalog widths.
- `decoration_footprints`: collision width/depth for floor-standing decorative props.
- `passage_labels`: destination names shown above door/stair sprites.
- `sort_offset`: visual sorting anchor for a tabletop interaction, leaving its E target and rendered position unchanged.

Sprites preserve aspect ratio and use bottom-center anchors. Transparent margins
are excluded with cached AtlasTextures. The original PNGs are unchanged.
`piano1.png` uses region `(357, 49, 270, 287)`, showing only the right-hand grand
piano and bench. It does not require a separately cropped PNG.

`scripts/levels/estate_art.gd` constructs the presentation. `estate_room.gd` still
owns physics bodies, navigation, surfaces, spawning and progression. Furniture
positions and footprints match the smaller visual scale. Piano, vanity, lectern
and Custodian table bodies join collision and navigation, with their interaction
points eight pixels in front. Floor-standing decorations have feet at y=392 and
explicit blockers, leaving the foreground walking route clear. Every bench is
rotated four degrees around its foot anchor so one end points subtly toward the camera.

Doors and stairways stand against the rear wall at y=362. Nearby windows are
omitted to prevent overlaps. All floor bands extend to the end trim, including
the foyer's formerly blank corridor. Exit approaches remain unobstructed. Doors
foreshorten around their left edge to expose a framed dark opening. Els walks
through it, emerges from the matching open doorway, then closes it from y=418.

Loose pickups use contrasting backing markers with normal floor draw order. The
Hearing Key is at (1960, 525), in the open space beside the piano, with a pulsing
gold marker. Interaction prompts identify nearby pickups and passage destinations.
Puzzle steps, noise intensity, progression IDs and key requirements are unchanged.
The floor flashlight is 32 pixels wide. Once collected, a 14-pixel copy remains
in Els's hand and its 130-pixel light pool stays behind her sprite on the floor.
The tool pouch uses `interact`, rather than the key-specific `pickup` action.

Set `use_imported_assets` to false on a floor for the previous greybox. A custom
`environment_art` scene takes priority over this built-in dressing, preserving the
existing artist scene workflow. `show_placeholder_environment` does not hide the
installed artwork or its stealth surface markings.

The existing `data/*.json` export include filter covers this catalog as well as
the gameplay layout. Original license text is alongside the props pack.

## Remaining artwork

Doors/stairs and loose pickups now use the generated essentials atlas; see its
[provenance and prompt](../assets/environment/props/estate_essentials/README.md).
The supplied pack contains no bed, cot, ancestral portraits or final ritual architecture.
The tabletop vanity reuses a blank wooden frame. Those are future art slots,
not newly invented story items or finished portrait/bedroom artwork.

## Verification

Run with the installed Godot executable, substituting its path for `godot`:

```powershell
godot --headless --path . res://tests/verify_estate_assets.tscn --quit-after 1800
godot --path . res://tests/verify_estate_assets.tscn --resolution 1280x720 --windowed --audio-driver Dummy --quit-after 1800 -- --capture
godot --path . res://tests/verify_game_route.tscn --resolution 1280x720 --windowed --audio-driver Dummy --quit-after 9000
```

The check loads Main for every floor and verifies atlas bounds, replacement
visuals, foot anchors, navigation and unobstructed E access to every interaction.
It exercises hiding, three-step puzzles, locked/unlocked keys, checkpoint ledger
restoration, room reloads and the greybox override. Render mode also checks for
nonblank frames and writes twenty-one room, open-door and flashlight views under
`build/asset-verification/`.

The route test requires rendering because the loading screen waits for a drawn
frame. It checks actual door transitions and the Full Awakening route, with
accelerated time and frozen enemies. These are focused integration checks, not
a full playthrough of all endings or a Windows/Web export test.
