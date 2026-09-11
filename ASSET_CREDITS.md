# Asset credits

No external art, music, fonts or sound effects were added during framework implementation. Environment geometry remains generated placeholder content; UI uses a project-authored native Godot Theme with system-font placeholders (Georgia/Times New Roman and Segoe UI/Arial, with engine fallback); no font files are bundled. Character and footstep integration now uses the supplied assets listed below.

The existing `icon.svg` came with the repository. Confirm its provenance and release suitability before using it as the final game icon.

Add a row for every third-party asset before release. Keep original license files alongside the imported assets where required.

| Asset / file path | Creator | Original source URL | License / version | Modifications | Required credit text |
| --- | --- | --- | --- | --- | --- |
| `assets/sprites/player/*.png` | AI-generated; supplied by project owner | See `assets/sprites/player/prompts.json` and README | See supplied asset provenance | Godot atlas regions, animation mapping and scene scaling; original PNGs unchanged | See supplied provenance |
| `assets/sprites/zombie/Skin2_x256_Spritesheets/` | Not identified in supplied folder | Supplied by project owner | Not supplied | Godot atlas regions, animation mapping and scene scaling; original PNGs unchanged | Not supplied |

| `assets/audio/Footsteps/Antons_Footsteps_FS_Wood_Walk_01.wav` through `_07.wav` | Not identified; filename prefix is Antons_Footsteps | Supplied by project owner | Not supplied in folder | Playback cadence, gain and restrained pitch variation; original WAVs unchanged | Team to confirm license and required attribution |

Do not list planned assets as installed. Team-created final assets should be identified separately with their creator's preferred credit.
