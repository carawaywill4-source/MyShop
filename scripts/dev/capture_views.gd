extends SceneTree
## Renders Bay, Under car and Engine views to docs/screenshots/ for visual review.
## Run windowed (not --headless): Godot --path . --script scripts/dev/capture_views.gd -- <tag>

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var tag := "current"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		tag = args[0]
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))
	var views := ["bay", "under", "engine"]
	if args.size() > 1 and args[1] == "job":
		main.accept_job()
	for view in views:
		main.world.set_view(view, true)
		for _i in 20:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png("res://docs/screenshots/%s_%s.png" % [tag, view])
		print("saved ", tag, "_", view)
	if args.size() > 1 and args[1] == "job":
		# Mid-job states: caddy placed under the car, then hood open in the engine view.
		main.select_tool("drain_pan")
		main._on_part_tapped("drain_pan_spot")
		main.world.set_view("under", true)
		await _settle()
		root.get_texture().get_image().save_png("res://docs/screenshots/%s_under_pan.png" % tag)
		main.select_tool("hand")
		main.set_view("engine")
		main._on_part_tapped("hood")
		await _settle(90)
		root.get_texture().get_image().save_png("res://docs/screenshots/%s_engine_open.png" % tag)
		print("saved mid-job states")
	quit(0)


func _settle(frames := 60) -> void:
	for _i in frames:
		await process_frame
