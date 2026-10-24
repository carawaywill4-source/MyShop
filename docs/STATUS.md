# Status

Last updated: 2026-10-23 (visual foundation phase 2)

## Working now

- One-bay workshop scene (`scenes/workshop/workshop_bay.tscn`) at real scale (10 × 11.9 × 4.2 m). It has a PBR floor and walls (CC0 Poly Haven textures), overhead fluorescent fixtures, one shadowed key light, a reflection probe, a bench with vice, tools and pegboard, parts shelving, tyres, drums, a tool chest and cart, floor markings, and a clean sectional door.
- A real two-post lift (`scenes/equipment/two_post_lift.tscn`): red C-channel columns, overhead beam, carriages, telescoping swing arms, screw pads, hydraulic line and power unit. The lift raises the car for Bay and Under car views and lowers it for Engine work.
- The Harbor Commute (`scenes/vehicles/harbor_commute.tscn`) is an original fictional compact sedan at real dimensions. Lofted body with wheel arches, shoulder line, greenhouse, door seams, a hood that actually opens on a cowl hinge, lights, mirrors, interior, alloy rims with brake discs, and an underbody with exhaust, tank, subframe and springs.
- Engine bay: transverse inline-4, radiator, battery and tray, air box and intake, coolant, brake and washer reservoirs, strut towers, firewall, hoses, battery cables, wiring loom.
- Separately addressable components (`scenes/vehicles/components/`), each with RepairableComponent data: oil filter, drain plug, oil fill cap, dipstick, engine, radiator, battery, air intake, reservoirs.
- Oil drain caddy that rolls under the car when the drain pan is placed. A ghost funnel marks where to tap.
- The same vehicle instance is used in all three views.
- The oil-change job, tools, wrong-tool messages, $750 start, $55 charge and $23.50 parts/supplies are unchanged.

## Limitations (honest list)

- **The engine is one combined mesh** (Grab3D CC0). The block, head, valve cover, intake manifold, oil pan, alternator, belt and pulleys are baked together and cannot be removed separately. The removable oil filter, drain plug, fill cap and dipstick are separate parts fitted onto the engine model's own filter boss, fill neck and dipstick tube. An alternator job needs a separately modelled alternator, belt, tensioner and bracket.
- The engine model is clean but slightly toy-like (salmon valve cover, simplified detail). It is the weakest realism link for a learning product. Replace it with a properly modelled I4 with separate parts before any engine repair beyond fluids.
- The car body is authored procedurally. Proportions are real, but surfacing is simpler than a hand-modelled car: soft nose, no panel gaps beyond door seams, no detailed grille. An artist should replace `Body/Shell` and `Body/HoodPivot/Hood/HoodPanel` meshes; the node layout is ready for that.
- Underbody detail is light: no brake lines, CV boots, or heat shields yet.
- No iPhone export or test. Touch has only been tested by ray-casting from the gameplay cameras on this Mac.
- No save/load, diagnostics, employees, or extra vehicles.

## Tests run on this Mac (2026-10-23)

- Headless editor import: no errors or missing resources.
- `scripts/dev/smoke_test.gd`: full oil change passes, including wrong-tool feedback, $31.50 net, and $781.50 final cash.
- `scripts/dev/tap_test.gd`: drain pan spot, drain plug and oil filter are tappable from Under car; hood, fill cap and dipstick from Engine. All passed. This test found and fixed a bug where the hidden drain-pan ghost blocked taps.
- `scripts/dev/capture_views.gd`: rendered Bay, Under car, Engine, caddy placed, and hood open. Screenshots are in `docs/screenshots/`.
- Not tested: an iPhone build, real touch hardware, frame rate on a phone.
