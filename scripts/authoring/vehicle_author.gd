extends RefCounted
## Authors the Harbor Commute: an original fictional compact sedan at real-world scale.
## Length 4.50 m, width 1.78 m, height 1.45 m, wheelbase 2.65 m, 205/55R16-sized tyres.
## Vehicle space: +Z is forward, +X is the car's left, Y=0 is the ground under the tyres.
## The body is a loft of cross-sections, so the silhouette, wheel arches, hood cut line and
## greenhouse are real continuous surfaces rather than stacked boxes.

const Forge := preload("res://scripts/authoring/mesh_forge.gd")

const LENGTH_FRONT := 2.25
const LENGTH_REAR := -2.25
const AXLE_FRONT := 1.325
const AXLE_REAR := -1.325
const TRACK_HALF := 0.765
const WHEEL_RADIUS := 0.325
const ARCH_RADIUS := 0.375
const COWL_Z := 0.98
const HOOD_FRONT_Z := 1.99
const ROOF_FRONT_Z := 0.10
const ROOF_REAR_Z := -0.82
const DECK_Z := -1.42
const ROOF_Y := 1.445
## Floor/pinch weld height. The lift pads touch here.
const SILL_Y := 0.19
const BAY_FLOOR_OPEN := Vector2(1.0, 2.02)
## Door shut lines. The hinge is the forward edge, which is the higher Z.
const FRONT_DOOR_Z := Vector2(-0.20, 0.90)
const REAR_DOOR_Z := Vector2(-0.90, -0.28)

var M: Dictionary
var out: Dictionary = {}


func _init(materials: Dictionary) -> void:
	M = materials


# ---------------------------------------------------------------- body shape functions

static func half_width(z: float) -> float:
	var w := 0.89
	if z > 1.62:
		w -= 0.11 * pow((z - 1.62) / (LENGTH_FRONT - 1.62), 2.2)
	elif z < -1.70:
		w -= 0.08 * pow((-1.70 - z) / (-1.70 - LENGTH_REAR), 2.0)
	return w


static func bottom_y(z: float) -> float:
	var b := SILL_Y
	if z > 1.78:
		b += 0.13 * smoothstep(1.78, LENGTH_FRONT, z)
	elif z < -1.85:
		b += 0.14 * smoothstep(-1.85, LENGTH_REAR, z)
	return b


## Height of the body's upper surface along the centreline (nose, hood, beltline, deck, tail).
static func top_y(z: float) -> float:
	if z > 1.97:
		var t := (z - 1.97) / (LENGTH_FRONT - 1.97)
		return lerpf(0.80, 0.58, pow(t, 1.8))
	if z > COWL_Z:
		return lerpf(0.925, 0.80, (z - COWL_Z) / (1.97 - COWL_Z))
	if z > -1.30:
		return lerpf(0.965, 0.925, (z + 1.30) / (COWL_Z + 1.30))
	if z > -2.02:
		return lerpf(0.985, 0.965, (z + 2.02) / 0.72)
	var r := (-2.02 - z) / (-2.02 - LENGTH_REAR)
	return lerpf(0.985, 0.70, pow(r, 1.6))


static func roof_y(z: float) -> float:
	if z >= COWL_Z:
		return top_y(z)
	if z > ROOF_FRONT_Z:
		var t := (z - ROOF_FRONT_Z) / (COWL_Z - ROOF_FRONT_Z)
		return lerpf(ROOF_Y - 0.01, top_y(z), pow(t, 0.85))
	if z > ROOF_REAR_Z:
		var mid := (ROOF_FRONT_Z + ROOF_REAR_Z) * 0.5
		return ROOF_Y + 0.012 * (1.0 - pow((z - mid) / ((ROOF_FRONT_Z - ROOF_REAR_Z) * 0.5), 2.0))
	if z > DECK_Z:
		var t2 := (ROOF_REAR_Z - z) / (ROOF_REAR_Z - DECK_Z)
		return lerpf(ROOF_Y - 0.01, top_y(z), pow(t2, 1.15))
	return top_y(z)


