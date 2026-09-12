# LIBERTAS VINCTA

**Team:** 4's Compliment

**GameJam theme:** DEGREE OF FREEDOM

**Engine:** Godot 4.7.2 stable

A compact psychological survival horror / stealth exploration game set in Hollowmere Estate. The project uses Godot 2D to compose a three-quarter elevated side view: upright characters, visible floor depth, horizontal exploration and restrained depth movement. No jumping, gravity-based platforming, 3D, combat or inventory combinations.

The game is playable from Awakening through three short ending branches. The female main character and zombie enemy use the supplied sprite sheets. All four floors now use selected estate furniture, wall and floor textures from the supplied 2D props pack, with the grand piano at the Music Room seal. Generated pickup and door/stair sprites replace their rectangles; furniture scale, exit coverage and piano key visibility are corrected throughout. Benches face slightly toward the camera, Els visibly carries the flashlight, and doors animate open, traversal and arrival closing. Letter copy, some audio slots and specialized room artwork remain prototypes.

Room dressing is configured in `data/estate_art.json`; see [environment asset placement](docs/ENVIRONMENT_ASSETS.md) for the selected assets, remaining gaps and verification commands.

## Run

1. Import `project.godot` in Godot **4.7.2**.
2. Allow scripts/resources to import, then press **F5** to run Main.
3. Wait through the short Awakening sequence.
4. Approach the flashlight and tool kit, then press E. Try the door once; press E again with both items to open it.
5. Explore the Music Room, Dining Hall and Pantry, then use the stairs to the upper floor and basement.

Use F5, not F6 on an individual generated room: Main supplies actors, UI, audio and progression.

## Controls

| Action | Input |
| --- | --- |
| Horizontal movement | A / D or Left / Right |
| Room depth | W / S or Up / Down |
| Sprint | Hold Shift |
| Crouch / quiet movement | Hold Ctrl |
| Interact / enter or leave hiding | E |
| Flashlight after pickup | F |
| Pause / resume | Esc |
| Close letter | E, Esc or Close button |

## Degree of Freedom

Freedom is exchanged, not simply gained:

- **Deprived:** noise and light are safe; the monster is dormant.
- **Hearing:** the first key enables investigation of footsteps and puzzle noise. Sprinting and debris/water become dangerous; crouching and carpet remain quieter.
- **Sight:** the second key enables deterministic range, field-of-view and occlusion checks. Darkness and crouching reduce visibility; flashlight use increases risk.
- **Memory:** the final key enables bounded records of observed hiding entrances and recent visible movement. Repeated hiding and routes become less reliable.

Three short E interactions release each puzzle seal. Collect its nearby gold key separately. No final animation or audio is required for these mechanics.

## Endings

- **Full Awakening:** restore all three senses and interact with the front door near the ground-floor start. The basement service passage returns to the ground-floor far end.
- **Partial Mercy:** restore exactly Hearing and Sight, then use the maintenance exit near the basement entrance before taking Memory.
- **Vantree:** collect the three ground-floor letters with at most one restored sense, then use the custodian seal near the Pantry.

Death fades into the latest runtime checkpoint. Checkpoints are taken on room entry and sense collection. Restart checkpoint and New game are separate pause-menu actions.

## Development and release

- [Implementation report](docs/IMPLEMENTATION_REPORT.md)
- [Asset integration contract](docs/ASSET_INTEGRATION.md)
- [Testing procedure and manual QA](docs/QA.md)
- [Known limitations](KNOWN_ISSUES.md)
- [Asset credits](ASSET_CREDITS.md)
- [AI disclosure](AI_DISCLOSURE.md)

Windows Desktop and single-threaded Web export presets are supplied. Install matching Godot 4.7.2 export templates before exporting. The layout JSON is explicitly included. Exports and caches are ignored by Git. No export binaries are included. Character assets are under `ifat/female` and `zombie`.
