extends SceneTree
## Verifies each oil-change part can be tapped from its gameplay camera: projects the part to
## the screen, casts the same physics ray a touch would, and checks the hit is that part and
## that it lands in the 3D band between the HUD bars. Run windowed:
## Godot --path . --resolution 1266x585 --script scripts/dev/tap_test.gd

const CHECKS := [
	["under", "drain_pan_spot"], ["under", "drain_plug"], ["under", "oil_filter"],
	["engine", "hood"], ["engine", "fill_cap"], ["engine", "dipstick"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.accept_job()
	var failed := 0
	for check in CHECKS:
		var view: String = check[0]
		var part_id: String = check[1]
		main.world.set_view(view, true)
		if part_id == "drain_plug":
			main.select_tool("drain_pan")
			main._on_part_tapped("drain_pan_spot")
		if part_id == "fill_cap" or part_id == "dipstick":
			main.world.set_hood_open(true)
			main.world.vehicle.set_hood_open(true, true)
		for _i in 10:
			await physics_frame
		var cam: Camera3D = main.world.camera
		var part: Node3D = main.world.parts[part_id]
		var target := part.global_position
		for child in part.get_children():
			if child is CollisionShape3D:
				target = (child as CollisionShape3D).global_position
		var screen := cam.unproject_position(target)
		var size := root.get_visible_rect().size
		var in_band := screen.y > size.y * 0.27 and screen.y < size.y * 0.66 and screen.x > 0 and screen.x < size.x
		var from := cam.project_ray_origin(screen)
		var to := from + cam.project_ray_normal(screen) * 20.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_bodies = true
		var hit := cam.get_world_3d().direct_space_state.intersect_ray(query)
		var hit_id := ""
		if hit and hit.collider and hit.collider.get("part_id") != null:
			hit_id = hit.collider.get("part_id")
		var ok := hit_id == part_id
		print("%s  %-7s %-15s screen=(%d,%d) hit=%s %s" % ["OK  " if ok else "FAIL", view, part_id, screen.x, screen.y, hit_id, "" if in_band else "(behind HUD)"])
		if not ok:
			failed += 1
	print("TAP TEST %s" % ("PASSED" if failed == 0 else "FAILED %d" % failed))
	quit(0 if failed == 0 else 1)
