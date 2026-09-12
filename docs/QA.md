# Testing procedure

## Environment integration validation - 2026-09-12

The supplied estate props and piano were tested with the locally installed
Godot 4.7 stable engine. `tests/verify_estate_assets.tscn` passed 751 headless checks
with zero failures. Rendered runs at 1280x720 and 960x600 passed 814 checks and capture
check twenty-one room, open-door and flashlight views per resolution. Visual review
included the carried flashlight and floor beam, pickup visibility, angled benches,
the piano key, door/window separation, floor coverage and stealth lanes.

Checks cover all 45 catalog textures, collision/navigation integration,
unobstructed E approaches to every interaction, hiding entry/exit, all three
seal/key sequences, checkpoint ledger restoration, room reloads and the greybox
override. A separate 67-check runtime route test also passed: foyer requirements,
all floor transitions and return routes, open/close completion, exact arrival
placement, three senses and Full Awakening.
Tests freeze enemies while inspecting interactions; they are not an exhaustive
ending playthrough or enemy-behavior regression suite. Export binaries were
not built. The sandbox emitted a system certificate-store error at startup;
there were no game script or asset-loading errors in the successful runs.

See [environment assets](ENVIRONMENT_ASSETS.md) for commands and remaining art slots.

## Editor smoke test

1. Open `project.godot` with Godot **4.7.2 stable** and wait for imports.
2. Press **F5**. Main should start with a black frame, silent-safe audio hooks and a slow fade.
3. Confirm movement is locked until Els rises after “...Where am I?”.
4. Use A/D and W/S (or arrows); confirm horizontal movement is faster than depth movement, diagonals do not gain speed and there is no jumping.
5. Approach the flashlight around x=430 and tool kit around x=900. E collects each once.
6. Approach the foyer door around x=1590. First E gives “Locked.” / “Of course.”. With both pickups, another E opens it after a brief lockpick beat and “Hello?”.
7. Ground floor: use E three times on the Music Room piano seal around x=1800, then collect the marked gold Hearing Key at (1960, 525), beside the piano. The end stairs are offscreen at the start.
8. Sprint over the debris after the key, then compare crouching on the lower carpet lane. The zombie should investigate loud noise.
9. Use the upper-floor stairs around x=6980. Complete the vanity near x=2150, then collect Sight at x=2370.
10. Compare crossing moonlight with the flashlight on versus crouching in the lower shadow lane. Furniture should block vision.
11. Use E at a folding hiding screen, then E to leave. Unseen entry is reliable. Entering directly in view is unsafe. The greybox override uses blue silhouettes instead.
12. Enter the basement. For Partial Mercy, use the maintenance exit near x=620 while holding exactly two keys.
13. For the full route, continue through water/quiet bypass choices. Complete the ritual near x=4090 and collect Memory at x=4310. Let the monster observe a hiding entrance, escape, and watch its bounded re-check/predicted search.
14. Use the far service return near x=6890, then return left along the ground floor and use the front door at x=180 for Full Awakening.
15. In a new run, collect the ground letters at x=600, 3650 and 5480 while holding zero or one key, then use the custodian seal at x=5900 for Vantree.
16. Let the monster catch Els. Expect a short fade and restart at room-entry or sense-key checkpoint with the saved senses/letters/flags restored.
17. Esc: test Resume, sliders, fullscreen, Restart checkpoint and New game. Reading letters must freeze the enemy. New game must clear all ledger progress.

Use the Remote scene tree to inspect generated level nodes. Enable `debug_detection` on the enemy scene or `debug_noise` on a floor scene for development. They default to false.

## Previous automated validation

The temporary test scripts, screenshots and logs were removed during cleanup. The checks recorded in the implementation report were run before removal. Use the editor procedure above and the manual checklist below for ongoing testing.

## Manual release checklist

- [ ] Complete every ending without debug teleporting or freezing the enemy.
- [ ] Measure a first successful run; tune toward 8–15 minutes.
- [ ] Confirm every progression prop is discoverable with the subtle E prompt.
- [ ] Test movement/camera at 30, 60 and high rendering frame rates.
- [ ] Check all four boundaries and furniture from both room-depth directions.
- [ ] Verify sprint/water/glass are noticeably riskier than crouch/carpet after Hearing.
- [ ] Verify walls block sight, darkness helps and light increases risk after Sight.
- [ ] Verify unseen hiding remains useful after Memory and observed reuse has consequences.
- [ ] Pause/resume during Awakening, puzzles and door beats; no control lock should persist.
- [ ] Read/close every letter and test duplicate pickups.
- [ ] Die after each key; verify restart and full New game independently.
- [ ] Verify UI at 1280×720, 16:10 and fullscreen; keyboard and mouse menu navigation.
- [ ] Assign and listen to all audio; verify silent slots, bus sliders and tension changes.
- [ ] Review credits, AI disclosure and final narrative.
- [ ] Export and play Windows and Web builds with the layout JSON included.

Automated results and environment limitations are recorded in the implementation report. Team release playtesting remains required.

## Character integration checks

- On F5, Els should display the female sprite during Awakening and after gaining control.
- Move in all eight directions, sprint, stop and crouch; no character placeholder should appear.
- Collect tools/keys, use a puzzle or door, and toggle the flashlight to check action clips.
- After the intro, find the dormant zombie; restore Hearing to check walking and investigation.
- Restore Sight and trigger a chase to check running. Capture should play zombie attack and
  Els death before the existing checkpoint restart. Also check capture from a remembered hiding spot.
- Check feet against collision and floor props, pause/resume, and room/checkpoint reloads.

Static validation of the integrated resources passed: 80 female clips (960 frames) and
32 zombie clips (640 frames), with all source files present, atlas regions within sheet
bounds and nonempty alpha in every referenced cell. Godot runtime and visual playtesting
were not run in the integration environment because no Godot executable was found.
