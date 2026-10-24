extends RefCounted
## Turns the Tripo-generated, part-segmented sport sedan (assets/models/tripo/kessler_gt6_tripo.glb)
## into a MyShop vehicle: bakes each part into vehicle space at real scale, assigns MyShop
## materials per part, drops the generated emblem, and gives the hood and wheels real pivots.
## Part numbers come from Tripo's "Generate in Parts" output; see PART_ROLES.

const SOURCE := "res://assets/models/tripo/kessler_gt6_tripo.glb"
const InteractableScript := preload("res://scripts/interactable.gd")
## Model units -> metres. The source is ~0.98 long; 4.75 gives a 4.66 m car with 0.71 m tyres.
const SCALE := 4.75
## Z range (metres) of the open floor under the engine bay.
const BAY_OPEN := Vector2(0.95, 2.15)

## Role per Tripo part index. Anything not listed is body paint.
const PART_ROLES := {
	"tyre": [7, 8, 11, 12],
	"rim": [5, 25, 9, 10],
	"hood": [4],
	"glass": [26, 22, 16, 45, 51, 50, 58, 52],
	"grille": [2],
	"remove": [36, 62, 63, 64],
	"black": [27, 29, 15, 32, 41, 46, 21, 42, 44, 49, 35, 39, 18, 40, 54, 55, 59, 60, 56, 61],
	"headlight": [37],
	"taillight": [34, 38, 47, 57],
	"exhaust": [23, 43, 48, 53],
	"roof": [3],
}

## Parts where Tripo fused two materials: triangles whose centroid (model units) falls in the
## box get the given role, the rest keep the part's own role.
const SPLITS := {
	14: {"role": "headlight", "min": Vector3(0.08, 0.143, 0.37), "max": Vector3(0.21, 0.20, 0.49)},
	28: {"role": "headlight", "min": Vector3(-0.21, 0.143, 0.37), "max": Vector3(-0.08, 0.20, 0.49)},
}

var M: Dictionary
var save: Callable
var report: Array = []


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save = mesh_saver


func _role(index: int) -> String:
	for role in PART_ROLES:
		if index in PART_ROLES[role]:
			return role
	return "paint"


func _material(role: String) -> Material:
	match role:
		"tyre": return M["tyre_rubber"]
		"rim": return M["wheel_dark"]
		"glass": return M["car_glass"]
		"grille": return M["grille_mesh"]
		"black": return M["piano_black"]
		"headlight": return M["headlight_lens"]
		"taillight": return M["taillight_lens"]
		"exhaust": return M["exhaust_tip"]
		"roof": return M["carbon_roof"]
	return M["sedan_paint"]


## Splits a part's triangles by a model-space box; returns [inside_mesh, outside_mesh] baked to metres.
func _split(mi: MeshInstance3D, xf: Transform3D, lo: Vector3, hi: Vector3) -> Array:
	var inside := SurfaceTool.new()
	var outside := SurfaceTool.new()
	inside.begin(Mesh.PRIMITIVE_TRIANGLES)
	outside.begin(Mesh.PRIMITIVE_TRIANGLES)
	var to_vehicle := Transform3D(Basis.from_scale(Vector3.ONE * SCALE), Vector3.ZERO) * xf
	var counts := [0, 0]
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx = arrays[Mesh.ARRAY_INDEX]
		var n: int = idx.size() if idx else verts.size()
		for t in range(0, n, 3):
			var a := verts[idx[t] if idx else t]
			var b := verts[idx[t + 1] if idx else t + 1]
			var c := verts[idx[t + 2] if idx else t + 2]
			var centre := xf * ((a + b + c) / 3.0)
			var hit := centre.x >= lo.x and centre.x <= hi.x and centre.y >= lo.y and centre.y <= hi.y and centre.z >= lo.z and centre.z <= hi.z
			var st := inside if hit else outside
			counts[0 if hit else 1] += 1
			for v in [a, b, c]:
				st.add_vertex(to_vehicle * v)
	report.append("split part %s: %d / %d triangles" % [mi.name, counts[0], counts[1]])
	var out := []
	for st in [inside, outside]:
		st.generate_normals()
		out.append(st.commit())
	return out