static func arch_y(z: float) -> float:
	var best := -1.0
	for axle in [AXLE_FRONT, AXLE_REAR]:
		var d := absf(z - axle)
		if d < ARCH_RADIUS:
			best = maxf(best, WHEEL_RADIUS + sqrt(ARCH_RADIUS * ARCH_RADIUS - d * d))
	return best


static func z_samples() -> PackedFloat32Array:
	var zs := PackedFloat32Array()
	var z := LENGTH_REAR
	while z < LENGTH_FRONT - 0.001:
		zs.append(z)
		var step := 0.035 if (absf(z - AXLE_FRONT) < 0.45 or absf(z - AXLE_REAR) < 0.45) else 0.06
		z += step
	zs.append(LENGTH_FRONT)
	for key in [COWL_Z, HOOD_FRONT_Z, DECK_Z]:
		var found := false
		for v in zs:
			if absf(v - key) < 0.004:
				found = true
		if not found:
			zs.append(key)
	zs.sort()
	return zs


## Half cross-section of the lower body, bottom centre -> top centre (11 points).
static func body_half_profile(z: float) -> PackedVector3Array:
	var w := half_width(z)
	var b := bottom_y(z)
	var t := top_y(z)
	var shoulder := t - 0.17
	var arch := arch_y(z)
	var raised := b
	if arch > 0.0:
		raised = minf(arch, shoulder - 0.035)
	var p := PackedVector3Array()
	p.append(Vector3(0.0, b, z))
	p.append(Vector3(0.60, b, z))
	p.append(Vector3(0.62, raised, z))
	p.append(Vector3(w - 0.10, raised, z))
	p.append(Vector3(w - 0.018, maxf(raised, b + 0.05) + 0.035, z))
	p.append(Vector3(w, maxf(lerpf(b, shoulder, 0.42), raised + 0.06), z))
	p.append(Vector3(w + 0.012, shoulder, z))
	p.append(Vector3(w - 0.008, t - 0.06, z))
	p.append(Vector3(w - 0.06, t - 0.012, z))
	p.append(Vector3(w * 0.55, t + 0.022, z))
	p.append(Vector3(0.0, t + 0.032, z))
	return p


# ---------------------------------------------------------------- body meshes

func build_body_meshes() -> void:
	var zs := z_samples()
	var sections := []
	for z in zs:
		sections.append(Forge.mirror_profile(body_half_profile(z)))
	var paint: Material = M["car_paint_harbor_blue"]
	var under: Material = M["underbody"]
	var classify := func(i: int, j: int) -> int:
		var h := i if i < 10 else 19 - i
		var zmid: float = (zs[j] + zs[j + 1]) * 0.5
		var in_bay := zmid > COWL_Z and zmid < BAY_FLOOR_OPEN.y
		if h == 0:
			return -1 if in_bay else 1
		if h <= 2:
			return 1
		if h >= 8:
			if zmid > COWL_Z + 0.005 and zmid < HOOD_FRONT_Z:
				return -1
			if h == 9 and zmid < COWL_Z and zmid > DECK_Z:
				return -1
		if h >= 4 and h <= 7 and _door_band(zmid) != "":
			return -1
		return 0
	var smooth := func(i: int) -> int:
		var h := i if i < 10 else 19 - i
		return 2 if h <= 2 else 1
	out["body"] = Forge.loft(sections, [paint, under], classify, true, smooth)
	_build_door_skins(zs, sections, paint)
	# Hood panel: the top faces between the cowl and the hood's front edge.
	var hood_sections := []
	for z in zs:
		if z >= COWL_Z - 0.001 and z <= HOOD_FRONT_Z + 0.001:
			hood_sections.append(Forge.mirror_profile(body_half_profile(z)))
	var hood_classify := func(i: int, _j: int) -> int:
		var h := i if i < 10 else 19 - i
		return 0 if h >= 8 else -1
	out["hood"] = Forge.loft(hood_sections, [paint], hood_classify, true)
	var inner_sections := []
	for s in hood_sections:
		var moved := PackedVector3Array()
		for v in s:
			moved.append(v + Vector3(0, -0.028, 0))
		inner_sections.append(moved)
	out["hood_inner"] = Forge.loft(inner_sections, [M["car_paint_inner"]], hood_classify, true)
	out["nose_cap"] = _cap(Forge.mirror_profile(body_half_profile(LENGTH_FRONT)), paint)
	out["tail_cap"] = _cap(Forge.mirror_profile(body_half_profile(LENGTH_REAR)), paint)
	build_greenhouse(zs)


