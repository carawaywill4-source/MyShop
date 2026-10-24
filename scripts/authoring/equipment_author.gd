extends RefCounted
## Authors shop equipment scenes: the two-post lift and the oil drain caddy.
## Lift dimensions follow a typical 4.5 t clear-floor two-post lift: 3.7 m columns,
## ~3.2 m between columns, asymmetric swing arms, round screw-up pads.

const Forge := preload("res://scripts/authoring/mesh_forge.gd")
const LiftScript := preload("res://scripts/equipment/two_post_lift.gd")
const CaddyScript := preload("res://scripts/equipment/oil_drain_caddy.gd")

const POST_X := 1.75
const COLUMN_H := 3.70
## Pad targets in vehicle space (pinch-weld pickup points behind/in front of the wheels).
const PAD_FRONT := Vector2(0.76, 0.92)
const PAD_REAR := Vector2(0.76, -0.98)

var M: Dictionary
var save_mesh: Callable


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save_mesh = mesh_saver


func _mi(name: String, mesh: Mesh, pos := Vector3.ZERO, basis := Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	return mi


func build_lift() -> Node3D:
	var root := Node3D.new()
	root.name = "TwoPostLift"
	root.set_script(LiftScript)
	var column: Mesh = save_mesh.call(_column_mesh(), "lift_column")
	var base: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.56, 0.03, 0.50), 0.01, M["graphite_steel"]), "lift_base_plate")
	var carriage: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.22, 0.62, 0.30), 0.03, M["graphite_steel"]), "lift_carriage")
	var arm_outer: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.12, 0.075, 1.0), 0.018, M["graphite_steel"]), "lift_arm_outer")
	var arm_inner: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.09, 0.058, 1.0), 0.014, M["bare_steel"]), "lift_arm_inner")
	var pad: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.0, -0.06), Vector2(0.05, -0.06), Vector2(0.052, -0.035), Vector2(0.075, -0.03), Vector2(0.078, -0.012), Vector2(0.074, 0.0), Vector2(0.0, 0.0)]), 24, M["rubber_pad"]), "lift_pad")
	var pad_ring: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.06, -0.075), Vector2(0.066, -0.075), Vector2(0.066, -0.035), Vector2(0.06, -0.035)]), 20, M["safety_yellow"], false, false), "lift_pad_ring")
	var pivot: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.045, -0.06), Vector2(0.045, 0.06)]), 16, M["bare_steel"]), "lift_arm_pivot")
	var stripe: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.312, 0.06, 0.272), 0.03, M["safety_yellow"]), "lift_column_stripe")
	for side in [1.0, -1.0]:
		var post := Node3D.new()
		post.name = "LeftPost" if side > 0.0 else "RightPost"
		post.position = Vector3(POST_X * side, 0, 0)
		root.add_child(post)
		post.add_child(_mi("Column", column, Vector3(0, COLUMN_H * 0.5, 0)))
		post.add_child(_mi("BasePlate", base, Vector3(0, 0.015, 0)))
		for y in [0.35, 2.1]:
			post.add_child(_mi("SafetyStripe", stripe, Vector3(0, y, 0)))
		var car := Node3D.new()
		car.name = "Carriage"
		car.position.y = 0.19
		post.add_child(car)
		car.add_child(_mi("CarriageBlock", carriage, Vector3(-0.2 * side, -0.12, 0)))
		for pad_xz in [PAD_FRONT, PAD_REAR]:
			var pivot_pos := Vector3(-0.27 * side, -0.10, 0.17 * signf(pad_xz.y))
			var pad_pos := Vector3(pad_xz.x * side - POST_X * side, 0.0, pad_xz.y)
			var flat := Vector3(pad_pos.x - pivot_pos.x, 0, pad_pos.z - pivot_pos.z)
			var length := flat.length()
			var basis := Basis.looking_at(flat.normalized(), Vector3.UP)
			var arm := Node3D.new()
			arm.name = "FrontArm" if pad_xz.y > 0.0 else "RearArm"
			arm.position = pivot_pos
			car.add_child(arm)
			arm.add_child(_mi("Pivot", pivot))
			arm.add_child(_mi("OuterTube", arm_outer, basis * Vector3(0, 0, -length * 0.34), basis * Basis.from_scale(Vector3(1, 1, length * 0.68))))
			arm.add_child(_mi("InnerTube", arm_inner, basis * Vector3(0, 0, -length * 0.74), basis * Basis.from_scale(Vector3(1, 1, length * 0.5))))
			arm.add_child(_mi("Pad", pad, Vector3(flat.x, 0.10, flat.z)))
			arm.add_child(_mi("PadRing", pad_ring, Vector3(flat.x, 0.10, flat.z)))
	# Overhead beam (clear-floor style) with the equalisation cable run and the power unit.
	var beam: Mesh = save_mesh.call(Forge.beveled_box(Vector3(POST_X * 2.0 + 0.30, 0.20, 0.24), 0.03, M["lift_red"]), "lift_overhead_beam")
	root.add_child(_mi("OverheadBeam", beam, Vector3(0, COLUMN_H + 0.10, 0)))
	var pad_bar: Mesh = save_mesh.call(Forge.beveled_box(Vector3(POST_X * 2.0 - 0.3, 0.04, 0.06), 0.015, M["safety_yellow"]), "lift_shutoff_bar")
	root.add_child(_mi("ShutoffBar", pad_bar, Vector3(0, COLUMN_H - 0.12, 0.0)))
	var hose: Mesh = save_mesh.call(Forge.tube(PackedVector3Array([
		Vector3(-POST_X - 0.02, 0.6, -0.16), Vector3(-POST_X, 2.0, -0.16), Vector3(-POST_X + 0.1, COLUMN_H + 0.05, -0.15),
		Vector3(POST_X - 0.1, COLUMN_H + 0.05, -0.15), Vector3(POST_X, 2.0, -0.16), Vector3(POST_X + 0.02, 0.6, -0.16),
	]), 0.012, M["rubber_hose"], 6, 4), "lift_hydraulic_line")
	root.add_child(_mi("HydraulicLine", hose))
	var unit: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.22, 0.34, 0.26), 0.03, M["graphite_steel"]), "lift_power_unit")
	var motor: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.075, 0.0), Vector2(0.08, 0.02), Vector2(0.08, 0.26), Vector2(0.06, 0.28), Vector2(0.0, 0.28)]), 20, M["lift_red"]), "lift_motor")
	root.add_child(_mi("PowerUnit", unit, Vector3(-POST_X - 0.27, 1.15, 0)))
	root.add_child(_mi("Motor", motor, Vector3(-POST_X - 0.27, 1.32, 0)))
	return root


