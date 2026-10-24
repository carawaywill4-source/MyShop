extends RefCounted
## Authors the Kessler GT6: an original fictional high-performance sport sedan whose
## proportions follow current German super-sedans (G80-class): 4.79 m long, 1.90 m wide,
## 1.43 m tall, 2.86 m wheelbase, 275/35R19 tyres. No real names, logos, or twin-kidney
## grille; the face is MyShop's own wide hex-mesh grille.
## Vehicle space: +Z forward, +X the car's left, Y=0 the ground.

const Forge := preload("res://scripts/authoring/mesh_forge.gd")
const InteractableScript := preload("res://scripts/interactable.gd")

const LENGTH_FRONT := 2.32
const LENGTH_REAR := -2.47
const AXLE_FRONT := 1.40
const AXLE_REAR := -1.46
const TRACK_HALF := 0.80
const WHEEL_RADIUS := 0.345
const TYRE_HALF_WIDTH := 0.1375
const RIM_RADIUS := 0.243
const ARCH_RADIUS := 0.385
const COWL_Z := 0.90
const HOOD_FRONT_Z := 2.12
const ROOF_FRONT_Z := -0.16
const ROOF_REAR_Z := -0.88
const DECK_Z := -1.66
const ROOF_Y := 1.415
## Floor / pinch-weld height. The lift pads touch here.
const SILL_Y := 0.15
const BAY_OPEN_FRONT := 2.05

var M: Dictionary
var save: Callable


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save = mesh_saver


# ------------------------------------------------------------------ shape functions

static func _bump(d: float, s: float) -> float:
	return exp(-(d / s) * (d / s))


static func half_width(z: float) -> float:
	var w := 0.905 + 0.035 * _bump(z - AXLE_FRONT, 0.42) + 0.045 * _bump(z - AXLE_REAR, 0.46)
	if z > 1.95:
		w -= 0.075 * pow((z - 1.95) / (LENGTH_FRONT - 1.95), 2.6)
	elif z < -2.05:
		w -= 0.06 * pow((-2.05 - z) / (-2.05 - LENGTH_REAR), 2.2)
	return w


static func bottom_y(z: float) -> float:
	var b := SILL_Y
	if z > 2.0:
		b += 0.06 * smoothstep(2.0, LENGTH_FRONT, z)
	elif z < -2.12:
		b += 0.14 * smoothstep(-2.12, LENGTH_REAR, z)
	return b


static func top_y(z: float) -> float:
	if z > HOOD_FRONT_Z:
		var t := (z - HOOD_FRONT_Z) / (LENGTH_FRONT - HOOD_FRONT_Z)
		return lerpf(0.775, 0.665, pow(t, 1.6))
	if z > COWL_Z:
		var t2 := (z - COWL_Z) / (HOOD_FRONT_Z - COWL_Z)
		return lerpf(0.95, 0.775, pow(t2, 1.2))
	if z > -1.55:
		# Rising wedge beltline.
		return lerpf(1.005, 0.95, (z + 1.55) / (COWL_Z + 1.55))
	if z > -2.30:
		return lerpf(1.035, 1.005, (z + 2.30) / 0.75)
	var r := (-2.30 - z) / (-2.30 - LENGTH_REAR)
	return lerpf(1.035, 0.82, pow(r, 1.4))


static func roof_y(z: float) -> float:
	if z >= COWL_Z:
		return top_y(z)
	if z > ROOF_FRONT_Z:
		var t := (z - ROOF_FRONT_Z) / (COWL_Z - ROOF_FRONT_Z)
		return lerpf(ROOF_Y - 0.02, top_y(z), pow(t, 0.8))
	if z > ROOF_REAR_Z:
		var mid := (ROOF_FRONT_Z + ROOF_REAR_Z) * 0.5
		return ROOF_Y + 0.028 * (1.0 - pow((z - mid) / ((ROOF_FRONT_Z - ROOF_REAR_Z) * 0.5), 2.0))
	if z > DECK_Z:
		# Fastback: long shallow rear screen.
		var t2 := (ROOF_REAR_Z - z) / (ROOF_REAR_Z - DECK_Z)
		return lerpf(ROOF_Y - 0.02, top_y(z), pow(t2, 1.15))
	return top_y(z)


static func arch_y(z: float) -> float:
	var best := -1.0
	for axle in [AXLE_FRONT, AXLE_REAR]:
		var d := absf(z - axle)
		if d < ARCH_RADIUS:
			best = maxf(best, WHEEL_RADIUS + sqrt(ARCH_RADIUS * ARCH_RADIUS - d * d))
	return best


static func swage_y(z: float) -> float:
	return lerpf(0.56, 0.47, clampf((z - LENGTH_REAR) / (LENGTH_FRONT - LENGTH_REAR), 0.0, 1.0))


