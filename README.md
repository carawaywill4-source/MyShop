# MyShop

A small iPhone-first auto repair prototype. This is not the full game. It is the first playable loop: one bay, one lift, one fictional commuter, one oil-change job.

## Current status

Phase 2 is in progress. You can start a work order, choose tools, service the car, and see that a $55 oil change is not $55 of profit.

Unreal Engine is the long-term target if this Mac’s storage and memory change. Today the project runs in Godot 4.7.2 because Unreal does not fit this machine.

## Open and play

1. Godot 4.7.2 is already installed at `/Applications/Godot.app`.
2. Open Godot.
3. Import `/Users/willsmacbook/Developer/MyShop`.
4. Press Play.

Or from Terminal:

`/Applications/Godot.app/Contents/MacOS/Godot --path /Users/willsmacbook/Developer/MyShop`

## How to complete the oil change

1. Read the work order and tap **Start job**.
2. Tap **Under car**.
3. Select **Pan**, then tap the pad under the engine.
4. Select **Socket**, tap the drain plug, wait for the oil to drain, then tap the plug area again to reinstall it.
5. Select **Filter**, remove the old filter, tap again to install the new one.
6. Tap **Engine**, select **Hand**, open the hood, open the fill cap.
7. Select **Oil** and tap the fill opening until the game fill is complete.
8. Close the cap. Optionally check the dipstick.
9. Tap **Complete job** and read the payment breakdown.

Wrong tools are rejected with a reason. Nothing is damaged just to punish you.

## What this is not

- Not a real service manual.
- Not licensed real-world brands. The car is the fictional Harbor Commute.
- Not an iPhone App Store build yet. Play it on this Mac first.

## Inspecting the 3D foundation

- Main scenes: `scenes/workshop/workshop_bay.tscn` (whole bay), `scenes/vehicles/harbor_commute.tscn` (car), `scenes/vehicles/components/` (repairable parts), `scenes/equipment/` (lift, drain caddy).
- Open any of them in Godot and press F6 to view it on its own, or press Play to run the game.
- Rebuild authored meshes and scenes: `Godot --headless --path . --script scripts/dev/build_foundation.gd`
- Tests: `Godot --headless --path . --script scripts/dev/smoke_test.gd`, and windowed `Godot --path . --resolution 1266x585 --script scripts/dev/tap_test.gd`

See `docs/PRODUCT_VISION.md` (direction), `docs/ARCHITECTURE.md` (how it fits together), `docs/STATUS.md` (what works and what does not), and `docs/ASSET_REGISTER.md` (licences).
