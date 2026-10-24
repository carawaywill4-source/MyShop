extends SceneTree
## Shows the raw Tripo GLB in the existing workshop. Does not load the oil-change game.
## Launch: Godot --path MyShop --resolution 1280x720 --script res://scripts/dev/visual_prototype.gd

const KAITO := "res://assets/models/tripo/kaito_sprint.glb"
const KESSLER := "res://assets/models/tripo/kessler_gt6_tripo.glb"
## Source mesh is 0.981 m long. Uniform scale only, so the length is about 4.45 m.
const LENGTH_SCALE := 4.45 / 0.9809265


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var workshop: Node = (load("res://scenes/workshop/workshop_bay.tscn") as PackedScene).instantiate()
	root.add_child(workshop)
	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.current = true
	root.add_child(cam)
	var out_dir := ProjectSettings.globalize_path("res://captures/visual")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var kaito := _place(KAITO)
	await process_frame
	await process_frame
	await create_timer(0.6).timeout
	await _shot(cam, Vector3(3.1, 1.45, 4.6), Vector3(0, 0.75, 0), out_dir + "/kaito_front.png")
	await _shot(cam, Vector3(-3.6, 1.2, 0.15), Vector3(0, 0.7, 0), out_dir + "/kaito_side.png")
	await _shot(cam, Vector3(3.1, 1.45, -4.6), Vector3(0, 0.75, 0), out_dir + "/kaito_rear.png")
	await _shot(cam, Vector3(0.8, 1.15, 3.1), Vector3(0, 0.7, 1.4), out_dir + "/kaito_nose.png")
	await _shot(cam, Vector3(0.35, 1.15, 0.15), Vector3(0.15, 1.05, 1.3), out_dir + "/kaito_cockpit.png")
	await _shot(cam, Vector3(-1.7, 1.15, 0.35), Vector3(0.1, 1.0, 0.2), out_dir + "/kaito_window.png")
	kaito.visible = false
	_place(KESSLER)
	await process_frame
	await create_timer(0.4).timeout
	await _shot(cam, Vector3(3.1, 1.45, 4.6), Vector3(0, 0.75, 0), out_dir + "/kessler_raw_front.png")
	print("VISUAL PROTOTYPE CAPTURED ", out_dir)
	quit(0)


func _place(path: String) -> Node3D:
	var holder := Node3D.new()
	root.add_child(holder)
	var model: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(model)
	model.scale = Vector3.ONE * LENGTH_SCALE
	model.position = Vector3(0, 0.02, 0)
	return holder


func _shot(cam: Camera3D, eye: Vector3, focus: Vector3, path: String) -> void:
	cam.global_position = eye
	cam.look_at(focus, Vector3.UP)
	await create_timer(0.35).timeout
	var image: Image = root.get_viewport().get_texture().get_image()
	image.save_png(path)
	print("CAPTURED ", path)