func _cap(loop: PackedVector3Array, mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Vector3.ZERO
	for v in loop:
		c += v
	c /= loop.size()
	var front := c.z > 0.0
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


func build_greenhouse(zs: PackedFloat32Array) -> void:
	var gz := []
	for z in zs:
		if z <= COWL_Z + 0.001 and z >= DECK_Z - 0.001:
			gz.append(z)
	var sections := []
	for z in gz:
		var t := top_y(z)
		var h := maxf(roof_y(z) - t, 0.0)
		var wb := half_width(z) - 0.06
		var wr := wb - 0.165
		var half := PackedVector3Array()
		half.append(Vector3(wb, t - 0.012, z))
		half.append(Vector3(wb - 0.012, t + minf(0.055, h * 0.3), z))
		half.append(Vector3(lerpf(wb - 0.012, wr + 0.03, 0.9), t + h * 0.86, z))
		half.append(Vector3(wr - 0.015, t + h - 0.004, z))
		half.append(Vector3(wr * 0.55, t + h + 0.018, z))
		half.append(Vector3(0.0, t + h + 0.024, z))
		var full := PackedVector3Array(half)
		for i in range(half.size() - 2, -1, -1):
			var p := half[i]
			full.append(Vector3(-p.x, p.y, p.z))
		sections.append(full)
	var classify := func(i: int, j: int) -> int:
		var h := i if i < 5 else 9 - i
		var zmid: float = (gz[j] + gz[j + 1]) * 0.5
		var roof_zone := zmid < ROOF_FRONT_Z and zmid > ROOF_REAR_Z
		var b_pillar := zmid < -0.20 and zmid > -0.31
		match h:
			0:
				return 2
			1:
				return 0 if b_pillar else 1
			2:
				return 0
			_:
				return 0 if roof_zone else 1
	var glass_cut := func(i: int, j: int) -> int:
		var zmid: float = (gz[j] + gz[j + 1]) * 0.5
		if _door_band(zmid) == "" or not _is_side_glass(i):
			return -1
		return 0
	# Side glass in the door bands is a separate mesh so it swings with the door.
	var keep_glass := func(i: int, j: int) -> int:
		var surf: int = classify.call(i, j)
		if surf == 1 and glass_cut.call(i, j) == 0:
			return -1
		return surf
	out["greenhouse"] = Forge.loft(sections, [M["car_paint_harbor_blue"], M["car_glass"], M["trim_black"]], keep_glass, false)
	_door_glass(sections, gz, "door_fl_glass", true, FRONT_DOOR_Z)
	_door_glass(sections, gz, "door_fr_glass", false, FRONT_DOOR_Z)
	_door_glass(sections, gz, "door_rl_glass", true, REAR_DOOR_Z)
	_door_glass(sections, gz, "door_rr_glass", false, REAR_DOOR_Z)


static func _door_band(zmid: float) -> String:
	if zmid > FRONT_DOOR_Z.x and zmid < FRONT_DOOR_Z.y:
		return "front"
	if zmid > REAR_DOOR_Z.x and zmid < REAR_DOOR_Z.y:
		return "rear"
	return ""


static func _is_side_glass(segment: int) -> bool:
	return segment == 1 or segment == 8


static func door_hinge(z: float, side: float) -> Vector3:
	var profile := body_half_profile(z)
	return Vector3(profile[6].x * side, profile[6].y, z)


func _build_door_skins(zs: PackedFloat32Array, sections: Array, paint: Material) -> void:
	_door_skin(zs, sections, "door_fl", true, FRONT_DOOR_Z, paint)
	_door_skin(zs, sections, "door_fr", false, FRONT_DOOR_Z, paint)
	_door_skin(zs, sections, "door_rl", true, REAR_DOOR_Z, paint)
	_door_skin(zs, sections, "door_rr", false, REAR_DOOR_Z, paint)
	out["door_card"] = Forge.beveled_box(Vector3(0.02, 0.50, 0.90), 0.008, M["interior_plastic"])


func _door_skin(zs: PackedFloat32Array, sections: Array, key: String, on_left: bool, band: Vector2, paint: Material) -> void:
	var classify := func(i: int, j: int) -> int:
		var zmid: float = (zs[j] + zs[j + 1]) * 0.5
		if zmid <= band.x or zmid >= band.y:
			return -1
		if on_left and i >= 4 and i <= 7:
			return 0
		if not on_left and i >= 12 and i <= 15:
			return 0
		return -1
	out[key] = Forge.loft(sections, [paint], classify, true)


func _door_glass(sections: Array, gz: Array, key: String, on_left: bool, band: Vector2) -> void:
	var classify := func(i: int, j: int) -> int:
		var zmid: float = (gz[j] + gz[j + 1]) * 0.5
		if zmid <= band.x or zmid >= band.y:
			return -1
		if on_left and i == 1:
			return 0
		if not on_left and i == 8:
			return 0
		return -1
	out[key] = Forge.loft(sections, [M["car_glass"]], classify, false)


# ---------------------------------------------------------------- details

func build_wheel_meshes() -> void:
	var alloy: Material = M["wheel_alloy"]
	# Rim in axle-Y space, +Y is the outboard face.
	var barrel := Forge.lathe(PackedVector2Array([
		Vector2(0.196, -0.098), Vector2(0.206, -0.092), Vector2(0.199, -0.082),
		Vector2(0.186, -0.05), Vector2(0.186, 0.05), Vector2(0.199, 0.082),
		Vector2(0.207, 0.094), Vector2(0.200, 0.100), Vector2(0.188, 0.094),
	]), 40, alloy, false, false)
	var hub := Forge.lathe(PackedVector2Array([
		Vector2(0.075, 0.02), Vector2(0.074, 0.07), Vector2(0.062, 0.086), Vector2(0.03, 0.092), Vector2(0.0, 0.093),
	]), 24, alloy, true, false)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(barrel, 0, Transform3D.IDENTITY)
	st.append_from(hub, 0, Transform3D.IDENTITY)
	var spoke := Forge.extrude(PackedVector2Array([
		Vector2(-0.024, 0.0), Vector2(0.024, 0.0), Vector2(0.016, 0.125), Vector2(-0.016, 0.125),
	]), 0.03, alloy)
	for k in 5:
		# Profile Y runs radially (rotated onto +Z), extrusion depth becomes the axle direction.
		var radial := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.074, 0.066))
		st.append_from(spoke, 0, Transform3D(Basis(Vector3.UP, TAU * k / 5.0), Vector3.ZERO) * radial)
	st.generate_normals()
	var rim := st.commit()
	rim.surface_set_material(0, alloy)
	out["rim"] = rim
	out["brake_disc"] = Forge.lathe(PackedVector2Array([
		Vector2(0.07, -0.012), Vector2(0.142, -0.012), Vector2(0.142, 0.012), Vector2(0.07, 0.012),
	]), 32, M["brake_disc"])
	out["caliper"] = Forge.beveled_box(Vector3(0.09, 0.05, 0.06), 0.015, M["brake_caliper"])


