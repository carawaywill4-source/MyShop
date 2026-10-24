# Technical decisions

- Engine for this prototype: Godot 4.7.2 (free, official macOS build). Unreal Engine 5 stays the intended later production engine if hardware allows. This was approved after the audit.
- Why Godot now: 8 GB RAM and a 256 GB disk cannot host Unreal plus an iOS project. Godot installed in about 160 MB and runs on this Air.
- Renderer: Godot mobile renderer from day one.
- Vehicles: fictional Harbor Commute. The Tripo files in Downloads (`ccs_hellcat.glb`, `ccs_gt3rs.glb`, `bmw+suv+3d+model.glb`) are branded cars and stay out of the project.
- Economy: JSON cents, not hardcoded dollars in gameplay code.
- Specs: 5 quarts is labeled as a game quantity. No torque spec is presented as real.
- Online services: none required for play.
- Visual upgrade phase 1 keeps gameplay in `scripts/main.gd` and builds visuals in `scripts/visuals/`.
- Vehicle and engine visuals use CC0 models: Kenney Car Kit sedan and Grab3D engine, radiator, and battery. See `docs/ASSET_REGISTER.md`. The workshop is still original geometry.
- Engine and under views lift the body shell so the motor is visible. The hood tap still works. The game still requires the hood to be opened before filling oil.

## 2026-10-23 — Visual foundation phase 2

- The visual world is now saved scenes (`scenes/workshop`, `scenes/vehicles`, `scenes/equipment`) instead of runtime box builders. The old `scripts/visuals/*` builders were removed; copies are in `backups/pre-foundation-phase2/`.
- Original meshes are authored by scripts in `scripts/authoring/` and baked by `scripts/dev/build_foundation.gd`. Blender was not installed, so meshes are generated in Godot and exported to glTF (`assets/models/authored/blender_source/`) for future Blender work.
- The Kenney toy sedan was replaced by the authored Harbor Commute at real dimensions, because no CC0 realistic car was available and branded models are off-limits.
- Workshop props and textures come from Poly Haven (CC0), downloaded at 1k to stay light on an 8 GB Mac and on phones. Textures are VRAM-compressed with mipmaps.
- The lift is lowered for Engine view and raised for Bay and Under car views, and stays up while oil drains. The car is parented to the vehicle anchor and moved by the lift, so all views share one vehicle.
- Gameplay change, kept minimal: `main.gd` now calls `world.set_drain_pan_placed()` when the pan is placed or the job restarts, so the caddy visibly moves. No rules or prices changed.
- Product direction: learning-first stylized realism, and fictional vehicles that are mechanically true to real archetypes. See `PRODUCT_VISION.md`.