func _column_mesh() -> ArrayMesh:
	# Formed C-channel column: outer shell with a recessed inner slot facing the car.
	var profile := PackedVector2Array([
		Vector2(-0.15, -0.13), Vector2(0.15, -0.13), Vector2(0.15, 0.13), Vector2(-0.15, 0.13),
		Vector2(-0.15, 0.05), Vector2(-0.11, 0.05), Vector2(-0.11, -0.05), Vector2(-0.15, -0.05),
	])
	var mesh := Forge.extrude(profile, COLUMN_H, M["lift_red"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Extrude runs along Z; stand it up so the column height is Y.
	st.append_from(mesh, 0, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
	st.generate_normals()
	var out := st.commit()
	out.surface_set_material(0, M["lift_red"])
	return out


func build_caddy() -> Node3D:
	var root := Node3D.new()
	root.name = "OilDrainCaddy"
	root.set_script(CaddyScript)
	var tank: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([
		Vector2(0.0, 0.10), Vector2(0.22, 0.10), Vector2(0.26, 0.14), Vector2(0.27, 0.40), Vector2(0.24, 0.50), Vector2(0.06, 0.53), Vector2(0.0, 0.53),
	]), 28, M["caddy_yellow"]), "caddy_tank")
	var caster: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.0, -0.02), Vector2(0.04, -0.02), Vector2(0.04, 0.02), Vector2(0.0, 0.02)]), 12, M["rubber_pad"]), "caddy_caster")
	root.add_child(_mi("Tank", tank))
	for k in 4:
		var a := TAU * (k + 0.5) / 4.0
		root.add_child(_mi("Caster", caster, Vector3(cos(a) * 0.19, 0.045, sin(a) * 0.19), Basis(Vector3.FORWARD, PI * 0.5)))
	var funnel := Node3D.new()
	funnel.name = "Funnel"
	funnel.position.y = 0.62
	root.add_child(funnel)
	var bowl: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([
		Vector2(0.03, -0.12), Vector2(0.05, -0.08), Vector2(0.26, 0.0), Vector2(0.29, 0.03), Vector2(0.28, 0.035),
	]), 28, M["caddy_yellow"], false, false), "caddy_funnel")
	bowl.surface_get_material(0)
	var mat := (M["caddy_yellow"] as StandardMaterial3D)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	funnel.add_child(_mi("Bowl", bowl))
	var pole: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.022, -1.0), Vector2(0.022, -0.1)]), 12, M["bare_steel"]), "caddy_pole")
	funnel.add_child(_mi("Pole", pole))
	var oil: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.2, 0.0)]), 24, M["used_oil"], false, false), "caddy_oil_surface")
	funnel.add_child(_mi("OilSurface", oil, Vector3(0, -0.01, 0)))
	return root


## Ghost marker the player taps (with the Pan tool) to place the caddy under the car.
func build_drain_spot() -> Node3D:
	var InteractableScript := preload("res://scripts/interactable.gd")
	var body := StaticBody3D.new()
	body.name = "DrainPanSpot"
	body.set_script(InteractableScript)
	body.set("part_id", "drain_pan_spot")
	body.set("display_name", "Drain pan spot")
	var ghost: Mesh = save_mesh.call(Forge.lathe(PackedVector2Array([
		Vector2(0.03, -0.12), Vector2(0.05, -0.08), Vector2(0.26, 0.0), Vector2(0.29, 0.03),
	]), 24, M["placement_ghost"], true, false), "drain_spot_ghost")
	body.add_child(_mi("Ghost", ghost))
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.34
	cyl.height = 0.3
	shape.shape = cyl
	body.add_child(shape)
	return body