static func z_samples() -> PackedFloat32Array:
	var zs := PackedFloat32Array()
	var z := LENGTH_REAR
	while z < LENGTH_FRONT - 0.001:
		zs.append(z)
		var near_axle := absf(z - AXLE_FRONT) < 0.48 or absf(z - AXLE_REAR) < 0.48
		var near_end := z > 2.0 or z < -2.15
		z += 0.03 if near_axle else (0.035 if near_end else 0.06)
	zs.append(LENGTH_FRONT)
	for key in [COWL_Z, HOOD_FRONT_Z, DECK_Z, BAY_OPEN_FRONT]:
		var found := false
		for v in zs:
			if absf(v - key) < 0.004:
				found = true
		if not found:
			zs.append(key)
	zs.sort()
	return zs


## Half cross-section of the lower body, bottom centre -> top centre (15 points).
## Index map: 4-5 side skirt, 7 swage crease, 9 shoulder crease, 11 hood cut line, 13 power dome.
static func body_half_profile(z: float) -> PackedVector3Array:
	var w := half_width(z)
	var b := bottom_y(z)
	var t := top_y(z)
	var shoulder := t - 0.115
	var swage := minf(swage_y(z), shoulder - 0.06)
	var arch := arch_y(z)
	var raised := b if arch < 0.0 else arch
	var rocker := b + 0.12
	var ys := [b, b, raised, raised, maxf(raised, b) + 0.025, maxf(rocker, raised + 0.05),
		maxf(lerpf(rocker, swage, 0.5), raised + 0.075), maxf(swage, raised + 0.095),
		lerpf(swage, shoulder, 0.55), shoulder, t - 0.05, t - 0.01, t + 0.012, t + 0.032, t + 0.042]
	# Keep the section ordered bottom-to-top; above the arches the creases compress into a lip.
	for i in range(4, 10):
		ys[i] = maxf(ys[i], ys[i - 1] + 0.004)
	for i in range(8, 1, -1):
		ys[i] = minf(ys[i], ys[i + 1] - 0.004)
	var xs := [0.0, 0.62, 0.64, w - 0.12, w - 0.04, w - 0.02, w - 0.006, w + 0.004,
		w + 0.012, w + 0.014, w - 0.022, w - 0.075, 0.42, 0.27, 0.0]
	var p := PackedVector3Array()
	for i in xs.size():
		p.append(Vector3(xs[i], ys[i], z))
	return p


static func _h(i: int) -> int:
	return i if i < 14 else 27 - i


# ------------------------------------------------------------------ body

func _body_meshes() -> Dictionary:
	var out := {}
	var zs := z_samples()
	var sections := []
	for z in zs:
		sections.append(Forge.mirror_profile(body_half_profile(z)))
	var paint: Material = M["sedan_paint"]
	var classify := func(i: int, j: int) -> int:
		var h := _h(i)
		var zmid: float = (zs[j] + zs[j + 1]) * 0.5
		if h == 0:
			return -1 if (zmid > COWL_Z and zmid < BAY_OPEN_FRONT) else 1
		if h <= 2:
			return 1
		if h == 4:
			return 2
		if h >= 11:
			if zmid > COWL_Z + 0.004 and zmid < HOOD_FRONT_Z:
				return -1
			if zmid < COWL_Z and zmid > DECK_Z:
				return -1
		return 0
	var smooth := func(i: int) -> int:
		return [2, 2, 2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9][_h(i)]
	out["shell"] = Forge.loft(sections, [paint, M["underbody"], M["piano_black"]], classify, true, smooth)
	var hood_sections := []
	for z in zs:
		if z >= COWL_Z - 0.001 and z <= HOOD_FRONT_Z + 0.001:
			hood_sections.append(Forge.mirror_profile(body_half_profile(z)))
	var hood_classify := func(i: int, _j: int) -> int:
		return 0 if _h(i) >= 11 else -1
	var hood_smooth := func(i: int) -> int:
		return 8 if _h(i) <= 12 else 9
	out["hood"] = Forge.loft(hood_sections, [paint], hood_classify, true, hood_smooth)
	var inner := []
	for s in hood_sections:
		var moved := PackedVector3Array()
		for v in s:
			moved.append(v + Vector3(0, -0.03, 0))
		inner.append(moved)
	out["hood_inner"] = Forge.loft(inner, [M["car_paint_inner"]], hood_classify, true)
	out["nose_cap"] = _cap(Forge.mirror_profile(body_half_profile(LENGTH_FRONT)), paint, true)
	out["tail_cap"] = _cap(Forge.mirror_profile(body_half_profile(LENGTH_REAR)), paint, false)
	out["greenhouse"] = _greenhouse(zs)
	return out


