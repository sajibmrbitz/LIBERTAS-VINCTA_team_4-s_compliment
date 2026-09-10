# Asset integration contract

Collision, interactions and sensing never infer dimensions or behavior from textures.

## Characters

| Asset type | Assignment point | Contract |
| --- | --- | --- |
| Player SpriteFrames resource / sprite sheets | `scenes/player/player.tscn → Visual/AnimatedSprite2D.sprite_frames` | Art uses a foot origin; adjust sprite position/scale to align feet. |
| Enemy SpriteFrames resource | `scenes/enemy/deprived_one.tscn → Visual/AnimatedSprite2D.sprite_frames` | Supply walk_left and walk_right for current enemy hooks. |
| Optional flashlight beam texture | Player `Visual/Flashlight/PointLight2D.texture` | Replace generated radial light texture; retain node names. Hide BeamPlaceholder when final effect is assigned. |
| Collision tuning | Character `CollisionShape2D` | Independent 24×14 foot footprint; keep the foot origin at the actor's position. |

Player animation hooks: idle_left, idle_right, walk_left, walk_right, walk_up, walk_down, sprint_left, sprint_right, crouch_idle, crouch_walk, interact, flashlight, caught. Missing animations fall back to muted placeholder geometry without errors. Provide every listed state to remove fallback flashes. Awake/get-up is currently a restrained visual rotation tween in the intro sequencer; replace that presentation independently of its control lock.

## Environment

Each `scenes/levels/{intro,ground,upper,basement}_floor.tscn` exposes:

- `environment_art`: assign a PackedScene containing the final room art.
- `show_placeholder_environment`: disable after assigning art.
- `zone_id`: selects layout data; preserve unless deliberately changing progression.
- `debug_noise`: leave false for release.

The artist scene should use room-local coordinates: floor/depth band y=354–634, foot positions generally y=375–615, wall above it. Intro width is 1,800; other groups are 7,200. Use upright side-facing sprites with visible floor depth. Background art should use a negative z index; foreground elements should use their foot Y or a suitable foreground z index.

Generated Geometry owns collision; Props owns Y-sorted furniture/interactables; Markers owns spawn/exit references. Replace visuals, not these gameplay responsibilities. The placeholder background includes subtle Parallax2D windows and floor seams.

`data/estate_layout.json` supplies prop type, unique ID, position and exported behavior values. Tune future art placement there or replace the builder with authored children using the same interaction contract. If furniture collision changes, update the matching navigation blockers and verify prop accessibility and enemy navigation in Godot.

## Props

Reusable presets are under `scenes/interactables/`. Assign Texture2D assets at `Visual/Sprite2D.texture`, then align position and scale. The placeholder hides automatically when a texture is supplied. Keep root script, Visual and child names intact.

Use distinct sprites for doors, keys, letters, flashlight, lockpick kit, hiding spots and puzzle seals. Text is replaceable in the layout JSON. IDs must remain unique; progression saves those IDs. Key and letter collection does not depend on visual size.

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

1. Assign character SpriteFrames and verify every fallback state.
2. Assign room-art scenes; hide only environment placeholders.
3. Align props to their existing foot markers and assign textures.
4. Assign audio streams and check loops, mix and subtitle timing.
5. Assign Theme/icons; verify 1280×720, 16:10 and fullscreen.
6. Fill credits/licenses and review placeholder narrative text.
7. Play through each ending and check collisions, stealth, checkpoints and menus.
8. Install matching export templates; test Windows and Web independently.
