extends SceneTree
## Prints the bounding box of every imported model so placement in scenes uses real sizes.
## Godot --headless --path . --script scripts/dev/measure_assets.gd

func _init() -> void:
	for dir_path in ["res://assets/models/polyhaven", "res://assets/models/sources"]:
		_walk(dir_path)
	quit(0)


func _walk(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_walk(path + "/" + sub)
	for file in dir.get_files():
		if file.ends_with(".gltf") or file.ends_with(".glb"):
			var scene := load(path + "/" + file) as PackedScene
			if scene == null:
				print("FAILED ", file)
				continue
			var node := scene.instantiate() as Node3D
			var box := _aabb(node, Transform3D.IDENTITY)
			print("%-40s size=%s min=%s meshes=%d" % [file, box.size.snapped(Vector3.ONE * 0.01), box.position.snapped(Vector3.ONE * 0.01), _count(node)])
			node.free()


func _aabb(node: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if node is Node3D:
		t = xf * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh:
		out = t * (node as MeshInstance3D).mesh.get_aabb()
		first = false
	for child in node.get_children():
		var sub := _aabb(child, t)
		if sub.size == Vector3.ZERO:
			continue
		out = sub if first else out.merge(sub)
		first = false
	return out


func _count(node: Node) -> int:
	var n := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		n += _count(child)
	return n
