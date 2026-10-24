extends SceneTree
## Builds MyShop's visual foundation and saves it as editable scenes and resources:
##   assets/materials/*.tres, assets/models/authored/*.res,
##   scenes/vehicles/components/*.tscn, scenes/vehicles/harbor_commute.tscn,
##   scenes/equipment/*.tscn, scenes/workshop/workshop_bay.tscn,
##   assets/models/authored/blender_source/*.glb (for editing in Blender).
## Re-running overwrites those files. Hand edits made in the Godot editor to these scenes
## will be lost on rebuild, so either edit the authoring scripts or stop rebuilding a scene
## once an artist takes it over.
##
## Godot --headless --path . --script scripts/dev/build_foundation.gd

const MaterialLibrary := preload("res://scripts/authoring/material_library.gd")
const VehicleAuthor := preload("res://scripts/authoring/vehicle_author.gd")
const ComponentAuthor := preload("res://scripts/authoring/component_author.gd")
const EquipmentAuthor := preload("res://scripts/authoring/equipment_author.gd")
const WorkshopAuthor := preload("res://scripts/authoring/workshop_author.gd")
const SportSedanAuthor := preload("res://scripts/authoring/sport_sedan_author.gd")
const TripoCarAuthor := preload("res://scripts/authoring/tripo_car_author.gd")
const TripoEngineAuthor := preload("res://scripts/authoring/tripo_engine_author.gd")
const TripoVehicleImporter := preload("res://scripts/authoring/tripo_vehicle_importer.gd")
const VehicleScript := preload("res://scripts/vehicles/vehicle.gd")
const InteractableScript := preload("res://scripts/interactable.gd")
const Forge := preload("res://scripts/authoring/mesh_forge.gd")

const MESH_DIR := "res://assets/models/authored/"
const MAT_DIR := "res://assets/materials/"
const TIRE_GLB := "res://assets/models/sources/car-tire.glb"

## Engine placement in vehicle space; component positions below derive from the engine
## model's own feature locations (found with scripts/dev/locate_engine_features.gd).
const ENGINE_POS := Vector3(0.08, 0.15, 1.45)
const ENGINE_SCALE := 0.85

var M: Dictionary = {}
var engine_i6_bounds := AABB()