func build_lights() -> void:
	out["headlight"] = _lens(Vector3(0.24, 0.062, 0.045), M["headlight_lens"])
	out["taillight"] = _lens(Vector3(0.26, 0.06, 0.035), M["taillight_lens"])
	out["indicator"] = _lens(Vector3(0.06, 0.025, 0.02), M["indicator_lens"])
	out["grille"] = Forge.beveled_box(Vector3(0.86, 0.12, 0.05), 0.04, M["trim_black"])
	out["lower_intake"] = Forge.beveled_box(Vector3(1.10, 0.11, 0.05), 0.045, M["trim_black"])
	out["plate"] = Forge.beveled_box(Vector3(0.52, 0.12, 0.012), 0.01, M["plate"])
	out["mirror"] = _lens(Vector3(0.13, 0.075, 0.09), M["car_paint_harbor_blue"])
	out["mirror_stalk"] = Forge.beveled_box(Vector3(0.09, 0.03, 0.05), 0.012, M["trim_black"])
	out["door_handle"] = Forge.beveled_box(Vector3(0.012, 0.025, 0.16), 0.008, M["trim_chrome"])
	out["wiper"] = Forge.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0.25, 0.012, -0.05), Vector3(0.5, 0.02, -0.08)]), 0.007, M["trim_black"], 6, 4)


