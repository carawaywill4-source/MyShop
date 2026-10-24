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
