extends Node3D
## The 3D world for the current job: loads the workshop and vehicle scenes, routes taps from
## Interactables to gameplay (main.gd), and maps gameplay state onto visuals. Job rules live
## in main.gd; visuals live in the scenes under res://scenes/.

const WORKSHOP_SCENE := preload("res://scenes/workshop/workshop_bay.tscn")
const DEFAULT_VEHICLE := "res://scenes/vehicles/kessler_gt6.tscn"
const ROSTER_DIR := "res://scenes/vehicles/roster/"
const ShopCameraScript := preload("res://scripts/camera/shop_camera.gd")
const OIL_MATERIAL := preload("res://assets/materials/used_oil.tres")

signal part_tapped(part_id: String)

const VIEW_BAY := "bay"
const VIEW_UNDER := "under"
const VIEW_ENGINE := "engine"

var camera: Camera3D
var workshop: Node3D
var vehicle: Vehicle
var lift: TwoPostLift
var caddy: OilDrainCaddy
var drain_spot: Node3D
var oil_stream: MeshInstance3D
var parts: Dictionary = {}
var vehicle_paths: Array[String] = []
var vehicle_index := 0

var _view := VIEW_BAY
var _pan_placed := false
var _draining := false


func _ready() -> void:
	workshop = WORKSHOP_SCENE.instantiate()
	add_child(workshop)
	lift = workshop.get_node("Equipment/TwoPostLift")
	caddy = workshop.get_node("Equipment/OilDrainCaddy")
	drain_spot = workshop.get_node("Equipment/DrainPanSpot")
	vehicle_paths = [DEFAULT_VEHICLE]
	var dir := DirAccess.open(ROSTER_DIR)
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tscn") or file.ends_with(".tscn.remap"):
				vehicle_paths.append(ROSTER_DIR + file.trim_suffix(".remap"))
	camera = ShopCameraScript.new()
	add_child(camera)
	camera.make_current()
	load_vehicle(0)


## Swaps the car on the lift. Only call between jobs; job state is not carried over.
func load_vehicle(index: int) -> void:
	vehicle_index = posmod(index, vehicle_paths.size())
	if vehicle:
		vehicle.get_parent().remove_child(vehicle)
		vehicle.free()
	vehicle = (load(vehicle_paths[vehicle_index]) as PackedScene).instantiate()
	workshop.get_node("VehicleAnchor").add_child(vehicle)
	lift.attach_vehicle(vehicle, vehicle.lift_point_height)
	parts.clear()
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var part_id: String = node.get("part_id")
		parts[part_id] = node
		if not node.tapped.is_connected(_on_part_tapped):
			node.tapped.connect(_on_part_tapped)
	_build_oil_stream()
	set_view(VIEW_BAY, true)


func next_vehicle() -> void:
	load_vehicle(vehicle_index + 1)


func vehicle_label() -> String:
	return vehicle.display_name if vehicle else ""


func set_view(view_name: String, instant: bool = false) -> void:
	_view = view_name
	camera.go_to(view_name, instant, vehicle.camera_height_offset if vehicle else 0.0)
	_apply_lift(instant)


func set_hood_open(open: bool) -> void:
	vehicle.set_hood_open(open)


func set_part_visible(part_id: String, on: bool) -> void:
	if parts.has(part_id):
		parts[part_id].set_visible_part(on)
	var component := vehicle.get_component(part_id)
	if component:
		component.state = RepairableComponent.State.INSTALLED if on else RepairableComponent.State.REMOVED


func set_highlight(part_id: String, on: bool) -> void:
	for id in parts:
		parts[id].set_highlight(id == part_id and on)


func set_oil_draining(on: bool) -> void:
	_draining = on
	oil_stream.visible = on
	if on:
		_apply_lift(false)


func set_drain_pan_placed(placed: bool) -> void:
	_pan_placed = placed
	_apply_lift(false)


## Engine work happens with the car lowered; underside work with it raised. The car stays
## up while oil is draining so the stream keeps landing in the caddy.
func _apply_lift(instant: bool) -> void:
	var raised := _view != VIEW_ENGINE or _draining
	lift.move_to(TwoPostLift.RAISED if raised else TwoPostLift.LOWERED, instant)
	var plug := _drain_plug_world_xz()
	if _pan_placed and raised:
		caddy.place(Vector3(plug.x, 0, plug.z), true, instant)
	else:
		caddy.park(instant)
	drain_spot.position = Vector3(plug.x, caddy.funnel_raised, plug.z)
	drain_spot.visible = raised and not _pan_placed
	drain_spot.input_ray_pickable = drain_spot.visible
	var spot_shape := drain_spot.get_node_or_null("TouchTarget") as CollisionShape3D
	if spot_shape:
		spot_shape.set_deferred("disabled", not drain_spot.visible)


func _drain_plug_world_xz() -> Vector3:
	if parts.has("drain_plug"):
		var p: Vector3 = parts["drain_plug"].global_position
		return Vector3(p.x, 0, p.z)
	return Vector3.ZERO


func _build_oil_stream() -> void:
	oil_stream = MeshInstance3D.new()
	oil_stream.name = "OilStream"
	var stream := CylinderMesh.new()
	stream.top_radius = 0.006
	stream.bottom_radius = 0.011
	stream.height = 0.36
	stream.radial_segments = 8
	stream.material = OIL_MATERIAL
	oil_stream.mesh = stream
	oil_stream.visible = false
	vehicle.add_child(oil_stream)
	if parts.has("drain_plug"):
		var plug: Node3D = parts["drain_plug"]
		oil_stream.position = vehicle.to_local(plug.global_position) + Vector3(0, -0.20, 0)


func _on_part_tapped(part_id: String) -> void:
	part_tapped.emit(part_id)
