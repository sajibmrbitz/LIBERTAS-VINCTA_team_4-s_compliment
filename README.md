# LIBERTAS VINCTA

**Team:** 4's Compliment

**Theme:** Degree of Freedom

**Engine:** Godot 4.7 stable

LIBERTAS VINCTA is a 2D psychological survival-horror game set in Hollowmere Estate and the Sunken Cathedral beneath it. Els Vantree restores senses to the Deprived One by taking sealed keys. Every restored sense changes its behavior, and taking all three keys creates a false escape that loops the house instead of winning.

The game contains the complete Part I estate route, the Part II Cathedral Roots, Chamber of Echoes, and Ley-Nexus, six successful endings across both parts, and the three-key Loop failure state.

## Run

1. Import `project.godot` in Godot 4.7 stable.
2. Wait for PNG and audio imports to finish.
3. Press F5.

Use F5 rather than running an individual floor scene. `Main` supplies Els, the Deprived One, HUD, audio director, checkpoints, and transition presentation.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD or arrow keys |
| Sprint | Shift |
| Crouch | Ctrl |
| Interact, leave hiding, channel | E |
| Flashlight | F |
| Hold breath | B |
| Use gadget | Q |
| Blood or partial sigil | R |
| Stun Rite | T |
| Pause | Esc |

The flashlight has 90 seconds of charge and drains three times faster while sprinting. Recharge stations take 12 stationary seconds. Breath can be held for 6 seconds and has a 15-second cooldown. Batteries, bottles, clocks, and lockpicks are persistent checkpoint inventory.

## Part I

The room graph uses the literal IDs `GF-01` through `GF-10`, `UF-01` through `UF-07`, and `BS-01` through `BS-09`. Hearing, Sight, and Memory activate successively stronger enemy behavior.

| Keys | Exit | Result |
| --- | --- | --- |
| 0 | Front door, after testing it once, with zero detections | Untouched |
| 1 | `BS-09` Ritual Conduit with at least 4 of 7 estate letters | Vantree |
| 2 | `BS-04` Flood Tunnel | Partial Mercy |
| 3 | Front door | Loop; keys and entity reset, no Part II seed |

The second completed Loop unlocks `vantree_memory_fragment_A`. The valid Part I endings produce distinct Part II seeds. Vantree gives the monster Touch, Els Blood Magic, and an 80% HP cap. Partial Mercy preserves two monster senses and gives Els partial sigils. Untouched preserves a full gadget kit and leaves all monster senses dormant.

## Part II

Part II spans six Cathedral Roots rooms (`CR`), five Chamber of Echoes rooms (`CE`), and the single-screen Ley-Nexus (`LN-CENTER`). It includes letters VIII through XIII, flooded and rubble surfaces, four crypt hiding alcoves, the name-carving reveal, branch mechanics, and a three-use skill gate.

At the Nexus, all three anchors are visible together. Holding E for 20 uninterrupted seconds chooses an ending; detection or damage resets the channel:

- `LN-A`: Severance
- `LN-B`: Custodian's Rest
- `LN-C`: Vessel

## Architecture

- `data/estate_layout.json`: room IDs, floor regions, surfaces, props, exits, requirements, items, and anchor choices.
- `data/estate_art.json`: atlas slices, imported furniture dressing, cathedral props, scale, tint, and collision footprints.
- `scripts/core/freedom_ledger.gd`: save schema, inventory, endings, loops, Part II seeds, HP, charge, and progression.
- `scripts/enemy/deprived_one.gd`: the nine-state sensory AI.
- `scripts/interactables/base_interactable.gd`: pickups, puzzles, hiding, doors, vents, recharging, forge, exits, and anchors.

## Verification

The maintained Godot tests cover layout/art, systems, and the canonical route:

```powershell
godot --headless --path . tests/verify_estate_assets.tscn
godot --headless --path . tests/verify_game_systems.tscn
godot --headless --path . tests/verify_game_route.tscn
```

Current results: 662 asset/layout checks, 48 systems checks, and 92 route checks, all with zero failures. The route test covers Awakening, Vantree Part I, Part II, the Echo skill gate, Severance, and the false-exit Loop reset.

See [QA](docs/QA.md), [asset credits](ASSET_CREDITS.md), and [AI disclosure](AI_DISCLOSURE.md).
