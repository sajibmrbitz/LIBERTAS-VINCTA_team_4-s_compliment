# Implementation report — LIBERTAS VINCTA

Implemented and validated in **Godot 4.7.2 stable (ed1daf0bf)** for **4's Compliment**. The current brief supersedes the former side-view milestone limit: the active game is now a 2D elevated room-plane greybox with intro, progression, stealth, three endings and replaceable asset hooks.

## 1. Created files

- `AI_DISCLOSURE.md`
- `ASSET_CREDITS.md`
- `KNOWN_ISSUES.md`
- `README.md`
- `data/estate_layout.json`
- `default_bus_layout.tres`
- `docs/ASSET_INTEGRATION.md`
- `docs/IMPLEMENTATION_REPORT.md`
- `docs/QA.md`
- `export_presets.cfg`
- `scenes/enemy/deprived_one.tscn`
- `scenes/interactables/base_interactable.tscn`
- `scenes/interactables/door.tscn`
- `scenes/interactables/exit_trigger.tscn`
- `scenes/interactables/flashlight.tscn`
- `scenes/interactables/hiding_spot.tscn`
- `scenes/interactables/key_pickup.tscn`
- `scenes/interactables/letter_pickup.tscn`
- `scenes/interactables/locked_door.tscn`
- `scenes/interactables/lockpick_tool.tscn`
- `scenes/interactables/puzzle_interactable.tscn`
- `scenes/intro/awakening.tscn`
- `scenes/levels/basement_floor.tscn`
- `scenes/levels/ground_floor.tscn`
- `scenes/levels/intro_floor.tscn`
- `scenes/levels/upper_floor.tscn`
- `scenes/systems/audio_director.tscn`
- `scripts/core/event_bus.gd`
- `scripts/core/event_bus.gd.uid`
- `scripts/core/freedom_ledger.gd`
- `scripts/core/freedom_ledger.gd.uid`
- `scripts/core/game_manager.gd`
- `scripts/core/game_manager.gd.uid`
- `scripts/enemy/deprived_one.gd`
- `scripts/enemy/deprived_one.gd.uid`
- `scripts/interactables/base_interactable.gd`
- `scripts/interactables/base_interactable.gd.uid`
- `scripts/intro/awakening.gd`
- `scripts/intro/awakening.gd.uid`
- `scripts/levels/estate_room.gd`
- `scripts/levels/estate_room.gd.uid`
- `scripts/main/main.gd`
- `scripts/main/main.gd.uid`
- `scripts/player/room_camera.gd`
- `scripts/player/room_camera.gd.uid`
- `scripts/systems/audio_director.gd`
- `scripts/systems/audio_director.gd.uid`
- `scripts/systems/noise_model.gd`
- `scripts/systems/noise_model.gd.uid`
- `scripts/systems/session_settings.gd`
- `scripts/systems/session_settings.gd.uid`
- `scripts/ui/game_hud.gd`
- `scripts/ui/game_hud.gd.uid`

The .gd.uid files are engine-generated stable script metadata, not cache. The pre-existing, untracked `scenes/levels/hearing_test_level.tscn` was inspected and retained unchanged; it is not counted as newly created by this implementation. Temporary test scripts, validation logs, screenshots and the validation-user cache were subsequently removed at the user's request. The results below record checks performed before that cleanup.

## 2. Modified files

- `project.godot`: five autoloads and room-depth input actions; existing Main entry point and Godot 4 configuration retained.
- `scenes/main/main.tscn`: preserved World, Entities and UI; added scene coordination, audio and Awakening.
- `scenes/player/player.tscn`: retained CharacterBody2D; replaced gravity-body collider with independent foot collision; added replaceable animated visual, flashlight and bounded camera.
- `scripts/player/player.gd`: adapted movement to normalized horizontal/depth locomotion; added interactions, hiding, flashlight, noise and animation hooks.

The initial implementation made no commits or pushes. A subsequent user-authorized cleanup removes temporary testing artifacts and publishes the game framework; caches remain excluded.

## 3. Scene hierarchy