func _cap(loop: PackedVector3Array, mat: Material, front: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3.ZERO
	for v in loop:
		c += v
	c /= loop.size()
	for i in loop.size():
		var a := loop[i]
		var b := loop[(i + 1) % loop.size()]
		if front:
			st.add_vertex(c); st.add_vertex(b); st.add_vertex(a)
		else:
			st.add_vertex(c); st.add_vertex(a); st.add_vertex(b)
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	return mesh


func _greenhouse(zs: PackedFloat32Array) -> ArrayMesh:
	var gz := []
	for z in zs:
		if z <= COWL_Z + 0.001 and z >= DECK_Z - 0.001:
			gz.append(z)
	var sections := []
	for z in gz:
		var t := top_y(z)
		var h := maxf(roof_y(z) - t, 0.0)
		var wb := half_width(z) - 0.075
		var wr := wb - 0.25
		var g1 := Vector3(wb - 0.012, t + minf(0.04, h * 0.2), z)
		var g4 := Vector3(wr + 0.04, t + h * 0.90, z)
		var half := PackedVector3Array([Vector3(wb, t - 0.012, z), g1])
		for f in [0.33, 0.66]:
			var p := g1.lerp(g4, f)
			p.x += 0.012 * sin(f * PI)
			half.append(p)
		half.append(g4)
		half.append(Vector3(wr - 0.005, t + h - 0.003, z))
		half.append(Vector3(wr * 0.55, t + h + 0.02, z))
		half.append(Vector3(0.0, t + h + 0.027, z))
		var full := PackedVector3Array(half)
		for i in range(half.size() - 2, -1, -1):
			var q := half[i]
			full.append(Vector3(-q.x, q.y, q.z))
		sections.append(full)
	# Side-window rear limits per glass band give the C-pillar its forward kink at the base.
	var rear_limit := [0.0, -1.18, -1.30, -1.20]
	var classify := func(i: int, j: int) -> int:
		var h := i if i < 7 else 13 - i
		var zmid: float = (gz[j] + gz[j + 1]) * 0.5
		var roof_zone := zmid < ROOF_FRONT_Z and zmid > ROOF_REAR_Z
		if h == 0:
			return 2
		if h <= 3:
			if zmid > 0.70 and h == 1:
				return 2
			if zmid < -0.30 and zmid > -0.42:
				return 2
			if zmid < rear_limit[h]:
				return 0
			return 1
		if h == 4:
			return 2 if (zmid > ROOF_REAR_Z - 0.25) else 0
		return 3 if roof_zone else 1
	return Forge.loft(sections, [M["sedan_paint"], M["car_glass"], M["piano_black"], M["carbon_roof"]], classify, false)


# ------------------------------------------------------------------ details

func _poly_mesh(points: PackedVector2Array, depth: float, mat: Material) -> ArrayMesh:
	return Forge.extrude(points, depth, mat)


func _mirror_x(points: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(points.size() - 1, -1, -1):
		out.append(Vector2(-points[i].x, points[i].y))
	return out


func _headlight_shape() -> PackedVector2Array:
	# Slim angular lamp; outer end high and pointed, inner end dropping toward the grille.
	return PackedVector2Array([
		Vector2(-0.185, -0.012), Vector2(-0.165, 0.028), Vector2(0.10, 0.048),
		Vector2(0.19, 0.030), Vector2(0.205, 0.004), Vector2(0.15, -0.030), Vector2(-0.14, -0.040),
	])


func _taillight_shape() -> PackedVector2Array:
	# L-shaped lamp seen from behind for the car's right side: bar inboard, drop at the corner.
	return PackedVector2Array([
		Vector2(0.34, 0.040), Vector2(0.80, 0.050), Vector2(0.835, 0.020), Vector2(0.82, -0.085),
		Vector2(0.785, -0.095), Vector2(0.76, -0.020), Vector2(0.36, -0.012),
	])


func _scale_poly(points: PackedVector2Array, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points:
		out.append(p * s)
	return out


func _mi(parent: Node3D, name: String, mesh: Mesh, pos := Vector3.ZERO, basis := Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	parent.add_child(mi)
	return mi


func _group(parent: Node3D, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	return n


func _s(mesh: ArrayMesh, name: String) -> Mesh:
	return save.call(mesh, "gt6_" + name)


func assemble(car: Node3D) -> void:
	var body_meshes := _body_meshes()
	var body := _group(car, "Body")
	_mi(body, "Shell", _s(body_meshes["shell"], "shell"))
	_mi(body, "Greenhouse", _s(body_meshes["greenhouse"], "greenhouse"))
	_mi(body, "NoseCap", _s(body_meshes["nose_cap"], "nose_cap"))
	_mi(body, "TailCap", _s(body_meshes["tail_cap"], "tail_cap"))
	_hood(body, body_meshes)
	_front_fascia(body)
	_rear_fascia(body)
	_side_details(body)
	_wheels(car)
	_interior(car)
	_underbody(car)
	_bay_structure(car)


func _hood(body: Node3D, meshes: Dictionary) -> void:
	var hinge := Vector3(0, top_y(COWL_Z) + 0.04, COWL_Z)
	var pivot := _group(body, "HoodPivot")
	pivot.position = hinge
	var hood := StaticBody3D.new()
	hood.name = "Hood"
	hood.set_script(InteractableScript)
	hood.set("part_id", "hood")
	hood.set("display_name", "Hood")
	hood.position = -hinge
	pivot.add_child(hood)
	_mi(hood, "HoodPanel", _s(meshes["hood"], "hood"))
	_mi(hood, "HoodInner", _s(meshes["hood_inner"], "hood_inner"))
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var box := BoxShape3D.new()
	var mid := (COWL_Z + HOOD_FRONT_Z) * 0.5
	box.size = Vector3(1.7, 0.16, HOOD_FRONT_Z - COWL_Z)
	shape.shape = box
	shape.position = Vector3(0, top_y(mid) + 0.03, mid)
	hood.add_child(shape)


func _front_fascia(body: Node3D) -> void:
	var f := _group(body, "FrontFascia")
	var zf := LENGTH_FRONT
	var black: Material = M["piano_black"]
	var mesh_mat: Material = M["grille_mesh"]
	# MyShop's own face: one wide hexagonal-mesh grille, not split kidneys.
	var grille := PackedVector2Array([Vector2(-0.31, 0.085), Vector2(0.31, 0.085), Vector2(0.36, 0.02), Vector2(0.34, -0.075), Vector2(-0.34, -0.075), Vector2(-0.36, 0.02)])
	_mi(f, "GrilleFrame", _s(_poly_mesh(grille, 0.03, black), "grille_frame"), Vector3(0, 0.505, zf + 0.004))
	_mi(f, "GrilleMesh", _s(_poly_mesh(_scale_poly(grille, 0.93), 0.01, mesh_mat), "grille_mesh"), Vector3(0, 0.505, zf + 0.022))
	_mi(f, "GrilleBar", _s(Forge.beveled_box(Vector3(0.66, 0.012, 0.01), 0.004, M["trim_chrome"]), "grille_bar"), Vector3(0, 0.50, zf + 0.026))
	for side in [1.0, -1.0]:
		var tag := "l" if side > 0.0 else "r"
		var intake := PackedVector2Array([Vector2(-0.10, 0.12), Vector2(0.09, 0.10), Vector2(0.13, -0.10), Vector2(-0.07, -0.12), Vector2(-0.12, -0.04)])
		var shape := intake if side > 0.0 else _mirror_x(intake)
		_mi(f, "SideIntake", _s(_poly_mesh(shape, 0.03, black), "side_intake_" + tag), Vector3(0.60 * side, 0.335, zf - 0.004))
		_mi(f, "SideIntakeMesh", _s(_poly_mesh(_scale_poly(shape, 0.86), 0.01, mesh_mat), "side_intake_mesh_" + tag), Vector3(0.60 * side, 0.335, zf + 0.012))
		var lamp := _headlight_shape() if side > 0.0 else _mirror_x(_headlight_shape())
		var yaw := Basis(Vector3.UP, 0.32 * side) * Basis(Vector3.RIGHT, -0.18)
		var hpos := Vector3(0.58 * side, 0.625, zf - 0.035)
		_mi(f, "HeadlightHousing", _s(_poly_mesh(_scale_poly(lamp, 1.04), 0.06, M["trim_black"]), "headlight_housing_" + tag), hpos, yaw)
		_mi(f, "HeadlightLens", _s(_poly_mesh(lamp, 0.012, M["headlight_lens"]), "headlight_lens_" + tag), hpos + yaw * Vector3(0, 0, 0.034), yaw)
		var drl := PackedVector3Array([Vector3(-0.15 * side, -0.02, 0), Vector3(0.12 * side, 0.0, 0), Vector3(0.17 * side, 0.02, 0)])
		_mi(f, "DaytimeRunningLight", _s(Forge.tube(drl, 0.006, M["drl"], 6, 4), "drl_" + tag), hpos + yaw * Vector3(0, 0, 0.028), yaw)
		_mi(f, "Projector", _s(Forge.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.024, 0.0), Vector2(0.026, 0.01), Vector2(0.0, 0.016)]), 16, M["trim_chrome"]), "projector"), hpos + yaw * Vector3(0.05 * side, -0.012, 0.022), yaw * Basis(Vector3.RIGHT, PI * 0.5))
	_mi(f, "LowerIntake", _s(_poly_mesh(PackedVector2Array([Vector2(-0.36, 0.035), Vector2(0.36, 0.035), Vector2(0.33, -0.035), Vector2(-0.33, -0.035)]), 0.03, black), "lower_intake"), Vector3(0, 0.27, zf - 0.006))
	_mi(f, "Splitter", _s(Forge.beveled_box(Vector3(1.64, 0.018, 0.14), 0.008, M["carbon_roof"]), "splitter"), Vector3(0, 0.205, zf - 0.01))
	_mi(f, "FrontPlate", _s(Forge.beveled_box(Vector3(0.52, 0.11, 0.01), 0.008, M["plate"]), "plate"), Vector3(0, 0.36, zf + 0.012))


func _rear_fascia(body: Node3D) -> void:
	var r := _group(body, "RearFascia")
	var zr := LENGTH_REAR
	var back := Basis(Vector3.UP, PI)
	for side in [1.0, -1.0]:
		var tag := "l" if side > 0.0 else "r"
		# Rotating 180 degrees about Y mirrors X, so the left lamp uses the mirrored shape.
		var shape := _mirror_x(_taillight_shape()) if side > 0.0 else _taillight_shape()
		_mi(r, "TaillightHousing", _s(_poly_mesh(shape, 0.05, M["trim_black"]), "tail_housing_" + tag), Vector3(0, 0.905, zr + 0.02), back)
		_mi(r, "TaillightLens", _s(_poly_mesh(_scale_poly(shape, 0.985), 0.012, M["taillight_lens"]), "tail_lens_" + tag), Vector3(0, 0.905, zr - 0.006), back)
		var wrap := PackedVector2Array([Vector2(-0.16, 0.035), Vector2(0.0, 0.045), Vector2(0.02, -0.03), Vector2(-0.14, -0.02)])
		_mi(r, "TaillightWrap", _s(_poly_mesh(wrap if side > 0.0 else _mirror_x(wrap), 0.01, M["taillight_lens"]), "tail_wrap_" + tag), Vector3((half_width(-2.30) - 0.005) * side, 0.90, -2.30), Basis(Vector3.UP, PI * 0.5 * side))
		for k in 2:
			var x: float = (0.40 + 0.115 * k) * side
			_mi(r, "ExhaustTip", _s(Forge.lathe(PackedVector2Array([Vector2(0.042, -0.06), Vector2(0.046, 0.05), Vector2(0.040, 0.055), Vector2(0.036, 0.0)]), 20, M["exhaust_tip"], false, false), "exhaust_tip"), Vector3(x, 0.255, zr - 0.06), Basis(Vector3.RIGHT, -PI * 0.5))
	_mi(r, "Diffuser", _s(Forge.beveled_box(Vector3(1.30, 0.05, 0.22), 0.015, M["carbon_roof"]), "diffuser"), Vector3(0, 0.30, zr + 0.08))
	for k in 5:
		_mi(r, "DiffuserFin", _s(Forge.beveled_box(Vector3(0.012, 0.09, 0.22), 0.004, M["carbon_roof"]), "diffuser_fin"), Vector3(-0.24 + k * 0.12, 0.26, zr + 0.06))
	_mi(r, "TrunkLip", _s(_poly_mesh(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.09, 0.0), Vector2(0.11, 0.025), Vector2(0.0, 0.012)]), 1.30, M["carbon_roof"]), "trunk_lip"), Vector3(0, top_y(-2.33) + 0.03, -2.36), Basis(Vector3.UP, -PI * 0.5))
	_mi(r, "RearPlate", _s(Forge.beveled_box(Vector3(0.52, 0.11, 0.01), 0.008, M["plate"]), "plate"), Vector3(0, 0.64, zr - 0.012))
	var badge := Label3D.new()
	badge.name = "ModelScript"
	badge.text = "GT6"
	badge.font_size = 30
	badge.pixel_size = 0.0016
	badge.position = Vector3(-0.42, 0.80, zr - 0.012)
	badge.rotation_degrees.y = 180.0
	badge.modulate = Color(0.78, 0.80, 0.82)
	r.add_child(badge)


