extends SceneTree
## Lists every mesh part in a glTF with its bounds and triangle count (for mapping AI-split parts).
## Godot --headless --path . --script scripts/dev/list_parts.gd -- res://path/model.glb

func _init() -> void:
	var path: String = OS.get_cmdline_user_args()[0]
	var node: Node = (load(path) as PackedScene).instantiate()
	var total := AABB()
	var rows := []
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var xf := _global(m)
		var box := xf * m.mesh.get_aabb()
		total = box if total.size == Vector3.ZERO else total.merge(box)
		var tris := 0
		for s in m.mesh.get_surface_count():
			var idx = m.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx else m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX].size()) / 3
		rows.append([m.name, box, tris])
	print("TOTAL size=", total.size.snapped(Vector3.ONE * 0.01), " pos=", total.position.snapped(Vector3.ONE * 0.01))
	for r in rows:
		var b: AABB = r[1]
		print("%-16s c=%s s=%s tris=%d" % [r[0], b.get_center().snapped(Vector3.ONE * 0.01), b.size.snapped(Vector3.ONE * 0.01), r[2]])
	quit(0)


func _global(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur and cur is Node3D:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf
