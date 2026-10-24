extends SceneTree
## Renders one model from three angles to docs/screenshots/preview_<name>_<n>.png.
## Godot --path . --script scripts/dev/preview_model.gd -- res://path/model.glb [distance]

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0]
	var dist := float(args[1]) if args.size() > 1 else 1.6
	var holder := Node3D.new()
	root.add_child(holder)
	var res := load(path)
	var node: Node3D = res.instantiate() if res is PackedScene else null
	if node == null:
		node = MeshInstance3D.new()
		(node as MeshInstance3D).mesh = res
	holder.add_child(node)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.35, 0.37, 0.4)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	holder.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	holder.add_child(sun)
	var cam := Camera3D.new()
	holder.add_child(cam)
	var target := Vector3(0, float(args[2]) if args.size() > 2 else 0.3, 0)
	var name := path.get_file().get_basename()
	var angles := [Vector3(1, 0.6, 1), Vector3(-1, 0.3, 0.2), Vector3(0.3, -0.7, 1)]
	for i in angles.size():
		cam.look_at_from_position(target + (angles[i] as Vector3).normalized() * dist, target, Vector3.UP)
		for _f in 6:
			await process_frame
		root.get_texture().get_image().save_png("res://docs/screenshots/preview_%s_%d.png" % [name, i])
	quit(0)