func _side_details(body: Node3D) -> void:
	var s := _group(body, "SideDetails")
	for side in [1.0, -1.0]:
		var tag := "l" if side > 0.0 else "r"
		# Aero mirror: body-colour cap on a black base and two stalks.
		var mpos := Vector3(1.0 * side, 1.03, 0.68)
		_mi(s, "MirrorCap", _s(_ellipsoid(Vector3(0.12, 0.052, 0.07), M["sedan_paint"]), "mirror_cap"), mpos, Basis(Vector3.UP, 0.12 * side))
		_mi(s, "MirrorBase", _s(_ellipsoid(Vector3(0.105, 0.045, 0.04), M["piano_black"]), "mirror_base"), mpos + Vector3(0, -0.012, -0.04))
		for k in 2:
			var a := Vector3(0.87 * side, 1.0, 0.72 - 0.07 * k)
			_mi(s, "MirrorStalk", _s(Forge.tube(PackedVector3Array([a, a.lerp(mpos, 0.5) + Vector3(0, 0.015, 0), mpos - Vector3(0.04 * side, 0, 0)]), 0.008, M["piano_black"], 6, 3), "mirror_stalk_%s_%d" % [tag, k]))
		# Fender gill behind the front wheel.
		var gill := PackedVector2Array([Vector2(-0.07, 0.03), Vector2(0.07, 0.022), Vector2(0.06, -0.025), Vector2(-0.075, -0.018)])
		var gz := AXLE_FRONT - ARCH_RADIUS - 0.10
		var gp := body_half_profile(gz)
		_mi(s, "FenderVent", _s(_poly_mesh(gill if side > 0.0 else _mirror_x(gill), 0.012, M["piano_black"]), "fender_vent_" + tag), Vector3((gp[8].x + 0.004) * side, 0.66, gz), Basis(Vector3.UP, PI * 0.5 * side))
		for z in [0.08, -0.88]:
			var hp := body_half_profile(z)
			_mi(s, "DoorHandle", _s(Forge.beveled_box(Vector3(0.008, 0.02, 0.15), 0.006, M["piano_black"]), "door_handle"), Vector3((hp[9].x + 0.002) * side, hp[9].y - 0.03, z))
		for k in 3:
			var sz: float = [AXLE_FRONT - ARCH_RADIUS - 0.02, -0.36, AXLE_REAR + ARCH_RADIUS + 0.02][k]
			var p := body_half_profile(sz)
			var pts := PackedVector3Array()
			for i in [5, 6, 7, 8, 9, 10]:
				pts.append(Vector3((p[i].x + 0.003) * side, p[i].y, sz))
			_mi(s, "DoorSeam", _s(Forge.tube(pts, 0.0032, M["trim_black"], 5, 4), "door_seam_%s_%d" % [tag, k]))


