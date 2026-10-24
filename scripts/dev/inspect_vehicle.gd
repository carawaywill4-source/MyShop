extends SceneTree
## Close-up review renders of the vehicle scene: 3/4 front, side, rear, open engine bay,
## and underside. Writes docs/screenshots/inspect_<n>.png and a contact sheet via the caller.
## Godot --path . --resolution 960x640 --script scripts/dev/inspect_vehicle.gd

const SHOTS := [
	[Vector3(4.0, 1.5, 4.6), Vector3(0, 0.6, 0.2)],
	[Vector3(6.2, 0.8, -0.1), Vector3(0, 0.65, -0.1)],
	[Vector3(-3.4, 1.4, -4.8), Vector3(0, 0.65, -0.6)],
	[Vector3(0.0, 1.9, 3.2), Vector3(0, 0.55, 1.45)],
	[Vector3(0.9, -1.2, 2.6), Vector3(0.1, 0.25, 1.3)],
	[Vector3(0.0, 0.75, 5.2), Vector3(0, 0.6, 0.0)],
	[Vector3(0.0, 0.85, 3.4), Vector3(0, 0.6, 2.0)],
	[Vector3(0.0, 1.2, -3.6), Vector3(0, 0.85, -2.1)],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.34, 0.37)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.82)
	env.environment.ambient_light_energy = 1.2
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	stage.add_child(sun)
	var scene_path := "res://scenes/vehicles/kessler_gt6.tscn"
	if OS.get_cmdline_user_args().size() > 0:
		scene_path = OS.get_cmdline_user_args()[0]
	var car: Node3D = (load(scene_path) as PackedScene).instantiate()
	stage.add_child(car)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.42, 0.43, 0.45)
	floor_mat.roughness = 0.7
	plane.material = floor_mat
	floor.mesh = plane
	stage.add_child(floor)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, -140, 0)
	fill.light_energy = 0.45
	stage.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 45
	stage.add_child(cam)
	for i in SHOTS.size():
		car.call("set_hood_open", i == 3, true)
		cam.look_at_from_position(SHOTS[i][0], SHOTS[i][1], Vector3.UP)
		for _f in 8:
			await process_frame
		root.get_texture().get_image().save_png("res://docs/screenshots/inspect_%d.png" % i)
	quit(0)
