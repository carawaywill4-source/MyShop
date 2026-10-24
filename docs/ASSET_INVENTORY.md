# Asset inventory, 2026-10-23

This is the inspection the pipeline brief asked for: "Produce an asset inventory containing the actual file path, format, file size, texture availability, and whether it contains separate meshes or parts." It does not replace `docs/ASSET_REGISTER.md`. Nothing else links here yet.

The car in the oil-change game is not a Tripo model. `scenes/vehicles/harbor_commute.tscn` draws `assets/models/authored/harbor_commute_body.res`, which `scripts/authoring/vehicle_author.gd` builds as a loft. The cabin pieces added later are the same kind of generated shapes. That scene was not changed in this pass. The oil-change game still loads it.

Blender is not installed. It was not installed for this pass.

## What is on screen in `captures/visual`

`scripts/dev/visual_prototype.gd` loads the GLB files below with their own materials and one uniform scale (0.981 m source length to about 4.45 m). No new body was modeled.

| File | Generator | Size | Meshes | Images | What it actually is |
| --- | --- | --- | --- | --- | --- |
| `assets/models/tripo/kaito_sprint.glb` | Tripo 2.0 | 13 MB | 75, all named `tripo_part_N` | 225 | Textured compact sedan. Honda badge on the nose and tail. Paint has pink torn patches. Glass is opaque. No dashboard, wheel, or seats. Hood is shut. |
| `assets/models/tripo/kessler_gt6_tripo.glb` | Tripo 2.0 | 4.6 MB | 65 `tripo_part_N` | 0 | Untextured white sedan. The grille is the four-ring shape. No textures to recover. |
| `assets/models/tripo/engine_i6_tripo_parts.glb` | Tripo 2.0 | 4.4 MB | 76 | 0 | Engine parts only. Not a car. |
| `Downloads/kessler_gt6_m340.glb` | Tripo 2.0 | 59 MB | 1 | 3 | One fused mesh, about 1.93 million triangles. Not imported. |
| `Downloads/ccs_hellcat.glb` | Tripo 2.0 | 60 MB | 1 | 3 | One fused mesh, about 1.92 million triangles. Not imported. |
| `Downloads/ccs_gt3rs.glb` | Tripo 2.0 | 62 MB | 1 | 3 | One fused mesh, about 1.98 million triangles. Not imported. |
| `Downloads/bmw+suv+3d+model.glb` | Tripo 2.0 | 59 MB | 1 | 3 | One fused mesh, about 1.87 million triangles. Not imported. |

Searched for `.glb`, `.gltf`, `.fbx`, and `.obj` in the project, Downloads, Desktop, and Documents. No other car exports. Desktop and Documents had none.

## Reference actually opened

Honda City side/rear photo, KuwarOnline, CC BY-SA 3.0: https://commons.wikimedia.org/wiki/File:Honda_City_2012_Side_View.JPG

Used only to judge a real sedan’s wheel placement, glass, and shut lines. It was not traced or textured onto a mesh. No licensed cockpit photo and no open-engine photo were opened, so those views are not claimed to match a reference.

## Not accepted as the template

Kaito is a real mesh and it looks more like a car than the procedural Harbor. It is also a badged Honda-like model with broken paint, a closed hood, and no interior. The parts are not named doors. Kessler’s raw export is an untextured badge-like sedan. Neither one should be copied into the other nine cars.
