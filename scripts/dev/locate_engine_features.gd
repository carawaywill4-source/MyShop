extends SceneTree
## Finds where colour-coded features (blue filter, yellow cap/dipstick, dark pan) sit on the
## single-mesh Grab3D engine by sampling its base-colour texture at each vertex UV.
## Godot --headless --path . --script scripts/dev/locate_engine_features.gd

func _init() -> void:
	var scene: Node = (load("res://assets/models/sources/car-engine.glb") as PackedScene).instantiate()
	var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
	var mat := mi.mesh.surface_get_material(0) as StandardMaterial3D
	var img: Image = mat.albedo_texture.get_image()
	if img.is_compressed():
		img.decompress()
	print("mesh xform ", mi.transform, " tex ", img.get_size())
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var buckets := {"blue": [], "yellow": [], "orange": [], "black": []}
	for i in verts.size():
		var uv := uvs[i]
		var c := img.get_pixel(clampi(int(fposmod(uv.x, 1.0) * img.get_width()), 0, img.get_width() - 1), clampi(int(fposmod(uv.y, 1.0) * img.get_height()), 0, img.get_height() - 1))
		var p := mi.transform * verts[i]
		if c.b > 0.6 and c.r < 0.55 and c.b > c.r + 0.2:
			buckets["blue"].append(p)
		elif c.r > 0.7 and c.g > 0.6 and c.b < 0.35:
			buckets["yellow"].append(p)
		elif c.r > 0.75 and c.g > 0.35 and c.g < 0.6 and c.b < 0.5:
			buckets["orange"].append(p)
	for key in buckets:
		var pts: Array = buckets[key]
		if pts.is_empty():
			print(key, ": none")
			continue
		var box := AABB(pts[0], Vector3.ZERO)
		for p in pts:
			box = box.expand(p)
		print(key, " n=", pts.size(), " min=", box.position.snapped(Vector3.ONE * 0.005), " max=", box.end.snapped(Vector3.ONE * 0.005))
		if key == "yellow":
			var left: Array = pts.filter(func(p): return p.x < 0.0)
			var right: Array = pts.filter(func(p): return p.x >= 0.0)
			for part in [left, right]:
				if part.is_empty():
					continue
				var b := AABB(part[0], Vector3.ZERO)
				for p in part:
					b = b.expand(p)
				print("   yellow cluster min=", b.position.snapped(Vector3.ONE * 0.005), " max=", b.end.snapped(Vector3.ONE * 0.005))
	img.save_png("res://docs/screenshots/engine_basecolor.png")
	quit(0)
