extends RefCounted
## Generic importer for Tripo-generated, segmented, textured vehicles (data/vehicles/roster.json).
## Keeps Tripo's own textures and:
##  - scales to the real vehicle length, front +Z, ground at Y=0, centred;
##  - finds the four wheels (round, low, outboard parts) and gives each a hub pivot;
##  - cuts the hood panel out of the body by region and hinges it at the cowl;
##  - paints chrome badges and lettering out of the texture at the nose and tail;
##  - opens the floor under the engine bay so the sump, plug and filter can be reached.

const InteractableScript := preload("res://scripts/interactable.gd")

var save: Callable
var report: Array = []
var _materials: Dictionary = {}
var _vehicle_id := ""


func _init(mesh_saver: Callable) -> void:
	save = mesh_saver


static func _global(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur and cur is Node3D:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


func _group(parent: Node3D, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	return n


## Simplified index buffer for very dense single-mesh models (meshoptimizer via ImporterMesh LODs),
## keeping UV seams so textures still line up.
func _decimated_indices(arrays: Array, target_tris: int) -> PackedInt32Array:
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if idx.size() / 3 <= target_tris:
		return idx
	var im := ImporterMesh.new()
	var clean := []
	clean.resize(Mesh.ARRAY_MAX)
	clean[Mesh.ARRAY_VERTEX] = arrays[Mesh.ARRAY_VERTEX]
	clean[Mesh.ARRAY_NORMAL] = arrays[Mesh.ARRAY_NORMAL]
	clean[Mesh.ARRAY_TEX_UV] = arrays[Mesh.ARRAY_TEX_UV]
	clean[Mesh.ARRAY_INDEX] = idx
	im.add_surface(Mesh.PRIMITIVE_TRIANGLES, clean)
	im.generate_lods(25.0, 60.0, [])
	var best := idx
	for lod in im.get_surface_lod_count(0):
		var cand := im.get_surface_lod_indices(0, lod)
		if cand.size() / 3 >= target_tris * 0.6:
			best = cand
	report.append("%s: decimated %d -> %d triangles" % [_vehicle_id, idx.size() / 3, best.size() / 3])
	return best


## Triangle soup of one part in vehicle space: [{verts:[a,b,c], uvs:[...], surf:int}]
func _triangles(mi: MeshInstance3D, xf: Transform3D, max_tris := 260000) -> Array:
	var out := []
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs = arrays[Mesh.ARRAY_TEX_UV]
		var norms = arrays[Mesh.ARRAY_NORMAL]
		var idx = arrays[Mesh.ARRAY_INDEX]
		if idx:
			idx = _decimated_indices(arrays, max_tris)
		var nb := xf.basis.inverse().transposed()
		var n: int = idx.size() if idx else verts.size()
		for t in range(0, n, 3):
			var ids := [idx[t] if idx else t, idx[t + 1] if idx else t + 1, idx[t + 2] if idx else t + 2]
			var tri := {"v": [xf * verts[ids[0]], xf * verts[ids[1]], xf * verts[ids[2]]], "s": s}
			if uvs:
				tri["uv"] = [uvs[ids[0]], uvs[ids[1]], uvs[ids[2]]]
			if norms:
				tri["n"] = [(nb * norms[ids[0]]).normalized(), (nb * norms[ids[1]]).normalized(), (nb * norms[ids[2]]).normalized()]
			out.append(tri)
	return out


func assemble(car: Node3D, spec: Dictionary) -> Dictionary:
	var id: String = spec["id"]
	_vehicle_id = id
	var src: Node = (load(spec["source"]) as PackedScene).instantiate()
	var meshes: Array = src.find_children("*", "MeshInstance3D", true, false)
	var total := AABB()
	for mi in meshes:
		var b: AABB = _global(mi) * (mi as MeshInstance3D).mesh.get_aabb()
		total = b if total.size == Vector3.ZERO else total.merge(b)
	var yaw := PI * 0.5 if total.size.x > total.size.z else 0.0
	yaw += deg_to_rad(float(spec.get("yaw_degrees", 0.0)))
	var scale := float(spec["length_m"]) / maxf(total.size.x, total.size.z)
	var c0 := total.get_center()
	var to_vehicle := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), Vector3.ZERO) * Transform3D(Basis.IDENTITY, Vector3(-c0.x, -total.position.y, -c0.z))
	var boxes := []
	var vbox := AABB()
	for mi in meshes:
		var b: AABB = (to_vehicle * _global(mi)) * (mi as MeshInstance3D).mesh.get_aabb()
		boxes.append(b)
		vbox = b if vbox.size == Vector3.ZERO else vbox.merge(b)
	var L := vbox.size.z
	var W := vbox.size.x
	var H := vbox.size.y
	var front := vbox.end.z
	var rear := vbox.position.z
	var hood_z: Array = spec.get("hood_z", [0.25, 0.485])
	var hood_from := float(hood_z[0]) * L
	var hood_to := float(hood_z[1]) * L
	var hood_min_y := float(spec.get("hood_min_y", 0.42)) * H
	var bay := Vector2(hood_from, hood_to - 0.22)
	# Wheels: round (Y~Z), low, outboard parts.
	var is_wheel := []
	for i in meshes.size():
		var b: AABB = boxes[i]
		var c := b.get_center()
		var ratio := b.size.y / maxf(b.size.z, 0.001)
		is_wheel.append(c.y < H * 0.32 and b.size.y > H * 0.15 and ratio > 0.7 and ratio < 1.4 and absf(c.x) > W * 0.25 and b.size.x < W * 0.3)
	var track := 0.0
	for i in meshes.size():
		if is_wheel[i]:
			track = maxf(track, absf((boxes[i] as AABB).get_center().x))
	if track == 0.0:
		track = W * 0.38
	var geometry_split: bool = spec.get("split", "parts") == "geometry"
	var all_tris := {}
	var wheel_cyl := []
	if geometry_split:
		# One solid mesh: find each wheel from its ground contact patch.
		var r := float(spec.get("tyre_radius_m", 0.34))
		var buckets := {}
		for i in meshes.size():
			all_tris[i] = _triangles(meshes[i], to_vehicle * _global(meshes[i]))
			for tri in all_tris[i]:
				for v in tri["v"]:
					if v.y < 0.03 and absf(v.x) > W * 0.2 and absf(v.z) > L * 0.15:
						var key := Vector2i(signi(int(signf(v.x))), signi(int(signf(v.z))))
						if not buckets.has(key):
							buckets[key] = [Vector3.ZERO, 0]
						buckets[key][0] += v
						buckets[key][1] += 1
		for key in buckets:
			var mean: Vector3 = buckets[key][0] / float(buckets[key][1])
			wheel_cyl.append(Vector3(mean.x, r, mean.z))
			track = maxf(track, absf(mean.x))
		report.append("%s: wheel centres from contact patches %s" % [id, wheel_cyl])
	var body_half := track + 0.12
	var badge_uvs := {}
	var body_tris := {}
	var hood_tris := []
	var wheel_groups := {}
	var sill := INF
	for i in meshes.size():
		var mi: MeshInstance3D = meshes[i]
		var b: AABB = boxes[i]
		var tris: Array = all_tris[i] if all_tris.has(i) else _triangles(mi, to_vehicle * _global(mi))
		if geometry_split:
			var rest := []
			for tri in tris:
				var cen: Vector3 = (tri["v"][0] + tri["v"][1] + tri["v"][2]) / 3.0
				var hit := -1
				for w in wheel_cyl.size():
					var wc: Vector3 = wheel_cyl[w]
					if signf(cen.x) == signf(wc.x) and absf(cen.x) > absf(wc.x) - 0.17 and Vector2(cen.y - wc.y, cen.z - wc.z).length() < wc.y * 1.04:
						hit = w
				if hit < 0:
					rest.append(tri)
					continue
				var wc2: Vector3 = wheel_cyl[hit]
				var key2 := ("Front" if wc2.z > 0.0 else "Rear") + ("Left" if wc2.x > 0.0 else "Right")
				if not wheel_groups.has(key2):
					wheel_groups[key2] = {"box": AABB(wc2 - Vector3(0.14, wc2.y, wc2.y), Vector3(0.28, wc2.y * 2.0, wc2.y * 2.0)), "parts": [[mi, []]]}
				wheel_groups[key2]["parts"][0][1].append(tri)
			tris = rest
		if is_wheel[i]:
			var key := ("Front" if b.get_center().z > 0.0 else "Rear") + ("Left" if b.get_center().x > 0.0 else "Right")
			if not wheel_groups.has(key):
				wheel_groups[key] = {"box": b, "parts": []}
			wheel_groups[key]["box"] = (wheel_groups[key]["box"] as AABB).merge(b)
			wheel_groups[key]["parts"].append([mi, tris])
			continue
		var bc := b.get_center()
		if b.size.x < W * 0.14 and b.size.y < H * 0.10 and absf(bc.x) < W * 0.08 and (b.end.z > front - 0.25 or b.position.z < rear + 0.20):
			report.append("%s: removed badge-sized part %s" % [id, mi.name])
			continue
		if b.size.x > W * 0.5:
			sill = minf(sill, b.position.y)
		var keep := []
		for tri in tris:
			var v: Array = tri["v"]
			var centre: Vector3 = (v[0] + v[1] + v[2]) / 3.0
			var normal: Vector3 = (v[1] - v[0]).cross(v[2] - v[0]).normalized()
			# Badge zones: centre of the nose and the tail.
			if tri.has("uv") and absf(centre.x) < body_half * 0.45:
				var nose := centre.z > front - 0.55 and centre.y > H * 0.22 and centre.y < H * 0.74
				var tail := centre.z < rear + 0.45 and centre.y > H * 0.30 and centre.y < H * 0.86
				if nose or tail:
					var s: int = tri["s"]
					if not badge_uvs.has(mi.mesh.surface_get_material(s)):
						badge_uvs[mi.mesh.surface_get_material(s)] = []
					badge_uvs[mi.mesh.surface_get_material(s)].append(tri["uv"])
			# Hood: upward-facing skin between the cowl and the nose.
			if absf(normal.y) > 0.35 and centre.z > hood_from and centre.z < hood_to and centre.y > hood_min_y and absf(centre.x) < track * 0.88:
				tri["m"] = mi.mesh.surface_get_material(tri["s"])
				hood_tris.append(tri)
				continue
			# Optionally clear the generator's own engine-bay contents; MyShop installs real parts.
			if spec.get("clear_bay", false) and centre.z > bay.x + 0.03 and centre.z < hood_to - 0.12 and absf(centre.x) < track - 0.16 and centre.y > 0.18 and centre.y < H * 0.60:
				continue
			# Open floor below the bay.
			if absf(normal.y) > 0.55 and centre.y < 0.45 and centre.z > bay.x and centre.z < bay.y and absf(centre.x) < 0.6:
				continue
			keep.append(tri)
		body_tris[i] = [mi, keep]
	# Badges first, so the shared materials carry the cleaned textures.
	for mat in badge_uvs:
		_debadge(mat, badge_uvs[mat])
	var body := _group(car, "Body")
	for i in body_tris:
		var entry: Array = body_tris[i]
		var out := MeshInstance3D.new()
		out.name = "Part_%d" % i
		out.mesh = _commit(entry[1], entry[0], Vector3.ZERO, "%s_part_%d" % [id, i])
		if out.mesh:
			body.add_child(out)
	var hinge := Vector3(0, 0, hood_from)
	var hood_box := AABB()
	for tri in hood_tris:
		for v in tri["v"]:
			hood_box = AABB(v, Vector3.ZERO) if hood_box.size == Vector3.ZERO and hood_box.position == Vector3.ZERO else hood_box.expand(v)
	hinge.y = hood_box.end.y
	if not hood_tris.is_empty():
		var pivot := _group(body, "HoodPivot")
		pivot.position = hinge
		var hood := StaticBody3D.new()
		hood.name = "Hood"
		hood.set_script(InteractableScript)
		hood.set("part_id", "hood")
		hood.set("display_name", "Hood")
		pivot.add_child(hood)
		var panel := MeshInstance3D.new()
		panel.name = "HoodPanel"
		panel.mesh = _commit(hood_tris, null, hinge, "%s_hood" % id, true)
		hood.add_child(panel)
		var shape := CollisionShape3D.new()
		shape.name = "TouchTarget"
		var box := BoxShape3D.new()
		box.size = hood_box.size + Vector3(0, 0.08, 0)
		shape.shape = box
		shape.position = hood_box.get_center() - hinge
		hood.add_child(shape)
	else:
		report.append("%s: no hood surface found" % id)
	var wheels_node := _group(car, "Wheels")
	var centres := []
	for key in wheel_groups:
		var g: Dictionary = wheel_groups[key]
		var c: Vector3 = (g["box"] as AABB).get_center()
		var wheel := _group(wheels_node, key)
		wheel.position = c
		centres.append(c)
		var k := 0
		for part in g["parts"]:
			var mesh_i := MeshInstance3D.new()
			mesh_i.name = "WheelPart_%d" % k
			mesh_i.mesh = _commit(part[1], part[0], c, "%s_%s_%d" % [id, key.to_snake_case(), k])
			wheel.add_child(mesh_i)
			k += 1
	if wheel_groups.size() != 4:
		report.append("%s: found %d wheel groups (expected 4)" % [id, wheel_groups.size()])
	report.append("%s: L=%.2f W=%.2f H=%.2f hood_tris=%d badge_tris=%d" % [id, L, W, H, hood_tris.size(), badge_uvs.values().reduce(func(a, x): return a + x.size(), 0)])
	src.free()
	return {"length": L, "width": body_half * 2.0, "track": track, "height": H, "front": front, "rear": rear, "hinge": hinge,
		"wheels": centres, "sill": sill if sill < INF else 0.15, "bay": bay, "has_hood": not hood_tris.is_empty()}