func _ellipsoid(scale: Vector3, mat: Material) -> ArrayMesh:
	var profile := PackedVector2Array()
	for i in 11:
		var a := -PI * 0.5 + PI * i / 10.0
		profile.append(Vector2(cos(a), sin(a)))
	var m := Forge.lathe(profile, 22, null, false, false)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(m, 0, Transform3D(Basis.from_scale(scale), Vector3.ZERO))
	st.generate_normals()
	var outm := st.commit()
	outm.surface_set_material(0, mat)
	return outm


func _wheels(car: Node3D) -> void:
	# Wheel meshes are authored around the Y axle with +Y outboard, then rotated per side.
	var tread := PackedVector2Array([Vector2(RIM_RADIUS + 0.004, -0.122), Vector2(0.285, -TYRE_HALF_WIDTH), Vector2(0.325, -0.133),
		Vector2(0.342, -0.115), Vector2(0.345, -0.085), Vector2(0.339, -0.075), Vector2(0.345, -0.065),
		Vector2(0.345, -0.025), Vector2(0.339, -0.015), Vector2(0.345, -0.005), Vector2(0.345, 0.035),
		Vector2(0.339, 0.045), Vector2(0.345, 0.055), Vector2(0.345, 0.085), Vector2(0.342, 0.115),
		Vector2(0.325, 0.133), Vector2(0.285, TYRE_HALF_WIDTH), Vector2(RIM_RADIUS + 0.004, 0.122)])
	var tyre := _s(Forge.lathe(tread, 48, M["tyre_rubber"], false, false), "tyre")
	var barrel := _s(Forge.lathe(PackedVector2Array([Vector2(0.232, -0.125), Vector2(0.244, -0.12), Vector2(0.236, -0.105),
		Vector2(0.224, -0.06), Vector2(0.224, 0.07), Vector2(0.238, 0.105), Vector2(RIM_RADIUS + 0.004, 0.118), Vector2(0.236, 0.124), Vector2(0.226, 0.118)]), 48, M["wheel_machined"], false, false), "rim_barrel")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(Forge.lathe(PackedVector2Array([Vector2(0.075, 0.07), Vector2(0.072, 0.098), Vector2(0.045, 0.106), Vector2(0.0, 0.108)]), 24, null, true, false), 0, Transform3D.IDENTITY)
	var spoke := Forge.extrude(PackedVector2Array([Vector2(-0.016, 0.0), Vector2(0.016, 0.0), Vector2(0.010, 0.165), Vector2(-0.010, 0.165)]), 0.028, null)
	for k in 5:
		for pair in [-0.17, 0.17]:
			var ang: float = TAU * k / 5.0 + pair
			# Spokes dish outward from a recessed hub to the rim lip.
			var radial := Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.12), Vector3(0, 0.088, 0.068))
			st.append_from(spoke, 0, Transform3D(Basis(Vector3.UP, ang), Vector3.ZERO) * radial)
	st.generate_normals()
	var face := st.commit()
	face.surface_set_material(0, M["wheel_dark"])
	var face_mesh := _s(face, "rim_face")
	var nut := _s(Forge.lathe(PackedVector2Array([Vector2(0.011, 0.0), Vector2(0.011, 0.014), Vector2(0.0, 0.016)]), 6, M["trim_chrome"]), "lug_nut")
	var disc := _s(Forge.lathe(PackedVector2Array([Vector2(0.09, -0.016), Vector2(0.19, -0.016), Vector2(0.19, 0.016), Vector2(0.09, 0.016)]), 40, M["brake_disc"]), "brake_disc")
	var hat := _s(Forge.lathe(PackedVector2Array([Vector2(0.09, -0.02), Vector2(0.09, 0.03), Vector2(0.0, 0.035)]), 24, M["graphite_steel"]), "brake_hat")
	var caliper := _s(Forge.beveled_box(Vector3(0.20, 0.10, 0.075), 0.03, M["brake_caliper"]), "brake_caliper")
	var wheels := _group(car, "Wheels")
	for def in [["FrontLeft", 1.0, AXLE_FRONT], ["FrontRight", -1.0, AXLE_FRONT], ["RearLeft", 1.0, AXLE_REAR], ["RearRight", -1.0, AXLE_REAR]]:
		var side: float = def[1]
		var wheel := _group(wheels, def[0])
		wheel.position = Vector3(TRACK_HALF * side, WHEEL_RADIUS, def[2])
		var out_basis := Basis(Vector3.FORWARD, PI * 0.5 * side)
		_mi(wheel, "Tyre", tyre, Vector3.ZERO, out_basis)
		_mi(wheel, "RimBarrel", barrel, Vector3.ZERO, out_basis)
		_mi(wheel, "RimFace", face_mesh, Vector3.ZERO, out_basis)
		for k in 5:
			var a := TAU * (k + 0.5) / 5.0
			_mi(wheel, "LugNut", nut, out_basis * Vector3(cos(a) * 0.05, 0.098, sin(a) * 0.05), out_basis)
		_mi(wheel, "BrakeDisc", disc, out_basis * Vector3(0, -0.03, 0), out_basis)
		_mi(wheel, "BrakeHat", hat, out_basis * Vector3(0, -0.03, 0), out_basis)
		var behind := -1.0 if def[2] > 0.0 else 1.0
		_mi(wheel, "Caliper", caliper, Vector3(-0.045 * side, 0.10, 0.11 * behind), Basis(Vector3.RIGHT, 0.6 * behind) * Basis(Vector3.UP, PI * 0.5))


