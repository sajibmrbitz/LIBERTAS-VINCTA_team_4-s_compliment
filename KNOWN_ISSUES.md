# Known limitations

- This is a non-asset greybox. Final character/environment art, animations, music, sound effects, theme/icons and narrative copy are not installed.
- The 8–15 minute first-run target is not measured. Traversal, puzzle timing, detection, hiding placement and return-route pacing need a human balance pass.
- Ground, upper and basement are compact horizontal room groups connected by instantaneous stair/door transitions. No streamed mansion, vertical stair animation or seamless camera transition is implemented.
- The old `hearing_test_level.tscn` is retained unchanged as a historical platformer-corridor reference. Main now uses the elevated room-plane scenes; the old level is not a supported test of the updated Player.
- Crouching changes visual posture, speed, noise and detection. The foot collision footprint remains constant; this is room-plane stealth, not a crawl-under platformer.
- Hiding prop silhouettes are non-solid interaction scenery. Furniture and room boundaries have physical collision and block vision.
- Enemy movement uses a small static AStar grid. Moving collision geometry dynamically would require rebuilding the grid. Memory records only observed behavior, is limited to a room instance, and clears on scene reload/checkpoint restart.
- Puzzle seals use three short timed E interactions, without note-sequence, inventory-combination or precision-lock minigames.
- Checkpoints and settings last for the current process only. No disk save or settings persistence is implemented.
- Pause provides Quit and New game rather than a separate title/menu scene. Browser hosting controls whether window close/fullscreen is allowed.
- All three endings execute, but their brief text is provisional. No final cinematics are supplied.
- The temporary automated progression suite (removed after validation) called many interaction methods directly and temporarily freezes enemies to isolate state behavior. It also checked the real E pickup path. The separate movement suite drove live enemy navigation. Neither substitutes for an uninterrupted human stealth playthrough.
- Windows/Web export presets exist, but no matching export templates were found in the standard local template directory. Export binaries and browser play were not verified.
- The restricted validation environment reports a Windows root-certificate-store error. Earlier editor/render runs also reported inaccessible per-user settings/log/shader-cache paths. No gameplay/parser errors occurred in the passing suites. The game itself has no network dependency.

No enemy combat, procedural mansion, complex inventory/save system, sequel content or final-asset claims are included.