## Thin trim line following the body side at one Z (door shut lines), slightly proud of the paint.
func door_seam(z: float, side: float) -> ArrayMesh:
	var p := body_half_profile(z)
	var pts := PackedVector3Array()
	for i in [4, 5, 6, 7]:
		pts.append(Vector3((p[i].x + 0.003) * side, p[i].y, z))
	return Forge.tube(pts, 0.0035, M["trim_black"], 5, 5)


func _lens(scale: Vector3, mat: Material) -> ArrayMesh:
	var profile := PackedVector2Array()
	for i in 9:
		var a := -PI * 0.5 + PI * i / 8.0
		profile.append(Vector2(cos(a), sin(a)))
	var m := Forge.lathe(profile, 20, null, false, false)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(m, 0, Transform3D(Basis.from_scale(scale) * Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO))
	st.generate_normals()
	var outm := st.commit()
	outm.surface_set_material(0, mat)
	return outm


func build_interior() -> void:
	var fabric: Material = M["interior_fabric"]
	var plastic: Material = M["interior_plastic"]
	out["seat_cushion"] = Forge.beveled_box(Vector3(0.50, 0.12, 0.50), 0.05, fabric)
	out["seat_back"] = Forge.beveled_box(Vector3(0.50, 0.62, 0.11), 0.05, fabric)
	out["rear_bench"] = Forge.beveled_box(Vector3(1.32, 0.14, 0.50), 0.05, fabric)
	out["rear_back"] = Forge.beveled_box(Vector3(1.32, 0.56, 0.12), 0.05, fabric)
	out["dashboard"] = Forge.beveled_box(Vector3(1.52, 0.22, 0.46), 0.06, plastic)
	out["steering_wheel"] = _steering_wheel(plastic)
	out["cluster"] = Forge.beveled_box(Vector3(0.34, 0.14, 0.045), 0.012, plastic)
	var gauge_mat: Material = M["headlight_lens"]
	out["gauge"] = _lens(Vector3(0.045, 0.045, 0.008), gauge_mat)
	out["warning_lamp"] = Forge.beveled_box(Vector3(0.028, 0.018, 0.01), 0.004, plastic)
	out["center_console"] = Forge.beveled_box(Vector3(0.28, 0.22, 0.78), 0.03, plastic)
	out["shifter"] = Forge.lathe(PackedVector2Array([
		Vector2(0.012, 0.0), Vector2(0.014, 0.08), Vector2(0.028, 0.10), Vector2(0.0, 0.105),
	]), 12, M["trim_black"])
	out["cabin_floor"] = Forge.beveled_box(Vector3(1.40, 0.04, 1.90), 0.02, M["underbody"])
	out["obd_port"] = Forge.beveled_box(Vector3(0.07, 0.045, 0.05), 0.008, M["trim_black"])
	out["ignition_coil"] = Forge.beveled_box(Vector3(0.10, 0.06, 0.08), 0.01, M["trim_black"])


func _steering_wheel(plastic: Material) -> ArrayMesh:
	var ring := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 15.0
		ring.append(Vector2(0.185 + cos(a) * 0.018, sin(a) * 0.016))
	var rim := Forge.lathe(ring, 32, null, false, false)
	var hub := Forge.lathe(PackedVector2Array([
		Vector2(0.0, -0.01), Vector2(0.045, -0.01), Vector2(0.05, 0.015), Vector2(0.0, 0.02),
	]), 16, null, true, false)
	var spoke := Forge.tube(PackedVector3Array([Vector3(0.04, 0, 0), Vector3(0.16, 0, 0)]), 0.01, null, 6, 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(rim, 0, Transform3D.IDENTITY)
	st.append_from(hub, 0, Transform3D.IDENTITY)
	for k in 3:
		st.append_from(spoke, 0, Transform3D(Basis(Vector3.UP, TAU * k / 3.0), Vector3.ZERO))
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, plastic)
	return mesh