## Paint parts: downward-facing faces become underbody coating, and the floor under the engine
## bay is opened so the oil pan, drain plug and filter can be reached from below.
func _bake_paint(mi: MeshInstance3D, xf: Transform3D, name: String) -> Mesh:
	var paint := SurfaceTool.new()
	var under := SurfaceTool.new()
	paint.begin(Mesh.PRIMITIVE_TRIANGLES)
	under.begin(Mesh.PRIMITIVE_TRIANGLES)
	var to_vehicle := Transform3D(Basis.from_scale(Vector3.ONE * SCALE), Vector3.ZERO) * xf
	var used := [false, false]
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx = arrays[Mesh.ARRAY_INDEX]
		var n: int = idx.size() if idx else verts.size()
		for t in range(0, n, 3):
			var a := to_vehicle * verts[idx[t] if idx else t]
			var b := to_vehicle * verts[idx[t + 1] if idx else t + 1]
			var c := to_vehicle * verts[idx[t + 2] if idx else t + 2]
			var centre := (a + b + c) / 3.0
			var normal := (b - a).cross(c - a).normalized()
			var facing_down := absf(normal.y) > 0.55 and centre.y < 0.45
			if facing_down and centre.z > BAY_OPEN.x and centre.z < BAY_OPEN.y and absf(centre.x) < 0.62:
				continue
			var st := under if facing_down else paint
			used[1 if facing_down else 0] = true
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
	var mesh := ArrayMesh.new()
	for k in 2:
		if not used[k]:
			continue
		var st: SurfaceTool = [paint, under][k]
		st.generate_normals()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, M["sedan_paint"] if k == 0 else M["underbody"])
	return save.call(mesh, "tripo_gt6_" + name)


## Bakes a part into vehicle space (metres), optionally relative to a pivot.
func _bake(mi: MeshInstance3D, xf: Transform3D, pivot: Vector3, mat: Material, name: String) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var to_vehicle := Transform3D(Basis.from_scale(Vector3.ONE * SCALE), -pivot) * xf
	for s in mi.mesh.get_surface_count():
		st.append_from(mi.mesh, s, to_vehicle)
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return save.call(mesh, "tripo_gt6_" + name)


func _global(n: Node) -> Transform3D:
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