func _interior(car: Node3D) -> void:
	var i := _group(car, "Interior")
	var fabric: Material = M["interior_fabric"]
	var plastic: Material = M["interior_plastic"]
	var cushion := _s(Forge.beveled_box(Vector3(0.50, 0.12, 0.52), 0.05, fabric), "seat_cushion")
	var back := _s(Forge.beveled_box(Vector3(0.50, 0.66, 0.12), 0.06, fabric), "seat_back")
	var bolster := _s(Forge.beveled_box(Vector3(0.07, 0.50, 0.16), 0.03, fabric), "seat_bolster")
	for side in [1.0, -1.0]:
		_mi(i, "FrontSeat", cushion, Vector3(0.38 * side, 0.32, -0.32))
		_mi(i, "FrontSeatBack", back, Vector3(0.38 * side, 0.70, -0.60), Basis(Vector3.RIGHT, -0.22))
		for b in [-1.0, 1.0]:
			_mi(i, "Bolster", bolster, Vector3(0.38 * side + 0.22 * b, 0.70, -0.57), Basis(Vector3.RIGHT, -0.22))
	_mi(i, "RearBench", _s(Forge.beveled_box(Vector3(1.36, 0.14, 0.52), 0.05, fabric), "rear_bench"), Vector3(0, 0.33, -1.20))
	_mi(i, "RearBenchBack", _s(Forge.beveled_box(Vector3(1.36, 0.58, 0.12), 0.05, fabric), "rear_back"), Vector3(0, 0.68, -1.47), Basis(Vector3.RIGHT, -0.30))
	_mi(i, "Dashboard", _s(Forge.beveled_box(Vector3(1.60, 0.20, 0.46), 0.08, plastic), "dashboard"), Vector3(0, 0.84, 0.62))
	_mi(i, "CenterScreen", _s(Forge.beveled_box(Vector3(0.40, 0.14, 0.012), 0.01, M["piano_black"]), "screen"), Vector3(0.05, 0.99, 0.46), Basis(Vector3.RIGHT, -0.35))
	var ring := PackedVector2Array()
	for k in 13:
		var a := TAU * k / 12.0
		ring.append(Vector2(0.18 + cos(a) * 0.018, sin(a) * 0.018))
	_mi(i, "SteeringWheel", _s(Forge.lathe(ring, 28, plastic, false, false), "steering_wheel"), Vector3(0.38, 0.92, 0.30), Basis(Vector3.RIGHT, PI * 0.5 - 0.42))
	_mi(i, "CenterConsole", _s(Forge.beveled_box(Vector3(0.22, 0.22, 0.90), 0.04, plastic), "console"), Vector3(0, 0.36, 0.0))


