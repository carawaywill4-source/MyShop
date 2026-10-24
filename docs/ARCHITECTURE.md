# Architecture

How the 3D foundation is put together, and where to extend it.

## Layers

| Concern | Lives in | Notes |
| --- | --- | --- |
| Job rules, tools, economy | `scripts/main.gd`, `data/*.json` | Unchanged gameplay. It talks to the world only through the API in `shop_world.gd`. |
| World glue | `scripts/shop_world.gd` | Loads the workshop and vehicle scenes, collects Interactables, maps job state onto visuals (lift height, hood, caddy, oil stream). |
| Camera and views | `scripts/camera/shop_camera.gd` | `VIEWS` presets for `bay`, `under`, `engine`, framed for the landscape HUD. |
| Vehicle identity | `scripts/vehicles/vehicle.gd` on `scenes/vehicles/harbor_commute.tscn` | `vehicle_id`, `family`, `engine_layout`, `drivetrain`, hood animation, and a `components` lookup. |
| Repairable parts | `scripts/components/repairable_component.gd` on `scenes/vehicles/components/*.tscn` | `component_id`, `required_tool`, `access_view`, `condition`, `state`, `removable`, `separate_mesh`. |
| Tap targets | `scripts/interactable.gd` | A StaticBody3D with a `part_id`. Colliders are larger than the visible part so they are easy to hit with a finger. |
| Equipment | `scripts/equipment/two_post_lift.gd`, `oil_drain_caddy.gd` | The lift carries the attached vehicle, so the same car is used in every view. |
| Visual authoring | `scripts/authoring/*.gd`, `scripts/dev/build_foundation.gd` | Generates the meshes, materials and scenes. Not used at runtime. |

## Scene tree at runtime

```
Main (main.gd)
└ WorldRoot
  └ ShopWorld (shop_world.gd)
    ├ WorkshopBay (scenes/workshop/workshop_bay.tscn)
    │ ├ WorldEnvironment, Room, Lighting (key light, fixtures, reflection probe)
    │ ├ Equipment: TwoPostLift, OilDrainCaddy, DrainPanSpot
    │ ├ WorkbenchArea, PartsStorage, FloorClutter (Poly Haven props)
    │ └ VehicleAnchor
    │   └ HarborCommute (scenes/vehicles/harbor_commute.tscn)
    │     ├ Body: Shell, Greenhouse, HoodPivot/Hood, Lights and trim
    │     ├ Wheels: FrontLeft, FrontRight, RearLeft, RearRight
    │     ├ Interior, Underbody
    │     └ EngineBay: structure, HosesAndWiring, Components/
    │         Engine, Radiator, Battery, AirIntake, CoolantReservoir,
    │         BrakeFluidReservoir, WasherReservoir, OilFilter, DrainPlug,
    │         OilFillCap, Dipstick
    └ ShopCamera
```

## Vehicle space

+Z is forward, +X is the car's left, Y=0 is the ground. Real dimensions: 4.50 m long, 1.78 m wide, 1.45 m tall, 2.65 m wheelbase, 0.65 m tyres. Lift pads touch the pinch welds at `lift_point_height` (0.19 m). Lift heights are 0.19 m (lowered, for engine work) and 1.42 m (raised, for under-car work).

## Rebuilding the visuals

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/dev/build_foundation.gd
```

This overwrites `assets/materials/`, `assets/models/authored/`, and the scenes under `scenes/vehicles`, `scenes/equipment` and `scenes/workshop`. Once someone hand-edits one of those scenes in the Godot editor, either stop rebuilding it or move that change into the authoring script.

## Adding a repairable component

1. Add a builder to `scripts/authoring/component_author.gd`. Use `_component(...)` for the RepairableComponent root and `_pickable(...)` if the player taps it.
2. Place it in `_assemble_vehicle()` in `build_foundation.gd`, under `EngineBay/Components` or `Underbody`.
3. Rebuild. `shop_world.gd` registers every Interactable automatically, and `vehicle.get_component(id)` finds it.
4. Add the job rule in gameplay code, not in the component scene.

## Swapping in artist meshes

Each visual is a MeshInstance3D with a clear name (for example `Body/Shell` or `Components/OilFilter/Pickable/FilterCan`). To replace one, change its mesh and keep the node, its name, and its pivot, so Interactables and gameplay references keep working. Blender-editable exports are in `assets/models/authored/blender_source/`.

## Dev tools

| Script | Purpose |
| --- | --- |
| `scripts/dev/smoke_test.gd` | Headless end-to-end oil change and economy check ($781.50). |
| `scripts/dev/tap_test.gd` | Windowed. Casts real touch rays from each gameplay camera at every job part. |
| `scripts/dev/capture_views.gd` | Windowed. Saves Bay, Under car and Engine screenshots, plus mid-job states with `-- <tag> job`. |
| `scripts/dev/inspect_vehicle.gd` | Windowed. Close-up review renders of the car. |
| `scripts/dev/measure_assets.gd` | Prints the real-world size of every imported model. |
| `scripts/dev/locate_engine_features.gd` | Finds the filter, fill cap and dipstick on the combined engine mesh. |