func build_underbody() -> void:
	var under: Material = M["underbody"]
	var steel: Material = M["cast_iron"]
	out["exhaust"] = Forge.tube(PackedVector3Array([
		Vector3(0.05, 0.36, 1.24), Vector3(0.10, 0.22, 1.02), Vector3(0.14, 0.17, 0.60),
		Vector3(0.14, 0.17, -0.40), Vector3(0.20, 0.17, -1.30), Vector3(0.46, 0.20, -1.72),
		Vector3(0.50, 0.24, -2.20), Vector3(0.50, 0.25, -2.30),
	]), 0.026, M["bare_steel"], 10, 6)
	out["muffler"] = _lens(Vector3(0.20, 0.10, 0.34), M["bare_steel"])
	out["fuel_tank"] = Forge.beveled_box(Vector3(0.86, 0.17, 0.56), 0.06, under)
	out["rear_beam"] = Forge.beveled_box(Vector3(1.30, 0.09, 0.10), 0.03, steel)
	out["subframe"] = Forge.beveled_box(Vector3(1.18, 0.07, 0.10), 0.025, steel)
	out["control_arm"] = Forge.beveled_box(Vector3(0.40, 0.035, 0.07), 0.015, steel)
	out["tunnel_brace"] = Forge.beveled_box(Vector3(0.22, 0.03, 0.70), 0.01, steel)
	var helix := PackedVector3Array()
	for i in 49:
		var a := TAU * 4.0 * i / 48.0
		helix.append(Vector3(cos(a) * 0.06, 0.012 + 0.24 * i / 48.0, sin(a) * 0.06))
	out["coil_spring"] = Forge.tube(helix, 0.009, M["lift_red"], 6, 1)
	out["driveshaft"] = Forge.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0.4, 0, 0)]), 0.018, steel, 8, 1)
	out["damper"] = Forge.lathe(PackedVector2Array([Vector2(0.024, 0.0), Vector2(0.024, 0.32), Vector2(0.012, 0.33), Vector2(0.012, 0.46)]), 12, M["graphite_steel"])


func build_bay_structure() -> void:
	var black: Material = M["bay_black"]
	var inner: Material = M["car_paint_inner"]
	out["firewall"] = Forge.beveled_box(Vector3(1.50, 0.62, 0.03), 0.04, black)
	out["apron"] = Forge.beveled_box(Vector3(0.03, 0.40, 1.00), 0.015, inner)
	out["strut_tower"] = Forge.lathe(PackedVector2Array([Vector2(0.11, 0.0), Vector2(0.10, 0.22), Vector2(0.07, 0.26), Vector2(0.0, 0.265)]), 20, inner)
	out["strut_cap"] = Forge.lathe(PackedVector2Array([Vector2(0.035, 0.0), Vector2(0.03, 0.03), Vector2(0.0, 0.035)]), 12, M["graphite_steel"])
	out["core_support"] = Forge.beveled_box(Vector3(1.44, 0.06, 0.06), 0.02, black)
	out["cowl_panel"] = Forge.beveled_box(Vector3(1.48, 0.03, 0.14), 0.012, black)
	out["battery_tray"] = Forge.beveled_box(Vector3(0.30, 0.03, 0.22), 0.01, black)
	out["hinge"] = Forge.beveled_box(Vector3(0.02, 0.05, 0.14), 0.008, M["graphite_steel"])
	out["prop_rod"] = Forge.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 0.55, -0.1)]), 0.006, M["bare_steel"], 6, 1)


func build_all() -> Dictionary:
	build_body_meshes()
	build_wheel_meshes()
	build_lights()
	build_interior()
	build_underbody()
	build_bay_structure()
	return out