func _underbody(car: Node3D) -> void:
	var u := _group(car, "Underbody")
	var steel: Material = M["cast_iron"]
	for side in [1.0, -1.0]:
		var tag := "l" if side > 0.0 else "r"
		var pipe := PackedVector3Array([Vector3(0.08 * side, 0.30, 1.15), Vector3(0.14 * side, 0.18, 0.80), Vector3(0.20 * side, 0.15, 0.0),
			Vector3(0.22 * side, 0.15, -1.20), Vector3(0.30 * side, 0.20, -2.05), Vector3(0.40 * side, 0.235, -2.25), Vector3(0.46 * side, 0.245, -2.42)])
		_mi(u, "ExhaustPipe", _s(Forge.tube(pipe, 0.03, M["bare_steel"], 10, 6), "exhaust_" + tag))
		_mi(u, "RearSilencer", _s(_ellipsoid(Vector3(0.20, 0.09, 0.16), M["bare_steel"]), "silencer"), Vector3(0.40 * side, 0.23, -2.18))
		_mi(u, "FrontControlArm", _s(Forge.beveled_box(Vector3(0.45, 0.035, 0.07), 0.015, steel), "control_arm"), Vector3(0.52 * side, 0.22, AXLE_FRONT - 0.10), Basis(Vector3.UP, 0.40 * side))
		_mi(u, "RearHalfShaft", _s(Forge.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0.62, 0, 0)]), 0.02, steel, 8, 1), "half_shaft"), Vector3(0.12 if side > 0.0 else -0.74, WHEEL_RADIUS - 0.02, AXLE_REAR))
		_mi(u, "RearSpring", _s(_helix(), "coil_spring"), Vector3(0.58 * side, 0.20, AXLE_REAR - 0.10))
		_mi(u, "FrontStrut", _s(Forge.lathe(PackedVector2Array([Vector2(0.026, 0.0), Vector2(0.026, 0.34), Vector2(0.013, 0.35), Vector2(0.013, 0.48)]), 12, M["graphite_steel"]), "damper"), Vector3(0.66 * side, 0.30, AXLE_FRONT))
	_mi(u, "PropShaft", _s(Forge.tube(PackedVector3Array([Vector3(0, 0.25, 0.85), Vector3(0, 0.23, -0.3), Vector3(0, 0.26, -1.40)]), 0.035, steel, 10, 4), "prop_shaft"))
	_mi(u, "RearDifferential", _s(_ellipsoid(Vector3(0.16, 0.12, 0.16), M["cast_aluminum"]), "differential"), Vector3(0, 0.30, AXLE_REAR))
	_mi(u, "FuelTank", _s(Forge.beveled_box(Vector3(0.90, 0.17, 0.56), 0.06, M["underbody"]), "fuel_tank"), Vector3(0, 0.18, -1.02))
	_mi(u, "FrontSubframe", _s(Forge.beveled_box(Vector3(1.22, 0.07, 0.11), 0.025, steel), "subframe"), Vector3(0, 0.18, 1.10))
	_mi(u, "RearSubframe", _s(Forge.beveled_box(Vector3(1.24, 0.08, 0.12), 0.025, steel), "rear_subframe"), Vector3(0, 0.24, AXLE_REAR + 0.18))
	_mi(u, "TunnelBrace", _s(Forge.beveled_box(Vector3(0.30, 0.03, 0.80), 0.01, M["cast_aluminum"]), "tunnel_brace"), Vector3(0, 0.155, 0.25))


