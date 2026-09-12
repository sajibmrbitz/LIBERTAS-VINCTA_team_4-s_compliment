# Asset credits

Environment dressing now uses the supplied Food & Drink 2D Mega Props Pack and piano sheet. Physics geometry remains generated independently of artwork. UI uses a project-authored native Godot Theme with system-font placeholders (Georgia/Times New Roman and Segoe UI/Arial, with engine fallback); no font files are bundled. Character and footstep integration uses the supplied assets listed below.

The existing `icon.svg` came with the repository. Confirm its provenance and release suitability before using it as the final game icon.

Add a row for every third-party asset before release. Keep original license files alongside the imported assets where required.

| Asset / file path | Creator | Original source URL | License / version | Modifications | Required credit text |
| --- | --- | --- | --- | --- | --- |
| `assets/environment/props/food_drink_2d_mega_props/Tiles/` | nacl1234; pack README discloses AI-assisted artwork | Food & Drink 2D Mega Props Pack v1.0, supplied by project owner; source URL not supplied | Supplied commercial license, retained at `assets/environment/props/food_drink_2d_mega_props/LICENSE.txt` | Selection of 39 PNGs for estate dressing; Godot atlas regions, scaling and tint; source files unchanged | No specific credit wording required in supplied license; original copyright is 2026 nacl1234 |
| `assets/environment/props/music_room/piano1.png` | Not identified in supplied image | Supplied by project owner | Not supplied | Godot atlas region selects grand piano and bench; source PNG unchanged | Team to confirm provenance and required attribution |
| `assets/environment/props/estate_essentials/estate_essentials.png` | OpenAI image generation, generated for this project on 2026-09-12 | Built-in imagegen; prompt and provenance in adjacent README | Generated output, not part of the commercial props pack | Six cached Godot atlas regions with transparent-margin trimming; source PNG unchanged | AI provenance recorded; no third-party attribution supplied |
| `assets/environment/props/cathedral/cathedral_props.png` | OpenAI image generation, generated for this project on 2026-09-13 | Built-in imagegen; prompt and provenance in adjacent README | Generated output | Six atlas slices with transparent-margin trimming | AI provenance recorded; no third-party attribution supplied |
| `assets/environment/props/cathedral/survival_pickups.png` | OpenAI image generation, generated for this project on 2026-09-13 | Built-in imagegen; prompt and provenance in adjacent README | Generated output | Four atlas slices with transparent-margin trimming | AI provenance recorded; no third-party attribution supplied |
| `assets/sprites/player/*.png` | AI-generated; supplied by project owner | See `assets/sprites/player/prompts.json` and README | See supplied asset provenance | Godot atlas regions, animation mapping and scene scaling; original PNGs unchanged | See supplied provenance |
| `assets/sprites/zombie/Skin2_x256_Spritesheets/` | Not identified in supplied folder | Supplied by project owner | Not supplied | Godot atlas regions, animation mapping and scene scaling; original PNGs unchanged | Not supplied |

| `assets/audio/Footsteps/Antons_Footsteps_FS_Wood_Walk_01.wav` through `_07.wav` | Not identified; filename prefix is Antons_Footsteps | Supplied by project owner | Not supplied in folder | Playback cadence, gain and restrained pitch variation; original WAVs unchanged | Team to confirm license and required attribution |

Do not list planned assets as installed. Team-created final assets should be identified separately with their creator's preferred credit.

The props pack license permits use in games and distribution embedded in an end
product; it does not permit distributing the standalone source assets. The local
integration does not publish or redistribute the pack.
