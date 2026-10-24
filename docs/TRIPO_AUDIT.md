# Tripo asset audit

Inspected 2026-10-23. No new Tripo generations. Blender is not installed. Branded Downloads models were not imported.

This note records the inspection the user asked for in the pipeline brief: "Create an audit report and a backup before changing the implementation." It does not replace `docs/ASSET_REGISTER.md`. Nothing else links to it yet.

## What is actually separate

| Asset | Nodes / meshes | Tris | What can move |
| --- | --- | --- | --- |
| `assets/models/tripo/kessler_gt6_tripo.glb` | 66 / 65 | ~195k | Generate-in-Parts shells named `tripo_part_N`. No pivots. |
| `scenes/vehicles/kessler_gt6.tscn` | authored from that GLB | — | Hood hinge and four wheels are separate. Paint_20, Paint_30, Paint_24, and Paint_17 are single side panels and are now hinged as doors. Trunk is fused into the body shells. No interior. |
| `assets/models/tripo/kaito_sprint.glb` | 76 / 75 | ~192k | Segmented parts, no door or hood pivots in the roster scene. Not articulated in this pass. |
| `assets/models/authored/blender_source/harbor_commute.glb` | Godot export | ~102k | Hood, seats, dashboard, steering wheel, and oil-change parts are separate. Doors are one shell. |
| Downloads Hellcat, GT3 RS, BMW SUV, `kessler_gt6_m340.glb` | 1 / 1 each | ~1.9M | One fused mesh each. Not used. |

A part name is not proof it can open. The Kessler trunk and the Harbor doors stay closed because their geometry is not a separate panel.

## License

Tripo commercial use is not confirmed for this account. The Kessler grille still resembles a real badge and must be redesigned before any release. The removed emblem stays out. Kenney, Grab3D, and Poly Haven rows in `docs/ASSET_REGISTER.md` remain CC0.

## Harbor milestone, 2026-10-23

The Harbor body was one loft, not a Tripo mesh. Blender is still not installed. The door skins and side glass were cut out of that loft and hinged at the forward shut line. The trunk is still the tail of the shell. Source files before this cut are in `backups/pre-harbor-cabin-2026-10-23/`. The earlier prototype backup was left in place.

Checked in Godot, not only by reading the scripts:

- Cabin view sits at the driver eye. The frame shows the steering wheel, dashboard, and instrument cluster. The shop wall is visible through the side glass. The seat is behind that eye point, and the OBD-II port is a separate mesh under the dash, not a prominent object in this framing.
- The driver door swings on its own pivot. Bay view with the door open shows the opening. Kessler's four separated panels still swing.
- The check-engine lamp follows the fault list. A failed cylinder-1 coil stores P0301. Clear says the code came back and leaves the fault in place. Replacing the coil removes the fault, and the next scan reports no codes and the lamp is off.
- Hood, under-car, and engine views still show the same Harbor. The oil-change smoke test still ends at $781.50.
- No iPhone build was run.

Still simple: the cluster is a panel with two gauge lenses, the console is a shaped block, and the door shut lines are not tight. Do not treat that as a finished interior, and do not generate the other nine cars yet.