```text
Main (Node2D; Y sorted)
├── World (Node2D; Y sorted)
│   └── IntroFloor / GroundFloor / UpperFloor / BasementFloor (runtime instance)
│       ├── Backdrop (placeholder walls, floor, seams, parallax)
│       ├── Geometry (StaticBody2D boundaries)
│       ├── Props (Y-sorted furniture and reusable interactables)
│       ├── Markers (player, return, enemy and prop locations)
│       └── EnvironmentArt (optional PackedScene assignment)
├── Entities (Node2D; Y sorted)
│   ├── Player (CharacterBody2D)
│   │   ├── CollisionShape2D (foot footprint)
│   │   ├── Visual
│   │   │   ├── Shadow / PlaceholderVisual / AnimatedSprite2D
│   │   │   └── Flashlight (beam placeholder + PointLight2D)
│   │   └── Camera2D (independent smoothed room-plane tracking)
│   └── DeprivedOne (outside intro)
│       ├── CollisionShape2D
│       ├── Visual (placeholder + AnimatedSprite2D)
│       └── DebugState (off by default)
├── UI (CanvasLayer; HUD/subtitles/letters/pause/settings/endings)
├── Audio (silent-safe AudioStreamPlayer hooks and tension)
└── Awakening (intro sequencer)
```

Room geometry and props are built from the layout JSON at runtime. Inspect them through Godot's Remote scene tree while playing.

## 4. Autoloads

| Autoload | Responsibility |
| --- | --- |
| EventBus | Cross-system signals; noise, senses, detection, hiding, interactions, subtitles, audio and endings |
| FreedomLedger | Canonical keys, derived sense flags/stage, unique letters, persistent flags and eligibility |
| GameManager | Intro/play/pause/reading/caught/ending states, scene transitions and runtime checkpoints |
| NoiseModel | Surface multipliers and gameplay footstep events, separate from audible SFX |
| SessionSettings | Audio bus levels and fullscreen settings for the current session |

## 5. Inputs

`move_left` A/Left; `move_right` D/Right; `move_up` W/Up; `move_down` S/Down; `sprint` Shift; `crouch` Ctrl; `interact` E; `flashlight` F; `pause` Esc.

## 6. Implemented gameplay

Normalized accelerated movement with reduced depth speed; speed exports; sprint/crouch; foot collision; Y sorting; camera limits and cinematic focus; line-of-sight-filtered nearby E interactions; one-shot pickups; flashlight light/signal; footsteps and surface noise; hiding; three puzzle seals; five unique letters; subtitle queue; ledger screen pulse; minimal sense HUD; pausing/reading; volume/fullscreen controls; enemy states; death fade; snapshots and restart; three playable text endings.

BaseInteractable and its scene presets cover Door, LockedDoor, KeyPickup, LetterPickup, FlashlightPickup, LockpickToolPickup, HidingSpot, PuzzleInteractable and ExitTrigger. Runtime behavior is shared rather than duplicated across ten scripts.

## 7. Awakening flow

Black screen → rain/drip/breathing/creak hooks → slow fade → Els lying down → “...Where am I?” → get-up placeholder and agency restored → flashlight with “Mine...” / “How did it get over there?” → tools with “At least I came prepared.” → locked-door reaction → short locksmith beat → door fades open toward a dark corridor → creak and “Hello?” → ground-floor gameplay.

There is no objective popup or theme counter. Every missing audio stream is safe.

## 8–9. Freedom progression and enemy stages

| Stage | New enemy capability | Player consequence |
| --- | --- | --- |
| Deprived | Dormant, no hearing/sight response | Movement and light are safe |
| Hearing | WANDER → INVESTIGATE noise → SEARCH | Sprint, glass and water become detectable |
| Sight | Range/FOV/occlusion detection → CHASE | Exposed/lighted movement and flashlight use carry risk |
| Memory | Observed hiding history, visible route samples → PREDICT_HUNT | Repeated observed hiding/routes can be rechecked |

The enemy uses AStarGrid2D with inflated obstacle cells, periodic repathing and a reachable-lane fallback. Physical CharacterBody2D movement still enforces collision. It never teleports through walls. Memory is bounded to three observed hiding spots and four visible route samples; unseen remote hiding is not recorded. Debug radius/state/path/noise drawing defaults off.

## 10. Greybox progression

