extends RefCounted
## Authors the separately addressable engine-bay parts. Each becomes its own scene under
## scenes/vehicles/components/ with a RepairableComponent root. Gameplay parts get an
## Interactable child with a collider larger than the visual so it is easy to tap on a phone.

const Forge := preload("res://scripts/authoring/mesh_forge.gd")
const RepairableScript := preload("res://scripts/components/repairable_component.gd")
const InteractableScript := preload("res://scripts/interactable.gd")

const ENGINE_GLB := "res://assets/models/sources/car-engine.glb"
const ENGINE_TEX := "res://assets/textures/engine/car-engine_basecolor_filter_mount.png"
const RADIATOR_GLB := "res://assets/models/sources/car-radiator.glb"
const BATTERY_GLB := "res://assets/models/sources/car-battery.glb"

var M: Dictionary
var save_mesh: Callable


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save_mesh = mesh_saver


## Returns {scene_name: root Node3D} — the caller packs and saves each one.
func build_all() -> Dictionary:
	return {
		"engine_i4": _engine(),
		"oil_filter": _oil_filter(),
		"drain_plug": _drain_plug(),
		"oil_fill_cap": _fill_cap(),
		"dipstick": _dipstick(),
		"radiator": _glb_component("Radiator", RADIATOR_GLB, "radiator", "Radiator", 0.9, "", false),
		"battery": _glb_component("Battery", BATTERY_GLB, "battery", "12 V battery", 1.0, "", false),
		"air_intake": _air_intake(),
		"coolant_reservoir": _reservoir("CoolantReservoir", "coolant_reservoir", "Coolant reservoir", Vector3(0.15, 0.16, 0.12), M["coolant_fluid"], M["trim_black"]),
		"brake_fluid_reservoir": _reservoir("BrakeFluidReservoir", "brake_fluid_reservoir", "Brake fluid reservoir", Vector3(0.09, 0.08, 0.07), M["cap_yellow"], M["trim_black"]),
		"washer_reservoir": _reservoir("WasherReservoir", "washer_reservoir", "Washer fluid reservoir", Vector3(0.14, 0.14, 0.10), M["oil_filter_blue"], M["oil_filter_blue"]),
	}


func _component(name: String, id: String, label: String, tool: String, view: String, removable: bool, separate := true) -> Node3D:
	var root := Node3D.new()
	root.name = name
	root.set_script(RepairableScript)
	root.set("component_id", id)
	root.set("display_name", label)
	root.set("required_tool", tool)
	root.set("access_view", view)
	root.set("removable", removable)
	root.set("separate_mesh", separate)
	return root


func _pickable(parent: Node3D, part_id: String, label: String, meshes: Array, collider_radius: float, collider_offset := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Pickable"
	body.set_script(InteractableScript)
	body.set("part_id", part_id)
	body.set("display_name", label)
	parent.add_child(body)
	for entry in meshes:
		body.add_child(entry)
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var sphere := SphereShape3D.new()
	sphere.radius = collider_radius
	shape.shape = sphere
	shape.position = collider_offset
	body.add_child(shape)
	return body


func _mi(name: String, mesh: Mesh, xf := Transform3D.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = xf
	return mi


func _engine() -> Node3D:
	var root := _component("Engine", "engine_block", "1.6 L inline-4 engine", "", "engine", false, false)
	var glb: Node = (load(ENGINE_GLB) as PackedScene).instantiate()
	var src: MeshInstance3D = glb.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh: ArrayMesh = src.mesh.duplicate(true)
	var mat := (mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	mat.resource_name = "engine_i4"
	mat.albedo_texture = load(ENGINE_TEX)
	mesh.surface_set_material(0, mat)
	var origin := src.transform.origin
	glb.free()
	var saved: Mesh = save_mesh.call(mesh, "engine_i4_block")
	root.add_child(_mi("EngineBlock", saved, Transform3D(Basis.from_scale(Vector3.ONE * 0.85), origin * 0.85)))
	return root


func _oil_filter() -> Node3D:
	var root := _component("OilFilter", "oil_filter", "Oil filter", "filter_wrench", "under", true)
	var can := Forge.lathe(PackedVector2Array([
		Vector2(0.040, 0.0), Vector2(0.046, 0.006), Vector2(0.047, 0.012), Vector2(0.047, 0.080),
		Vector2(0.044, 0.092), Vector2(0.036, 0.100), Vector2(0.0, 0.103),
	]), 28, M["oil_filter_blue"], true, true)
	var gasket := Forge.lathe(PackedVector2Array([Vector2(0.034, -0.004), Vector2(0.044, -0.004), Vector2(0.044, 0.004), Vector2(0.034, 0.004)]), 24, M["rubber_hose"])
	var axis := Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3.ZERO)
	_pickable(root, "oil_filter", "Oil filter", [
		_mi("FilterCan", save_mesh.call(can, "oil_filter_can"), axis),
		_mi("Gasket", save_mesh.call(gasket, "oil_filter_gasket"), axis),
	], 0.085, Vector3(0, 0, 0.05))
	return root


func _drain_plug() -> Node3D:
	var root := _component("DrainPlug", "drain_plug", "Oil drain plug", "socket", "under", true)
	var hex := Forge.lathe(PackedVector2Array([Vector2(0.017, -0.02), Vector2(0.017, -0.006), Vector2(0.0, -0.006)]), 6, M["zinc_bolt"], true, false)
	var washer := Forge.lathe(PackedVector2Array([Vector2(0.021, -0.006), Vector2(0.021, 0.0), Vector2(0.0, 0.0)]), 20, M["bare_steel"], true, false)
	_pickable(root, "drain_plug", "Drain plug", [
		_mi("HexHead", save_mesh.call(hex, "drain_plug_hex")),
		_mi("Washer", save_mesh.call(washer, "drain_plug_washer")),
	], 0.075, Vector3(0, -0.02, 0))
	return root


func _fill_cap() -> Node3D:
	var root := _component("OilFillCap", "fill_cap", "Oil fill cap", "hand", "engine", true)
	var profile := PackedVector2Array([Vector2(0.03, 0.0), Vector2(0.034, 0.004), Vector2(0.034, 0.02), Vector2(0.03, 0.026), Vector2(0.012, 0.03), Vector2(0.0, 0.03)])
	var cap := Forge.lathe(profile, 12, M["cap_yellow"])
	var tab := Forge.beveled_box(Vector3(0.05, 0.012, 0.01), 0.004, M["cap_yellow"])
	_pickable(root, "fill_cap", "Oil fill cap", [
		_mi("Cap", save_mesh.call(cap, "oil_fill_cap")),
		_mi("GripTab", save_mesh.call(tab, "oil_fill_cap_tab"), Transform3D(Basis.IDENTITY, Vector3(0, 0.034, 0))),
	], 0.07, Vector3(0, 0.02, 0))
	return root


func _dipstick() -> Node3D:
	var root := _component("Dipstick", "dipstick", "Oil dipstick", "hand", "engine", false)
	var ring := PackedVector2Array()
	for i in 11:
		var a := TAU * i / 10.0
		ring.append(Vector2(0.022 + cos(a) * 0.006, sin(a) * 0.006))
	var loop := Forge.lathe(ring, 18, M["cap_yellow"], false, false)
	var tube := Forge.tube(PackedVector3Array([Vector3(0, -0.012, 0), Vector3(0, -0.12, 0.01), Vector3(0.01, -0.26, 0.05)]), 0.007, M["bare_steel"], 6, 4)
	_pickable(root, "dipstick", "Dipstick", [
		_mi("Handle", save_mesh.call(loop, "dipstick_handle"), Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.015, 0))),
		_mi("Tube", save_mesh.call(tube, "dipstick_tube")),
	], 0.065, Vector3(0, 0.015, 0))
	return root