func _init() -> void:
	if OS.get_environment("MYSHOP_HARBOR_ONLY") == "1":
		_rebuild_harbor_only()
		return
	for dir in [MESH_DIR, MAT_DIR, "res://scenes/vehicles/components", "res://scenes/equipment", "res://scenes/workshop"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_build_materials()
	var saver := Callable(self, "_save_mesh")
	var comp_paths := {}
	var components: Dictionary = ComponentAuthor.new(M, saver).build_all()
	for key in components:
		comp_paths[key] = _pack(components[key], "res://scenes/vehicles/components/%s.tscn" % key)
	var i6 := TripoEngineAuthor.new(M, saver)
	comp_paths["engine_i6"] = _pack(i6.build(), "res://scenes/vehicles/components/engine_i6.tscn")
	engine_i6_bounds = i6.bounds
	var vehicle := _assemble_vehicle(comp_paths)
	_pack(vehicle, "res://scenes/vehicles/harbor_commute.tscn")
	_pack(_assemble_sport_sedan(comp_paths), "res://scenes/vehicles/kessler_gt6_procedural.tscn")
	_pack(_assemble_tripo_car(comp_paths), "res://scenes/vehicles/kessler_gt6.tscn")
	_build_roster(comp_paths)
	var eq := EquipmentAuthor.new(M, saver)
	var lift_path := _pack(eq.build_lift(), "res://scenes/equipment/two_post_lift.tscn")
	var caddy_path := _pack(eq.build_caddy(), "res://scenes/equipment/oil_drain_caddy.tscn")
	var spot_path := _pack(eq.build_drain_spot(), "res://scenes/equipment/drain_pan_spot.tscn")
	var workshop: Node3D = WorkshopAuthor.new(M, saver).build(
		(load(lift_path) as PackedScene).instantiate(),
		(load(caddy_path) as PackedScene).instantiate(),
		(load(spot_path) as PackedScene).instantiate())
	_pack(workshop, "res://scenes/workshop/workshop_bay.tscn")
	_export_glb("res://scenes/vehicles/kessler_gt6.tscn", "kessler_gt6.glb")
	_export_glb(lift_path, "two_post_lift.glb")
	print("FOUNDATION BUILD OK")
	quit(0)


func _rebuild_harbor_only() -> void:
	for dir in [MESH_DIR, MAT_DIR]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	_build_materials()
	var comp := {
		"engine_i4": "res://scenes/vehicles/components/engine_i4.tscn",
		"radiator": "res://scenes/vehicles/components/radiator.tscn",
		"battery": "res://scenes/vehicles/components/battery.tscn",
		"air_intake": "res://scenes/vehicles/components/air_intake.tscn",
		"coolant_reservoir": "res://scenes/vehicles/components/coolant_reservoir.tscn",
		"brake_fluid_reservoir": "res://scenes/vehicles/components/brake_fluid_reservoir.tscn",
		"washer_reservoir": "res://scenes/vehicles/components/washer_reservoir.tscn",
		"oil_filter": "res://scenes/vehicles/components/oil_filter.tscn",
		"drain_plug": "res://scenes/vehicles/components/drain_plug.tscn",
		"oil_fill_cap": "res://scenes/vehicles/components/oil_fill_cap.tscn",
		"dipstick": "res://scenes/vehicles/components/dipstick.tscn",
	}
	var vehicle := _assemble_vehicle(comp)
	_pack(vehicle, "res://scenes/vehicles/harbor_commute.tscn")
	_export_glb("res://scenes/vehicles/harbor_commute.tscn", "harbor_commute.glb")
	print("HARBOR REBUILD OK")
	quit(0)


func _build_materials() -> void:
	var built: Dictionary = MaterialLibrary.new().build()
	for name in built:
		var path: String = MAT_DIR + name + ".tres"
		ResourceSaver.save(built[name], path)
		M[name] = load(path)


func _save_mesh(mesh: Mesh, name: String) -> Mesh:
	var path := MESH_DIR + name + ".res"
	ResourceSaver.save(mesh, path)
	return load(path)


func _pack(root_node: Node, path: String) -> String:
	_own(root_node, root_node)
	var packed := PackedScene.new()
	var err := packed.pack(root_node)
	if err != OK:
		push_error("pack failed %s: %s" % [path, err])
	ResourceSaver.save(packed, path)
	root_node.free()
	print("saved ", path)
	return path


func _own(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		if child.scene_file_path == "":
			_own(child, owner_node)


func _mi(name: String, mesh: Mesh, pos := Vector3.ZERO, basis := Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	return mi


func _group(parent: Node3D, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	return n


func _instance(parent: Node3D, path: String, pos: Vector3, basis := Basis.IDENTITY) -> Node3D:
	var node: Node3D = (load(path) as PackedScene).instantiate()
	node.transform = Transform3D(basis, pos)
	parent.add_child(node)
	return node


func _engine_point(local: Vector3) -> Vector3:
	return ENGINE_POS + local * ENGINE_SCALE


func _tube(name: String, pts: PackedVector3Array, radius: float, mat: Material, sides := 10) -> MeshInstance3D:
	return _mi(name, _save_mesh(Forge.tube(pts, radius, mat, sides, 5), name.to_snake_case()))


func _assemble_vehicle(comp: Dictionary) -> Node3D:
	var author := VehicleAuthor.new(M)
	var meshes: Dictionary = author.build_all()
	var saved := {}
	for key in meshes:
		saved[key] = _save_mesh(meshes[key], "harbor_commute_" + key)
	var car := Node3D.new()
	car.name = "HarborCommute"
	car.set_script(VehicleScript)
	car.set("vehicle_id", "commuter_a")
	car.set("display_name", "2016 Harbor Commute")
	car.set("family", "compact_sedan")
	car.set("engine_layout", "transverse_inline_4")
	car.set("drivetrain", "fwd")
	car.set("lift_point_height", VehicleAuthor.SILL_Y)

	var body := _group(car, "Body")
	body.add_child(_mi("Shell", saved["body"]))
	body.add_child(_mi("Greenhouse", saved["greenhouse"]))
	body.add_child(_mi("NoseCap", saved["nose_cap"]))
	body.add_child(_mi("TailCap", saved["tail_cap"]))
	# Hood hinges at the cowl; the panel mesh is authored in vehicle space, so offset it back.
	var hinge := Vector3(0, VehicleAuthor.top_y(VehicleAuthor.COWL_Z) + 0.03, VehicleAuthor.COWL_Z)
	var hood_pivot := _group(body, "HoodPivot")
	hood_pivot.position = hinge
	var hood := StaticBody3D.new()
	hood.name = "Hood"
	hood.set_script(InteractableScript)
	hood.set("part_id", "hood")
	hood.set("display_name", "Hood")
	hood.position = -hinge
	hood_pivot.add_child(hood)
	hood.add_child(_mi("HoodPanel", saved["hood"]))
	hood.add_child(_mi("HoodInner", saved["hood_inner"]))
	var hood_shape := CollisionShape3D.new()
	hood_shape.name = "TouchTarget"
	var hood_box := BoxShape3D.new()
	hood_box.size = Vector3(1.6, 0.14, 1.0)
	hood_shape.shape = hood_box
	hood_shape.position = Vector3(0, 0.88, 1.49)
	hood.add_child(hood_shape)

	var lights := _group(body, "Lights")
	for side in [1.0, -1.0]:
		var yaw: float = 0.30 * side
		lights.add_child(_mi("Headlight", saved["headlight"], Vector3(0.575 * side, 0.585, 2.205), Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -0.35)))
		lights.add_child(_mi("Indicator", saved["indicator"], Vector3(0.78 * side, 0.52, 2.03), Basis(Vector3.UP, 1.2 * side)))
		lights.add_child(_mi("Taillight", saved["taillight"], Vector3(0.60 * side, 0.86, -2.215), Basis(Vector3.UP, -0.32 * side) * Basis(Vector3.RIGHT, 0.4)))
		var seams := [VehicleAuthor.AXLE_FRONT - VehicleAuthor.ARCH_RADIUS - 0.02, -0.25, VehicleAuthor.AXLE_REAR + VehicleAuthor.ARCH_RADIUS + 0.02]
		for k in seams.size():
			var seam_name := "harbor_commute_door_seam_%d_%s" % [k, "l" if side > 0.0 else "r"]
			lights.add_child(_mi("DoorSeam", _save_mesh(author.door_seam(seams[k], side), seam_name)))
		lights.add_child(_mi("Wiper", saved["wiper"], Vector3(0.05 * side - 0.45, 0.945, 1.02)))
	_add_door(body, saved, "door_fl", "Front left door", 1.0, VehicleAuthor.FRONT_DOOR_Z, true)
	_add_door(body, saved, "door_fr", "Front right door", -1.0, VehicleAuthor.FRONT_DOOR_Z, true)
	_add_door(body, saved, "door_rl", "Rear left door", 1.0, VehicleAuthor.REAR_DOOR_Z, false)
	_add_door(body, saved, "door_rr", "Rear right door", -1.0, VehicleAuthor.REAR_DOOR_Z, false)
	lights.add_child(_mi("Grille", saved["grille"], Vector3(0, 0.535, 2.235)))
	lights.add_child(_mi("LowerIntake", saved["lower_intake"], Vector3(0, 0.36, 2.20)))
	lights.add_child(_mi("FrontPlate", saved["plate"], Vector3(0, 0.41, 2.262)))
	lights.add_child(_mi("RearPlate", saved["plate"], Vector3(0, 0.55, -2.262)))
	var badge := Label3D.new()
	badge.name = "RearBadge"
	badge.text = "HARBOR"
	badge.font_size = 28
	badge.pixel_size = 0.0018
	badge.position = Vector3(0.45, 0.70, -2.258)
	badge.rotation_degrees.y = 180.0
	badge.modulate = Color(0.85, 0.87, 0.9)
	lights.add_child(badge)

	var wheels := _group(car, "Wheels")
	for wheel_def in [["FrontLeft", 1.0, VehicleAuthor.AXLE_FRONT], ["FrontRight", -1.0, VehicleAuthor.AXLE_FRONT], ["RearLeft", 1.0, VehicleAuthor.AXLE_REAR], ["RearRight", -1.0, VehicleAuthor.AXLE_REAR]]:
		var side: float = wheel_def[1]
		var wheel := _group(wheels, wheel_def[0])
		wheel.position = Vector3(VehicleAuthor.TRACK_HALF * side, VehicleAuthor.WHEEL_RADIUS, wheel_def[2])
		_instance(wheel, TIRE_GLB, Vector3(0, -VehicleAuthor.WHEEL_RADIUS, 0), Basis(Vector3.UP, PI * 0.5)).name = "Tyre"
		var outward := Basis(Vector3.FORWARD, PI * 0.5 * side)
		wheel.add_child(_mi("Rim", saved["rim"], Vector3.ZERO, outward))
		wheel.add_child(_mi("BrakeDisc", saved["brake_disc"], Vector3(-0.035 * side, 0, 0), outward))
		wheel.add_child(_mi("Caliper", saved["caliper"], Vector3(-0.05 * side, 0.08, -0.10 if wheel_def[2] > 0.0 else 0.10)))

	var interior := _group(car, "Interior")
	for side in [1.0, -1.0]:
		interior.add_child(_mi("FrontSeat", saved["seat_cushion"], Vector3(0.38 * side, 0.36, -0.22)))
		interior.add_child(_mi("FrontSeatBack", saved["seat_back"], Vector3(0.38 * side, 0.72, -0.50), Basis(Vector3.RIGHT, -0.22)))
	interior.add_child(_mi("RearBench", saved["rear_bench"], Vector3(0, 0.37, -1.05)))
	interior.add_child(_mi("RearBenchBack", saved["rear_back"], Vector3(0, 0.72, -1.32), Basis(Vector3.RIGHT, -0.28)))
	interior.add_child(_mi("Dashboard", saved["dashboard"], Vector3(0, 0.84, 0.72)))
	interior.add_child(_mi("SteeringWheel", saved["steering_wheel"], Vector3(0.38, 1.02, 0.46), Basis(Vector3.RIGHT, PI * 0.5 - 0.55)))
	interior.add_child(_mi("Cluster", saved["cluster"], Vector3(0.38, 1.01, 0.64)))
	interior.add_child(_mi("GaugeLeft", saved["gauge"], Vector3(0.31, 1.02, 0.665)))
	interior.add_child(_mi("GaugeRight", saved["gauge"], Vector3(0.45, 1.02, 0.665)))
	var lamp := _mi("CheckEngineLamp", saved["warning_lamp"], Vector3(0.50, 1.03, 0.66))
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.albedo_color = Color(0.25, 0.03, 0.02)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(0.15, 0.0, 0.0)
	lamp_mat.emission_energy_multiplier = 0.0
	lamp.material_override = lamp_mat
	interior.add_child(lamp)
	interior.add_child(_mi("CenterConsole", saved["center_console"], Vector3(0, 0.48, -0.02)))
	interior.add_child(_mi("Shifter", saved["shifter"], Vector3(0, 0.64, 0.08)))
	interior.add_child(_mi("CabinFloor", saved["cabin_floor"], Vector3(0, 0.30, -0.10)))
	_add_named_part(interior, "ObdPort", "obd_port", "OBD-II port", saved["obd_port"], Vector3(0.55, 0.72, 0.50), Vector3(0.16, 0.10, 0.12))
	var eye := Node3D.new()
	eye.name = "DriverEye"
	eye.position = Vector3(0.38, 1.08, -0.02)
	interior.add_child(eye)
	var look := Node3D.new()
	look.name = "ClusterLook"
	look.position = Vector3(0.38, 1.00, 0.64)
	interior.add_child(look)

	var under := _group(car, "Underbody")
	under.add_child(_mi("Exhaust", saved["exhaust"]))
	under.add_child(_mi("Muffler", saved["muffler"], Vector3(0.40, 0.205, -1.60)))
	under.add_child(_mi("FuelTank", saved["fuel_tank"], Vector3(-0.05, 0.20, -0.95)))
	under.add_child(_mi("RearBeam", saved["rear_beam"], Vector3(0, 0.30, VehicleAuthor.AXLE_REAR + 0.04)))
	under.add_child(_mi("FrontSubframe", saved["subframe"], Vector3(0, 0.20, 1.10)))
	under.add_child(_mi("TunnelBrace", saved["tunnel_brace"], Vector3(0, 0.17, 0.30)))
	for side in [1.0, -1.0]:
		under.add_child(_mi("ControlArm", saved["control_arm"], Vector3(0.50 * side, 0.23, 1.22), Basis(Vector3.UP, 0.45 * side)))
		under.add_child(_mi("Driveshaft", saved["driveshaft"], Vector3(0.24 if side > 0.0 else -0.64, 0.30, VehicleAuthor.AXLE_FRONT)))
		under.add_child(_mi("RearSpring", saved["coil_spring"], Vector3(0.56 * side, 0.21, VehicleAuthor.AXLE_REAR - 0.06)))
		under.add_child(_mi("RearDamper", saved["damper"], Vector3(0.62 * side, 0.18, VehicleAuthor.AXLE_REAR + 0.10)))
		under.add_child(_mi("FrontStrut", saved["damper"], Vector3(0.64 * side, 0.30, VehicleAuthor.AXLE_FRONT)))

	var bay := _group(car, "EngineBay")
	bay.add_child(_mi("Firewall", saved["firewall"], Vector3(0, 0.55, VehicleAuthor.COWL_Z - 0.01)))
	bay.add_child(_mi("CowlPanel", saved["cowl_panel"], Vector3(0, 0.90, VehicleAuthor.COWL_Z + 0.06)))
	bay.add_child(_mi("CoreSupport", saved["core_support"], Vector3(0, 0.71, 2.00)))
	for side in [1.0, -1.0]:
		bay.add_child(_mi("InnerApron", saved["apron"], Vector3(0.655 * side, 0.52, 1.49)))
		bay.add_child(_mi("StrutTower", saved["strut_tower"], Vector3(0.60 * side, 0.49, VehicleAuthor.AXLE_FRONT)))
		bay.add_child(_mi("StrutCap", saved["strut_cap"], Vector3(0.60 * side, 0.755, VehicleAuthor.AXLE_FRONT)))
		bay.add_child(_mi("HoodHinge", saved["hinge"], Vector3(0.63 * side, 0.92, VehicleAuthor.COWL_Z + 0.06)))
	bay.add_child(_mi("BatteryTray", saved["battery_tray"], Vector3(-0.46, 0.445, 1.55)))

	_add_bay_parts(bay, comp)
	_add_named_part(bay, "IgnitionCoil", "ignition_coil", "Ignition coil", saved["ignition_coil"], Vector3(0.30, 0.78, 1.55), Vector3(0.16, 0.12, 0.14))
	return car


func _add_door(body: Node3D, saved: Dictionary, id: String, label: String, side: float, band: Vector2, with_mirror: bool) -> void:
	var hinge := VehicleAuthor.door_hinge(band.y, side)
	var pivot := _group(body, id)
	pivot.position = hinge
	pivot.set_meta("open_sign", -1.0 if side > 0.0 else 1.0)
	var door := StaticBody3D.new()
	door.name = "Door"
	door.set_script(InteractableScript)
	door.set("part_id", id)
	door.set("display_name", label)
	door.position = -hinge
	pivot.add_child(door)
	door.add_child(_mi("Shell", saved[id]))
	var glass: Mesh = saved[id + "_glass"]
	if glass.get_surface_count() > 0:
		door.add_child(_mi("Glass", glass))
	var length := band.y - band.x
	var z_mid := (band.x + band.y) * 0.5
	door.add_child(_mi("Card", saved["door_card"], Vector3(side * 0.82, 0.66, z_mid), Basis.from_scale(Vector3(1, 1, length / 0.90))))
	var handle_z := 0.12 if band.y > 0.0 else -0.80
	door.add_child(_mi("Handle", saved["door_handle"], Vector3(0.91 * side, 0.86, handle_z)))
	if with_mirror:
		door.add_child(_mi("Mirror", saved["mirror"], Vector3(0.955 * side, 1.0, 0.70), Basis(Vector3.UP, 0.15 * side)))
		door.add_child(_mi("MirrorStalk", saved["mirror_stalk"], Vector3(0.88 * side, 0.975, 0.72)))
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var box := BoxShape3D.new()
	box.size = Vector3(0.14, 0.85, length)
	shape.shape = box
	shape.position = Vector3(side * 0.88, 0.78, z_mid)
	door.add_child(shape)
	print("  ", id, " surfaces ", (saved[id] as Mesh).get_surface_count(), " glass ", glass.get_surface_count())


func _add_named_part(parent: Node3D, node_name: String, part_id: String, label: String, mesh: Mesh, pos: Vector3, touch: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.set_script(InteractableScript)
	body.set("part_id", part_id)
	body.set("display_name", label)
	body.position = pos
	parent.add_child(body)
	body.add_child(_mi("Mesh", mesh))
	var shape := CollisionShape3D.new()
	shape.name = "TouchTarget"
	var box := BoxShape3D.new()
	box.size = touch
	shape.shape = box
	body.add_child(shape)


## Engine-bay components and plumbing shared by every vehicle with the transverse I4 bay layout.
func _add_bay_parts(bay: Node3D, comp: Dictionary) -> void:
	var parts := _group(bay, "Components")
	_instance(parts, comp["engine_i4"], ENGINE_POS)
	_instance(parts, comp["radiator"], Vector3(0, 0.25, 1.93))
	_instance(parts, comp["battery"], Vector3(-0.46, 0.46, 1.55))
	_instance(parts, comp["air_intake"], Vector3(0.50, 0.60, 1.60))
	_instance(parts, comp["coolant_reservoir"], Vector3(-0.47, 0.57, 1.12))
	_instance(parts, comp["brake_fluid_reservoir"], Vector3(0.42, 0.66, 1.06))
	_instance(parts, comp["washer_reservoir"], Vector3(-0.50, 0.52, 1.84))
	# Gameplay parts sit exactly on the engine model's own filter boss, fill neck and dipstick tube.
	_instance(parts, comp["oil_filter"], _engine_point(Vector3(0.115, 0.305, 0.20)))
	_instance(parts, comp["drain_plug"], _engine_point(Vector3(0.12, 0.0, 0.10)))
	_instance(parts, comp["oil_fill_cap"], _engine_point(Vector3(0.1925, 0.775, 0.0)))
	_instance(parts, comp["dipstick"], _engine_point(Vector3(-0.28, 0.745, -0.19)))

	var hoses := _group(bay, "HosesAndWiring")
	var hose_mat: Material = M["rubber_hose"]
	hoses.add_child(_tube("UpperRadiatorHose", PackedVector3Array([Vector3(0.28, 0.63, 1.84), Vector3(0.30, 0.70, 1.79), Vector3(0.30, 0.66, 1.73)]), 0.022, hose_mat))
	hoses.add_child(_tube("LowerRadiatorHose", PackedVector3Array([Vector3(-0.28, 0.32, 1.84), Vector3(-0.27, 0.27, 1.78), Vector3(-0.20, 0.30, 1.72)]), 0.022, hose_mat))
	hoses.add_child(_tube("HeaterHose", PackedVector3Array([Vector3(-0.15, 0.55, 1.18), Vector3(-0.15, 0.62, 1.06), Vector3(-0.10, 0.60, 0.99)]), 0.012, hose_mat, 8))
	hoses.add_child(_tube("BatteryPositiveCable", PackedVector3Array([Vector3(-0.40, 0.68, 1.56), Vector3(-0.30, 0.72, 1.50), Vector3(-0.22, 0.58, 1.44)]), 0.008, M["brake_caliper"], 6))
	hoses.add_child(_tube("BatteryNegativeCable", PackedVector3Array([Vector3(-0.55, 0.68, 1.58), Vector3(-0.60, 0.66, 1.68), Vector3(-0.63, 0.58, 1.72)]), 0.008, M["trim_black"], 6))
	hoses.add_child(_tube("WiringLoom", PackedVector3Array([Vector3(-0.55, 0.74, 1.10), Vector3(-0.30, 0.80, 1.10), Vector3(0.0, 0.80, 1.14), Vector3(0.25, 0.78, 1.20)]), 0.011, M["trim_black"], 8))


func _assemble_sport_sedan(comp: Dictionary) -> Node3D:
	var car := Node3D.new()
	car.name = "KesslerGT6"
	car.set_script(VehicleScript)
	car.set("vehicle_id", "sport_sedan_a")
	car.set("display_name", "2022 Kessler GT6")
	car.set("family", "sport_sedan")
	car.set("engine_layout", "transverse_inline_4_placeholder")
	car.set("drivetrain", "rwd")
	car.set("lift_point_height", SportSedanAuthor.SILL_Y)
	SportSedanAuthor.new(M, Callable(self, "_save_mesh")).assemble(car)
	_add_bay_parts(car.get_node("EngineBay"), comp)
	return car


## Imports every roster vehicle whose Tripo model is present (data/vehicles/roster.json).
func _build_roster(comp: Dictionary) -> void:
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/vehicles/roster.json"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/vehicles/roster"))
	for spec in roster["vehicles"]:
		if not FileAccess.file_exists(spec["source"]):
			print("  roster: skip %s (no model yet)" % spec["id"])
			continue
		var car := Node3D.new()
		car.name = String(spec["name"]).to_pascal_case().replace(" ", "")
		car.set_script(VehicleScript)
		car.set("vehicle_id", spec["id"])
		car.set("display_name", "%d %s" % [int(spec["year"]), spec["name"]])
		car.set("family", spec["class"])
		car.set("engine_layout", spec["layout"])
		car.set("drivetrain", spec["drivetrain"])
		var importer := TripoVehicleImporter.new(Callable(self, "_save_mesh"))
		var info: Dictionary = importer.assemble(car, spec)
		for line in importer.report:
			print("  ", line)
		car.set("lift_point_height", info["sill"])
		car.set("camera_height_offset", info["height"] - 1.43)
		_generic_bay(car, info, comp, spec)
		_pack(car, "res://scenes/vehicles/roster/%s.tscn" % spec["id"])


## Engine bay sized to an imported vehicle: firewall at the hood hinge, aprons inside the
## fenders, struts over the front wheels, engine and service parts by engine type.
func _generic_bay(car: Node3D, info: Dictionary, comp: Dictionary, spec: Dictionary) -> void:
	var bay := _group(car, "EngineBay")
	var black: Material = M["bay_black"]
	var inner: Material = M["car_paint_inner"]
	var bz: Vector2 = info["bay"]
	var half_w: float = info["width"] * 0.5
	var sill: float = info["sill"]
	var front_axle := 0.0
	for c in info["wheels"]:
		front_axle = maxf(front_axle, c.z)
	var hood_y: float = info["hinge"].y
	var mid := (bz.x + bz.y) * 0.5
	bay.add_child(_mi("Firewall", _save_mesh(Forge.beveled_box(Vector3(half_w * 1.6, hood_y - sill, 0.03), 0.04, black), "%s_firewall" % spec["id"]), Vector3(0, (hood_y + sill) * 0.5, bz.x - 0.01)))
	for side in [1.0, -1.0]:
		bay.add_child(_mi("InnerApron", _save_mesh(Forge.beveled_box(Vector3(0.03, (hood_y - sill) * 0.7, bz.y - bz.x), 0.015, inner), "%s_apron" % spec["id"]), Vector3((half_w - 0.24) * side, sill + (hood_y - sill) * 0.45, mid)))
	bay.add_child(_mi("CoreSupport", _save_mesh(Forge.beveled_box(Vector3(half_w * 1.6, 0.06, 0.06), 0.02, black), "%s_core" % spec["id"]), Vector3(0, hood_y - 0.22, bz.y - 0.05)))
	var parts := _group(bay, "Components")
	var engine: String = spec["engine"]
	if engine == "engine_i6" or engine == "engine_v8":
		# Longitudinal engines (the V8 uses the inline-6 model until a V8 is generated).
		var b := engine_i6_bounds
		var base := Vector3(0, sill - 0.02, clampf(front_axle - 0.10, bz.x - b.position.z + 0.05, bz.y - b.end.z - 0.25))
		_instance(parts, comp["engine_i6"], base)
		var top := base.y + b.size.y
		var ef := base.z + b.end.z
		var er := base.z + b.position.z
		_instance(parts, comp["oil_fill_cap"], Vector3(0.0, top + 0.005, ef - 0.18))
		_instance(parts, comp["dipstick"], Vector3(-0.17, top - 0.06, ef - 0.08))
		_instance(parts, comp["oil_filter"], Vector3(b.end.x + 0.02, base.y + b.size.y * 0.42, lerpf(er, ef, 0.55)), Basis(Vector3.UP, PI * 0.5))
		_instance(parts, comp["drain_plug"], Vector3(0.0, base.y + 0.002, lerpf(er, ef, 0.35)))
		_instance(parts, comp["radiator"], Vector3(0, sill + 0.10, minf(ef + 0.20, bz.y - 0.12)))
	else:
		# Transverse inline-4 over the front axle; service points sit on the model's own features.
		var pos := Vector3(0.08, sill, clampf(front_axle + 0.10, bz.x + 0.35, bz.y - 0.45))
		_instance(parts, comp["engine_i4"], pos)
		var at := func(local: Vector3) -> Vector3: return pos + local * ENGINE_SCALE
		_instance(parts, comp["oil_filter"], at.call(Vector3(0.115, 0.305, 0.20)))
		_instance(parts, comp["drain_plug"], at.call(Vector3(0.12, 0.0, 0.10)))
		_instance(parts, comp["oil_fill_cap"], at.call(Vector3(0.1925, 0.775, 0.0)))
		_instance(parts, comp["dipstick"], at.call(Vector3(-0.28, 0.745, -0.19)))
		_instance(parts, comp["radiator"], Vector3(0, sill + 0.10, minf(pos.z + 0.48, bz.y - 0.12)))
	_instance(parts, comp["battery"], Vector3(-(half_w - 0.45), sill + 0.31, mid + 0.10))
	_instance(parts, comp["coolant_reservoir"], Vector3(-(half_w - 0.45), sill + 0.42, bz.x + 0.20))
	_instance(parts, comp["brake_fluid_reservoir"], Vector3(half_w - 0.50, sill + 0.50, bz.x + 0.14))
	_instance(parts, comp["air_intake"], Vector3(half_w - 0.42, sill + 0.45, mid + 0.15))


## Longitudinal inline-6 bay: engine on the centreline, service points placed on its real faces.
func _add_i6_bay(bay: Node3D, comp: Dictionary) -> void:
	var parts := _group(bay, "Components")
	var b := engine_i6_bounds
	var base := Vector3(0, 0.12, 1.42)
	_instance(parts, comp["engine_i6"], base)
	var top := base.y + b.size.y
	var front := base.z + b.end.z
	var rear := base.z + b.position.z
	_instance(parts, comp["radiator"], Vector3(0, 0.25, front + 0.20))
	_instance(parts, comp["battery"], Vector3(-0.46, 0.46, 1.55))
	_instance(parts, comp["air_intake"], Vector3(0.50, 0.60, 1.60))
	_instance(parts, comp["coolant_reservoir"], Vector3(-0.47, 0.57, 1.12))
	_instance(parts, comp["brake_fluid_reservoir"], Vector3(0.42, 0.66, 1.06))
	_instance(parts, comp["washer_reservoir"], Vector3(-0.50, 0.52, 1.84))
	_instance(parts, comp["oil_fill_cap"], Vector3(0.0, top + 0.005, front - 0.18))
	_instance(parts, comp["dipstick"], Vector3(-0.17, top - 0.06, front - 0.08))
	_instance(parts, comp["oil_filter"], Vector3(b.end.x + 0.02, base.y + b.size.y * 0.42, lerpf(rear, front, 0.55)), Basis(Vector3.UP, PI * 0.5))
	_instance(parts, comp["drain_plug"], Vector3(0.0, base.y + 0.002, lerpf(rear, front, 0.35)))


## The Kessler GT6 built from the Tripo part-segmented model (see tripo_car_author.gd).
func _assemble_tripo_car(comp: Dictionary) -> Node3D:
	var car := Node3D.new()
	car.name = "KesslerGT6"
	car.set_script(VehicleScript)
	car.set("vehicle_id", "sport_sedan_a")
	car.set("display_name", "2022 Kessler GT6")
	car.set("family", "sport_sedan")
	car.set("engine_layout", "transverse_inline_4_placeholder")
	car.set("drivetrain", "rwd")
	var author := TripoCarAuthor.new(M, Callable(self, "_save_mesh"))
	var info: Dictionary = author.assemble(car)
	car.set("lift_point_height", info["sill"])
	# Same bay sheet metal as the procedural GT6, with the longitudinal inline-6.
	SportSedanAuthor.new(M, Callable(self, "_save_mesh"))._bay_structure(car)
	car.get_node("EngineBay/StrutBrace").free()
	car.set("engine_layout", "longitudinal_inline_6_twin_turbo")
	_add_i6_bay(car.get_node("EngineBay"), comp)
	for line in author.report:
		print("  ", line)
	print("  tripo car: hinge=", info["hinge"], " hood=", info["hood_box"], " sill=", info["sill"], " wheels=", info["wheels"])
	return car


func _export_glb(scene_path: String, file_name: String) -> void:
	var node: Node = (load(scene_path) as PackedScene).instantiate()
	root.add_child(node)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_scene(node, state) == OK:
		doc.write_to_filesystem(state, ProjectSettings.globalize_path(MESH_DIR + "blender_source/" + file_name))
		print("exported ", file_name)
	node.queue_free()