Cold Foyer (1,800 pixels) → Ground (7,200: Music Room, Dining Hall, Servant's Pantry) → Upper (7,200: Portrait Gallery, Master Bedroom, Nursery/Linen) → Basement (7,200: Flooded Cellar, Wine Cellar, Ritual Chamber).

Stairs connect room groups. Floor depth spans roughly y=354–634. Furniture offers occlusion and alternative walking lanes. Glass/carpet choices follow Hearing; light/shadow choices follow Sight; water, hiding and a ritual-pressure interaction lead into Memory. The basement service return unlocks after Memory.

These are compact room groups with named areas, not separate full-size rooms for each name. The 8–15 minute target remains subject to measured human playtesting.

## 11. Ending conditions

- **Full Awakening:** exactly three keys; interact with the ground-floor front door.
- **Partial Mercy:** exactly two keys; interact with the basement maintenance escape.
- **Vantree:** zero or one key plus at least three letters; interact with the ground-floor custodian seal.

All three execute. The third branch is intentionally a short isolated text ending, not a second campaign.

## 12–14. Audio and asset integration

Master/Music/Ambience/SFX buses are defined. Rain, drips, house ambience, breathing/creak, three footstep families, key sting, creature sounds, door/lockpick/flashlight/UI and CALM/SEARCHING/CHASE music slots exist. Named players are built from exported AudioStream fields; empty slots remain silent. Music crossfades over 1.2 seconds.

Exact asset types, node paths, animation names and integration steps are in [ASSET_INTEGRATION.md](ASSET_INTEGRATION.md). Assign SpriteFrames to character AnimatedSprite2D nodes, Texture2D to prop Sprite2D nodes, PackedScene room art to each floor's environment_art export, AudioStream assets to Audio, and a Theme to Main/UI. Collision and gameplay IDs remain independent.

No final art/audio is installed. The team still needs final assets, approved letter/ending text, mix/pacing/balance passes and credits.

## 15. Known limitations / work not verified

See [KNOWN_ISSUES.md](../KNOWN_ISSUES.md). No technical implementation blocker remains for the supplied greybox framework. Human balance/release QA, the requested 8–15 minute duration and actual Windows/Web builds could not be verified as complete. Matching export templates were absent from the standard local directory; none were installed automatically. Presets include the JSON but binaries were not generated.

Settings/checkpoints are session-only. Navigation geometry is static. Room transitions are immediate. Puzzle interactions are deliberately simple. The old corridor is a retained reference, not the active level. All current letter/ending text beyond supplied dialogue is provisional.

## 16–17. Validation and exact testing procedure

Run Main with F5 in Godot 4.7.2. Full step-by-step route and manual release checklist are in [QA.md](QA.md).

Validation performed:

- Godot headless editor import: no parser errors.
- Framework suite: **54 checks, 0 failures** on the final gameplay scripts.
- Movement suite: **9 checks, 0 failures**, including actual traversal around all six blockers.
- Rendered smoke suite: **3 checks, 0 failures** plus native OpenGL captures of both floor styles, pause/settings, letters and an ending.
- Rendered screenshots were inspected for framing, readability and layout.
- `git diff --check`: clean.

A misplaced Hearing Key was found during visual review, moved out of furniture collision, then verified by the real E-input path and new all-room placement checks.

Some progression tests freeze the enemy and call interactions directly to isolate state transitions. This is not a claim of an uninterrupted human stealth run. The separate movement suite runs live enemy navigation. The restricted Windows environment reports a certificate-store error unrelated to the offline game. Final validation redirected editor cache/settings to the ignored workspace cache to avoid protected user-profile writes.

## 18. Suggested commit sequence

1. `refactor: adapt player and camera to elevated room-plane movement`
2. `feat: add freedom ledger events and runtime game lifecycle`
3. `feat: add awakening reusable interactions and subtitle UI`
4. `feat: add hearing sight memory and stealth enemy behavior`
5. `feat: connect estate greybox puzzles letters and ending branches`
6. `feat: add pause settings and silent-safe audio hooks`
7. `test: cover progression checkpoints sensing and live navigation`
8. `docs: document asset integration QA and jam export setup`

These are suggestions for coherent review/staging; the human developer decides when to commit and push.