func assemble(car: Node3D) -> Dictionary:
	var src: Node = (load(SOURCE) as PackedScene).instantiate()
	var parts := {}
	for node in src.find_children("*", "MeshInstance3D", true, false):
		var idx := String(node.name).get_slice("_", 2).to_int()
		parts[idx] = node
	var body := _group(car, "Body")
	var trim := _group(body, "Trim")
	var lights := _group(body, "Lights")
	var glass := _group(body, "Glass")
	# Hood: hinge at its rear edge, top surface.
	var hood_src: MeshInstance3D = parts[PART_ROLES["hood"][0]]
	var hood_box := _global(hood_src) * hood_src.mesh.get_aabb()
	var hinge := Vector3(0, hood_box.end.y, hood_box.position.z) * SCALE
	var pivot := _group(body, "HoodPivot")
	pivot.position = hinge
	var hood := StaticBody3D.new()
	hood.name = "Hood"
	hood.set_script(InteractableScript)
	hood.set("part_id", "hood")
	hood.set("display_name", "Hood")
	pivot.add_child(hood)
	var hood_mesh := MeshInstance3D.new()
	hood_mesh.name = "HoodPanel"
	hood_mesh.mesh = _bake(hood_src, _global(hood_src), hinge, M["sedan_paint"], "hood")
	hood.add_child(hood_mesh)
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var box := BoxShape3D.new()
	box.size = hood_box.size * SCALE + Vector3(0, 0.06, 0)
	shape.shape = box
	shape.position = hood_box.get_center() * SCALE - hinge
	hood.add_child(shape)
	# Wheels: pair each tyre with the rim at the same position, pivot at the hub.
	var wheels := _group(car, "Wheels")
	var wheel_centres := []
	for t in PART_ROLES["tyre"]:
		var tyre: MeshInstance3D = parts[t]
		var tb := _global(tyre) * tyre.mesh.get_aabb()
		var centre := tb.get_center() * SCALE
		var name := ("Front" if centre.z > 0.0 else "Rear") + ("Left" if centre.x > 0.0 else "Right")
		var wheel := _group(wheels, name)
		wheel.position = centre
		wheel_centres.append(centre)
		var tyre_mi := MeshInstance3D.new()
		tyre_mi.name = "Tyre"
		tyre_mi.mesh = _bake(tyre, _global(tyre), centre, M["tyre_rubber"], "tyre_" + name.to_snake_case())
		wheel.add_child(tyre_mi)
		for r in PART_ROLES["rim"]:
			var rim: MeshInstance3D = parts[r]
			var rc := (_global(rim) * rim.mesh.get_aabb()).get_center() * SCALE
			if rc.distance_to(centre) < 0.15:
				var rim_mi := MeshInstance3D.new()
				rim_mi.name = "Rim"
				rim_mi.mesh = _bake(rim, _global(rim), centre, M["wheel_dark"], "rim_" + name.to_snake_case())
				wheel.add_child(rim_mi)
	# Everything else bakes in place into its group.
	var lowest := INF
	for idx in parts:
		var role := _role(idx)
		if role in ["tyre", "rim", "hood"]:
			continue
		if role == "remove":
			report.append("removed part %d (generated emblem / stray)" % idx)
			continue
		var mi: MeshInstance3D = parts[idx]
		if SPLITS.has(idx):
			var rule: Dictionary = SPLITS[idx]
			var pieces := _split(mi, _global(mi), rule["min"], rule["max"])
			var lens := MeshInstance3D.new()
			lens.name = "%s_%d" % [String(rule["role"]).to_pascal_case(), idx]
			(pieces[0] as ArrayMesh).surface_set_material(0, _material(rule["role"]))
			lens.mesh = save.call(pieces[0], "tripo_gt6_part_%d_%s" % [idx, rule["role"]])
			lights.add_child(lens)
			var rest := MeshInstance3D.new()
			rest.name = "%s_%d" % [role.to_pascal_case(), idx]
			(pieces[1] as ArrayMesh).surface_set_material(0, _material(role))
			rest.mesh = save.call(pieces[1], "tripo_gt6_part_%d" % idx)
			body.add_child(rest)
			continue
		var parent := body
		match role:
			"glass": parent = glass
			"headlight", "taillight": parent = lights
			"black", "exhaust", "grille": parent = trim
		var out := MeshInstance3D.new()
		out.name = "%s_%d" % [role.to_pascal_case(), idx]
		if role == "paint":
			out.mesh = _bake_paint(mi, _global(mi), "part_%d" % idx)
		else:
			out.mesh = _bake(mi, _global(mi), Vector3.ZERO, _material(role), "part_%d" % idx)
		parent.add_child(out)
		if role == "paint":
			var b := _global(mi) * mi.mesh.get_aabb()
			lowest = minf(lowest, b.position.y * SCALE)
	# Backing behind the grille where the generated emblem was removed.
	var Forge := preload("res://scripts/authoring/mesh_forge.gd")
	var emblem: MeshInstance3D = parts[36]
	var eb := _global(emblem) * emblem.mesh.get_aabb()
	var patch := MeshInstance3D.new()
	patch.name = "GrilleBacking"
	patch.mesh = save.call(Forge.beveled_box(Vector3(eb.size.x * SCALE + 0.12, eb.size.y * SCALE + 0.08, 0.02), 0.01, M["grille_mesh"]), "tripo_gt6_grille_backing")
	patch.position = eb.get_center() * SCALE - Vector3(0, 0, eb.size.z * SCALE + 0.02)
	trim.add_child(patch)
	src.free()
	return {"hinge": hinge, "hood_box": AABB(hood_box.position * SCALE, hood_box.size * SCALE), "wheels": wheel_centres, "sill": lowest}
