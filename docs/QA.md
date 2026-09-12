# Quality assurance

## Automated verification

Validated with Godot 4.7 stable on 2026-09-13.

| Suite | Coverage | Result |
| --- | --- | --- |
| `tests/verify_estate_assets.tscn` | 7 zones, 37 room regions, 56 texture entries, every progression prop, doors, pickup markers, paths, hiding priorities, recharge coverage, and simultaneous Nexus anchor framing | 662 checks, 0 failures |
| `tests/verify_game_systems.tscn` | Input map, all Part II seeds, movement and battery tunables, noise radii, nine enemy states, hearing escalation, sight confirmation, Memory pursuit, Blood/partial magic costs, stun, and interrupted channel reset | 48 checks, 0 failures |
| `tests/verify_game_route.tscn` | Awakening, Hearing key, four-letter Vantree gate, all floor transitions, Part II seed, Roots, Echoes, three mechanic uses, Nexus, Severance, and two Loop resets | 92 checks, 0 failures |

Use these commands from the project directory:

```powershell
& "E:\New folder\Godot_v4.7-stable_win64_console.exe" --headless --path . tests/verify_estate_assets.tscn
& "E:\New folder\Godot_v4.7-stable_win64_console.exe" --headless --path . tests/verify_game_systems.tscn
& "E:\New folder\Godot_v4.7-stable_win64_console.exe" --headless --path . tests/verify_game_route.tscn
```

The restricted test sandbox can report an OS root-certificate-store warning. It is outside the game and does not affect test exit status. Runtime script and asset-loading errors are treated as failures.

## Visual verification

Roots, Echoes, and Nexus were rendered at 1280x720 with the OpenGL compatibility renderer. The generated props retain transparency, altar and forge interactions are unobstructed, the player remains visible, the cathedral wall fills the frame, and all three Nexus anchors are simultaneously visible. The center floor seal is sorted behind the center anchor.

## Manual release checklist

- [ ] Complete Untouched, Vantree, and Partial Mercy without debug movement.
- [ ] Complete Severance, Custodian's Rest, and Vessel from their intended Part II seeds.
- [ ] Trigger the three-key front-door Loop twice and confirm memory fragment A.
- [ ] Confirm enemy catches restore the latest transition or key checkpoint.
- [ ] Test vents before and after Stage 3.
- [ ] Test 90-second charge, sprint drain, all three recharge stations, and battery use.
- [ ] Test bottles, clocks, pantry pots, dining false noise, and the crouch-safe Trophy Hall floor.
- [ ] Test hiding-priority growth after repeated use.
- [ ] Test Touch transmission on stone, rubble, and the elevated Choir lane.
- [ ] Test Blood Sigil, Stun Rite, and Partial Sigil HP/cooldown limits.
- [ ] Interrupt each Nexus anchor with both detection and damage.
- [ ] Check HUD and modal layout at 1280x720, 960x600, and fullscreen.
- [ ] Confirm Continue restores zone, position, ledger, inventory, health, and Part II seed.
- [ ] Review third-party license details before public distribution.