func _commit(tris: Array, mi: MeshInstance3D, pivot: Vector3, name: String, per_tri_material := false) -> Mesh:
	if tris.is_empty():
		return null
	var by_surface := {}
	for tri in tris:
		var key = tri["m"] if per_tri_material else tri["s"]
		if not by_surface.has(key):
			by_surface[key] = []
		by_surface[key].append(tri)
	var out := ArrayMesh.new()
	for key in by_surface:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var has_normals: bool = by_surface[key][0].has("n")
		for tri in by_surface[key]:
			# Keep the generator's normals and wind each triangle to face the same way, since
			# Tripo meshes mix winding orders.
			var order := [0, 1, 2]
			if has_normals:
				var v: Array = tri["v"]
				var face: Vector3 = (v[1] - v[0]).cross(v[2] - v[0])
				var avg: Vector3 = tri["n"][0] + tri["n"][1] + tri["n"][2]
				if face.dot(avg) > 0.0:
					order = [0, 2, 1]
			for k in order:
				if tri.has("uv"):
					st.set_uv(tri["uv"][k])
				if has_normals:
					st.set_normal(tri["n"][k])
				st.add_vertex(tri["v"][k] - pivot)
		if not has_normals:
			st.generate_normals()
		st.commit(out)
		var mat: Material = key if per_tri_material else mi.mesh.surface_get_material(key)
		out.surface_set_material(out.get_surface_count() - 1, _shared_material(mat))
	return save.call(out, "veh_" + name)


