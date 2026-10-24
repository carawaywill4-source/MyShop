# Status

Last updated: 2026-10-23

## Working now

- Godot 4.7.2 project opens with a mobile renderer.
- Bay shows a Kenney Car Kit sedan on the lift. Engine and under views show a Grab3D engine, radiator, and battery.
- Oil-change job, tools, wrong-tool messages, $750 start, $55 charge, and $23.50 parts/supplies are unchanged.
- Job and price data still live in JSON.

## Not working yet

- The bay is laid out like a real one-car shop: door, two-post lift, tool cart, waste-oil drum, and a stained pad under the car. Walls and props are still simple geometry. The engine model is one piece, so the filter and drain plug you tap are small markers on it.
- No iPhone export.
- No save/load, diagnostics, employees, or extra vehicles.
- Touch has not been tested on a physical iPhone.

## Tests run

- Headless launch: no script errors.
- Automated oil-change smoke test passed, including $781.50 cash after the $31.50 net.
- Captured Bay, Under car, and Engine views after the model swap. Bay shows the sedan on the lift. Engine shows the motor between the front wheels. Under car shows the oil pan.
- No iPhone build was made.
