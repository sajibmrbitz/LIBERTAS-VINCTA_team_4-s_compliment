# Asset integration contract

Collision, interactions and sensing never infer dimensions or behavior from textures.

## Characters

The playable Els uses `scenes/player/female_frames.tres`, built from the ten sheets in
`ifat/female`. The existing Deprived One enemy uses `scenes/enemy/zombie_frames.tres`,
built from the supplied zombie Idle, Walk, Run and Attack1 sheets. Main spawns that
enemy on the ground, upper and basement floors; it remains dormant until Hearing.

Both scenes assign SpriteFrames directly, so their art is also visible in the editor.
Animation names use `<action>_<direction>` with s, sw, w, nw, n, ne, e and se suffixes.
`character_animation.gd` maps facing to those directions and preserves gait frames
when turning. Female sheets use direction rows; zombie sheets use separate angle
files (0 south, 090 east) with frames read left to right, then top to bottom.

Player movement selects idle/walk/run. Crouching slows walk playback and compresses
the existing Visual node because no crouch sheet was supplied. Interactions select
interact, pickup, unlock or flashlight; caught plays death and holds its final frame.
Damage and stagger clips are available for future hooks; this game currently uses
instant capture rather than health or combat. Zombie animation selects idle when
stationary, walk while investigating/patrolling, run while chasing, and attack on capture.

Both sprites retain fixed 256-pixel cells and a (128, 224) foot anchor, using offset
(0, -96) on centered sprites. Player scale is 0.4; zombie scale is 0.55. Collision
remains an independent 24 by 14 foot footprint. No per-frame cropping is performed.
Awakening retains its existing rotation tween and control lock.

Rebuild the checked-in resources after replacing sheets:

```powershell
python scripts/tools/build_character_frames.py
```

Godot imports PNGs automatically; Python is only needed to rebuild resources.
After pickup, a small flashlight prop is attached to Els's hand. Its compact
trapezoid light pool renders behind her on the floor; the old radial light is disabled.

## Environment

The supplied 2D pack and piano are integrated by default through
`scripts/levels/estate_art.gd` and `data/estate_art.json`. See
[environment asset placement](ENVIRONMENT_ASSETS.md) for the installed furniture,
atlas region, remaining art slots and runtime verification commands.

Each `scenes/levels/{intro,ground,upper,basement}_floor.tscn` exposes:

- `environment_art`: assign a PackedScene containing the final room art.
- `use_imported_assets`: enabled by default; builds the supplied estate dressing when no custom `environment_art` is assigned.
- `show_placeholder_environment`: disable after assigning art.
- `zone_id`: selects layout data; preserve unless deliberately changing progression.
- `debug_noise`: leave false for release.

The artist scene should use room-local coordinates: floor/depth band y=354–634, foot positions generally y=375–615, wall above it. Intro width is 1,800; other groups are 7,200. Use upright side-facing sprites with visible floor depth. Background art should use a negative z index; foreground elements should use their foot Y or a suitable foreground z index.

Generated Geometry owns collision; Props owns Y-sorted furniture/interactables; Markers owns spawn/exit references. Replace visuals, not these gameplay responsibilities. The placeholder background includes subtle Parallax2D windows and floor seams.

Built-in art places furniture bodies using explicit positions and footprints in
the art catalog. Floor decorations, piano, vanity, ritual lectern and Custodian
table also register collision with navigation before its grid is built.
Interaction origins remain in front of their supporting furniture collision.
Loose pickups and passages use the generated essentials atlas; keys receive
high-contrast markers while retaining normal floor sorting. Door roots align to
the rear wall at y=362. A successful passage opens around its left edge over a
dark doorway, moves Els through, and loads the destination with that door open.
Els emerges to y=418 before the destination door closes and control returns.

`data/estate_layout.json` supplies prop type, unique ID, position and exported behavior values. Tune future art placement there or replace the builder with authored children using the same interaction contract. If furniture collision changes, update the matching navigation blockers and verify prop accessibility and enemy navigation in Godot.

## Props

Reusable presets are under `scenes/interactables/`. Assign Texture2D assets at `Visual/Sprite2D.texture`, then align position and scale. The placeholder hides automatically when a texture is supplied. Keep root script, Visual and child names intact.

Use distinct sprites for doors, keys, letters, flashlight, lockpick kit, hiding spots and puzzle seals. Text is replaceable in the layout JSON. IDs must remain unique; progression saves those IDs. Key and letter collection does not depend on visual size. The tool pouch uses the generic reach animation because `pickup` is specifically authored around a brass key.

## Audio

Assign AudioStream resources on `scenes/systems/audio_director.tscn` (or the Main/Audio instance's Inspector overrides). Named AudioStreamPlayer children are constructed at runtime. Every unassigned slot remains silent.

| Exported slots | Suggested format / content | Bus |
| --- | --- | --- |
| rain, house_ambience | Loop-ready OGG ambience | Ambience |
| drip, breathing, building_creak | Short WAV/OGG accents | Ambience |
| wood_footsteps, stone_footsteps, water_footsteps | Short footstep WAV files | SFX |
| key_sting | Short sense-restoration accent | SFX |
| monster_breathing, monster_search | Creature accents | SFX |
| door, lockpick, flashlight, ui | Short interaction/UI sounds | SFX |
| calm_music, searching_music, chase_music | Loop-ready OGG tension layers | Music |

Master, Music, Ambience and SFX buses are defined in `default_bus_layout.tres`. Tension changes crossfade over 1.2 seconds; key screen treatment lasts 0.65 seconds. Gameplay noise is an EventBus signal, separate from audible sound. Leave detection balance independent of sound volume.

## UI and story

Assign a Theme resource to `Main/UI.ui_theme`. The UI provides readable default controls without external fonts. Replace sense text with icons only while retaining ledger-driven state. Subtitle queue accepts optional speaker, line and duration; current gameplay uses timed advancement. Letters pause danger and close with E/Esc. No final letter pages are claimed.

Edit Awakening timing/lines in `scripts/intro/awakening.gd` and pickup/door lines in BaseInteractable. Letter slots and provisional text are in the JSON. Ending titles/text are isolated in `GameHUD.show_ending()`. The supplied brief's Els lines are already wired.

## Integration checklist

1. Verify the integrated female and zombie animations in all eight directions.
2. Assign room-art scenes; hide only environment placeholders.
3. Align props to their existing foot markers and assign textures.
4. Assign audio streams and check loops, mix and subtitle timing.
5. Assign Theme/icons; verify 1280×720, 16:10 and fullscreen.
6. Fill credits/licenses and review placeholder narrative text.
7. Play through each ending and check collisions, stealth, checkpoints and menus.
8. Install matching export templates; test Windows and Web independently.