## Tripo parts share one textured material; save it once per vehicle so every part references it.
func _shared_material(src: Material) -> Material:
	if src == null:
		return null
	if not _materials.has(src):
		var dir := "res://assets/materials/vehicles/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var path := "%s%s_%d.res" % [dir, _vehicle_id, _materials.size()]
		# Tripo gives each part its own small texture set, already imported next to the .glb;
		# the copy references those files. Only badge-cleaned albedos are embedded.
		var copy: Material = src.duplicate(false)
		if copy is StandardMaterial3D:
			# Tripo shells are double layered; drawing both sides makes the inner layer shadow the paint.
			(copy as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_BACK
			# The baked normal maps don't match rebuilt tangents and blotch the paint; geometry
			# is dense enough that smooth vertex normals read better.
			(copy as StandardMaterial3D).normal_enabled = false
		ResourceSaver.save(copy, path)
		_materials[src] = load(path)
	return _materials[src]


## Removes chrome logos and lettering: inside the badge-zone UV triangles, bright low-saturation
## texels are replaced with the median of the surrounding non-chrome texels.
func _debadge(src: Material, uv_tris: Array) -> void:
	var mat := src as StandardMaterial3D
	if mat == null or mat.albedo_texture == null:
		return
	var img := mat.albedo_texture.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var changed := 0
	for uv in uv_tris:
		var p0 := Vector2(uv[0].x * w, uv[0].y * h)
		var p1 := Vector2(uv[1].x * w, uv[1].y * h)
		var p2 := Vector2(uv[2].x * w, uv[2].y * h)
		var lo := Vector2(minf(p0.x, minf(p1.x, p2.x)), minf(p0.y, minf(p1.y, p2.y))).floor()
		var hi := Vector2(maxf(p0.x, maxf(p1.x, p2.x)), maxf(p0.y, maxf(p1.y, p2.y))).ceil()
		var base := []
		var chrome := []
		for y in range(clampi(int(lo.y), 0, h - 1), clampi(int(hi.y) + 1, 0, h)):
			for x in range(clampi(int(lo.x), 0, w - 1), clampi(int(hi.x) + 1, 0, w)):
				if not Geometry2D.point_is_inside_triangle(Vector2(x + 0.5, y + 0.5), p0, p1, p2):
					continue
				var col := img.get_pixel(x, y)
				if col.v > 0.42 and col.s < 0.25:
					chrome.append(Vector2i(x, y))
				else:
					base.append(col)
		if chrome.is_empty() or base.size() < 4:
			continue
		base.sort_custom(func(a, b): return a.v < b.v)
		var fill: Color = base[base.size() / 4]
		for px in chrome:
			img.set_pixelv(px, fill)
		changed += chrome.size()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	report.append("%s: repainted %d badge texels" % [_vehicle_id, changed])
