extends RefCounted
## Turns the Tripo part-segmented inline-6 (assets/models/tripo/engine_i6_tripo_parts.glb) into the
## engine_i6 component scene. The source is untextured, so each part gets a MyShop material from
## its position and size: cam cover and coils black, block and head cast aluminium, sump dark
## cast, small fittings steel. The engine is turned so its crank runs along +Z (longitudinal),
## timing cover forward.

const SOURCE := "res://assets/models/tripo/engine_i6_tripo_parts.glb"
const RepairableScript := preload("res://scripts/components/repairable_component.gd")
## Source units are close to metres (0.83 m long block); keep real size.
const SCALE := 0.95
## Rotates source -X (timing end) to vehicle +Z (front).
const MOUNT := Basis(Vector3.UP, PI * 0.5)

var M: Dictionary
var save: Callable
var bounds := AABB()


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save = mesh_saver


func _global(n: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur := n
	while cur and cur is Node3D:
		xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf


## Picks a material from where the part sits on the engine (source space, y up, x along crank).
func _material_for(box: AABB, top: float, bottom: float) -> Array:
	var c := box.get_center()
	var biggest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	if c.y > top - 0.12:
		return ["CamCover", M["engine_black"]]
	if c.y < bottom + 0.10 and box.size.x > 0.2:
		return ["OilPan", M["cast_iron"]]
	if biggest > 0.45:
		return ["Block", M["cast_aluminum"]]
	if biggest < 0.12:
		return ["Fitting", M["bare_steel"]]
	if absf(c.x) > 0.33:
		return ["FrontDrive" if c.x < 0.0 else "Bellhousing", M["engine_black"] if c.x < 0.0 else M["cast_aluminum"]]
	return ["Ancillary", M["graphite_steel"]]


func build() -> Node3D:
	var src: Node = (load(SOURCE) as PackedScene).instantiate()
	var meshes := src.find_children("*", "MeshInstance3D", true, false)
	var total := AABB()
	for mi in meshes:
		var b: AABB = _global(mi) * (mi as MeshInstance3D).mesh.get_aabb()
		total = b if total.size == Vector3.ZERO else total.merge(b)
	var root := Node3D.new()
	root.name = "Engine"
	root.set_script(RepairableScript)
	root.set("component_id", "engine_block")
	root.set("display_name", "3.0 L twin-turbo inline-6")
	root.set("access_view", "engine")
	root.set("separate_mesh", true)
	# Centre the engine on X/Z with the sump bottom at Y=0 so the bay can place it simply.
	var recentre := Vector3(-total.get_center().x, -total.position.y, -total.get_center().z)
	var to_vehicle := Transform3D(MOUNT.scaled(Vector3.ONE * SCALE), Vector3.ZERO) * Transform3D(Basis.IDENTITY, recentre)
	var top := total.end.y
	var bottom := total.position.y
	var counts := {}
	for mi in meshes:
		var m := mi as MeshInstance3D
		var xf := _global(m)
		var box: AABB = xf * m.mesh.get_aabb()
		var pick: Array = _material_for(box, top, bottom)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in m.mesh.get_surface_count():
			st.append_from(m.mesh, s, to_vehicle * xf)
		st.generate_normals()
		var mesh := st.commit()
		mesh.surface_set_material(0, pick[1])
		var idx := String(m.name).get_slice("_", 2).to_int()
		var out := MeshInstance3D.new()
		out.name = "%s_%d" % [pick[0], idx]
		out.mesh = save.call(mesh, "engine_i6_part_%d" % idx)
		root.add_child(out)
		counts[pick[0]] = counts.get(pick[0], 0) + 1
	bounds = AABB(to_vehicle * total.position, Vector3.ZERO).expand(to_vehicle * total.end)
	print("  engine_i6 parts by role: ", counts, " size(m)=", bounds.size.snapped(Vector3.ONE * 0.01))
	src.free()
	return root