func _glb_component(name: String, path: String, id: String, label: String, scale: float, tool: String, removable: bool) -> Node3D:
	var root := _component(name, id, label, tool, "engine", removable)
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.name = "Model"
	model.scale = Vector3.ONE * scale
	root.add_child(model)
	return root


func _air_intake() -> Node3D:
	var root := _component("AirIntake", "air_filter_box", "Air filter box", "hand", "engine", false)
	var box := Forge.beveled_box(Vector3(0.24, 0.14, 0.34), 0.035, M["bay_black"])
	var lid := Forge.beveled_box(Vector3(0.25, 0.03, 0.35), 0.012, M["trim_black"])
	var duct := Forge.tube(PackedVector3Array([Vector3(-0.04, 0.07, -0.14), Vector3(-0.10, 0.12, -0.22), Vector3(-0.16, 0.08, -0.28)]), 0.034, M["rubber_hose"], 12, 5)
	var snorkel := Forge.tube(PackedVector3Array([Vector3(0.0, -0.02, 0.17), Vector3(0.0, -0.05, 0.26), Vector3(-0.04, -0.08, 0.30)]), 0.03, M["bay_black"], 10, 4)
	root.add_child(_mi("Housing", save_mesh.call(box, "air_box")))
	root.add_child(_mi("Lid", save_mesh.call(lid, "air_box_lid"), Transform3D(Basis.IDENTITY, Vector3(0, 0.075, 0))))
	root.add_child(_mi("IntakeDuct", save_mesh.call(duct, "air_intake_duct")))
	root.add_child(_mi("Snorkel", save_mesh.call(snorkel, "air_intake_snorkel")))
	return root


func _reservoir(name: String, id: String, label: String, size: Vector3, fluid: Material, cap_mat: Material) -> Node3D:
	var root := _component(name, id, label, "", "engine", false)
	var tank := Forge.beveled_box(size, minf(size.x, size.z) * 0.3, M["reservoir_plastic"])
	var fluid_mesh := Forge.beveled_box(size * Vector3(0.9, 0.55, 0.9), minf(size.x, size.z) * 0.25, fluid)
	var cap := Forge.lathe(PackedVector2Array([Vector2(0.022, 0.0), Vector2(0.022, 0.018), Vector2(0.0, 0.02)]), 14, cap_mat)
	root.add_child(_mi("Tank", save_mesh.call(tank, id + "_tank")))
	root.add_child(_mi("Fluid", save_mesh.call(fluid_mesh, id + "_fluid"), Transform3D(Basis.IDENTITY, Vector3(0, -size.y * 0.18, 0))))
	root.add_child(_mi("Cap", save_mesh.call(cap, id + "_cap"), Transform3D(Basis.IDENTITY, Vector3(0, size.y * 0.5, 0))))
	return root
