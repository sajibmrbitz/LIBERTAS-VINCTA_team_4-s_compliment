# Female animation sheets

Open `../../../index.html` and choose Female adventurer. Existing actions only:
Idle, Walk, Run, Interact, Unlock/open door, Pick up key, Use flashlight,
Take damage, Stagger, Death.

Each action is a transparent PNG, 3072 x 2048 pixels: **12 columns x 8 rows**,
with 256 x 256 cells. Frames run left to right. Direction rows are South,
Southwest, West, Northwest, North, Northeast, East, Southeast.
Ground contact is y=224; nominal root x=128. No runtime auto-cropping or scaling
per pose. The preview defaults to 12 FPS; only Idle, Walk and Run loop by default.
Changing direction preserves the current frame and paused/playing state.

Idle deliberately contains twelve identical held poses in each direction.
This eliminates idle jitter in both the preview and exported assets; it is not
a twelve-pose breathing animation. Right-facing directions mirror matching
left-facing art, including the asymmetric satchel. Generated poses can retain
small drawing/proportion differences; these are raster animation assets, not
skeletal animation or motion-captured LPC retargeting.

The built-in image generation tool produced the source art using the original
female character image for identity and the supplied LPC archive for movement
reference. `prompts.json` records the generation prompts. The LPC sample is
reference only and contributes no additional actions to the preview.

Rebuild in Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "female character/generated/smooth/build.ps1"
```

The build removes magenta backgrounds, detects actual pose boundaries, checks
for exactly twelve poses in eight rows, applies a common scale per action,
anchors each pose, and exports the sheets. It rejects missing rows, missing
poses and clipping. Raw generation results stay in `source/` for refinement.
Death's source contains eleven poses; its twelfth exported frame holds the
settled final pose. This preserves the fall sequence without skipping poses.
The older draft files and stable build are retained but are no longer loaded.

Verification: run `verify-assets.ps1` with Windows PowerShell and
`node "female character/generated/smooth/verify-preview.cjs"` from the project
root. These check all 960 cells, alpha and clipping, identical idle pixels,
frame selection, direction continuity, looping, final-pose hold, and the
original-character selector. The player test uses a minimal DOM, not a browser.