func _helix() -> ArrayMesh:
	var pts := PackedVector3Array()
	for k in 49:
		var a := TAU * 4.0 * k / 48.0
		pts.append(Vector3(cos(a) * 0.065, 0.012 + 0.25 * k / 48.0, sin(a) * 0.065))
	return Forge.tube(pts, 0.01, M["lift_red"], 6, 1)


func _bay_structure(car: Node3D) -> void:
	var bay := _group(car, "EngineBay")
	var black: Material = M["bay_black"]
	var inner: Material = M["car_paint_inner"]
	var mid := (COWL_Z + HOOD_FRONT_Z) * 0.5
	_mi(bay, "Firewall", _s(Forge.beveled_box(Vector3(1.56, 0.62, 0.03), 0.04, black), "firewall"), Vector3(0, 0.55, COWL_Z - 0.01))
	_mi(bay, "CowlPanel", _s(Forge.beveled_box(Vector3(1.56, 0.03, 0.14), 0.012, black), "cowl_panel"), Vector3(0, top_y(COWL_Z) - 0.03, COWL_Z + 0.06))
	_mi(bay, "CoreSupport", _s(Forge.beveled_box(Vector3(1.50, 0.06, 0.06), 0.02, black), "core_support"), Vector3(0, 0.70, HOOD_FRONT_Z - 0.10))
	for side in [1.0, -1.0]:
		_mi(bay, "InnerApron", _s(Forge.beveled_box(Vector3(0.03, 0.42, HOOD_FRONT_Z - COWL_Z - 0.1), 0.015, inner), "apron"), Vector3(0.70 * side, 0.52, mid))
		_mi(bay, "StrutTower", _s(Forge.lathe(PackedVector2Array([Vector2(0.115, 0.0), Vector2(0.105, 0.22), Vector2(0.075, 0.26), Vector2(0.0, 0.265)]), 20, inner), "strut_tower"), Vector3(0.63 * side, 0.50, AXLE_FRONT))
		_mi(bay, "StrutCap", _s(Forge.lathe(PackedVector2Array([Vector2(0.035, 0.0), Vector2(0.03, 0.03), Vector2(0.0, 0.035)]), 12, M["graphite_steel"]), "strut_cap"), Vector3(0.63 * side, 0.765, AXLE_FRONT))
		_mi(bay, "HoodHinge", _s(Forge.beveled_box(Vector3(0.02, 0.05, 0.14), 0.008, M["graphite_steel"]), "hinge"), Vector3(0.66 * side, top_y(COWL_Z) - 0.01, COWL_Z + 0.06))
	_mi(bay, "StrutBrace", _s(Forge.tube(PackedVector3Array([Vector3(-0.63, 0.80, AXLE_FRONT), Vector3(0, 0.83, AXLE_FRONT - 0.30), Vector3(0.63, 0.80, AXLE_FRONT)]), 0.016, M["cast_aluminum"], 10, 4), "strut_brace"))
	_mi(bay, "BatteryTray", _s(Forge.beveled_box(Vector3(0.30, 0.03, 0.22), 0.01, black), "battery_tray"), Vector3(-0.46, 0.445, 1.55))
