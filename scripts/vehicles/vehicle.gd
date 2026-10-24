class_name Vehicle
extends Node3D
## Runtime side of a vehicle scene (scenes/vehicles/*.tscn): identity, hood animation, and a
## lookup of its RepairableComponents. Contains no job rules.

@export var vehicle_id: String = ""
@export var display_name: String = ""
## Mechanical family / layout, so future vehicles differ mechanically, not only visually.
@export var family: String = ""
@export var engine_layout: String = ""
@export var drivetrain: String = ""
## Height of the lift pickup points (pinch welds) above the vehicle origin, in metres.
@export var lift_point_height: float = 0.19
@export var hood_open_degrees: float = 58.0
## How much taller than the reference sedan this vehicle is; gameplay cameras rise by this.
@export var camera_height_offset: float = 0.0

var components: Dictionary = {}
var panels: Dictionary = {}
var _hood_tween: Tween
var _panel_tweens: Dictionary = {}

@onready var hood_pivot: Node3D = get_node_or_null("Body/HoodPivot")

## Side panels Tripo split out, which the importer left glued to the body. Hinge is the
## forward, inboard edge. shop_world.gd set_panel_open and main.gd door taps call this.
const _DOOR_PARTS := {
	"Paint_20": {"id": "door_fl", "label": "Front left door"},
	"Paint_30": {"id": "door_fr", "label": "Front right door"},
	"Paint_24": {"id": "door_rl", "label": "Rear left door"},
	"Paint_17": {"id": "door_rr", "label": "Rear right door"},
}


func _ready() -> void:
	_rig_separated_doors()
	_register_scene_panels()
	_place_driver_camera()
	_ensure_cabin_light()
	for node in find_children("*", "Node3D", true, false):
		if node is RepairableComponent:
			components[node.component_id] = node


func has_interior() -> bool:
	return get_node_or_null("Interior/SteeringWheel") != null


func driver_eye_global() -> Vector3:
	var eye := get_node_or_null("Interior/DriverEye") as Node3D
	if eye:
		return eye.global_position
	var seat := get_node_or_null("Interior/FrontSeat") as Node3D
	if seat == null:
		return global_position
	return seat.global_position + global_transform.basis * Vector3(0, 0.5, -0.2)


func driver_look_global() -> Vector3:
	var look := get_node_or_null("Interior/ClusterLook") as Node3D
	if look:
		return look.global_position
	var wheel := get_node_or_null("Interior/SteeringWheel") as Node3D
	if wheel == null:
		return global_position + global_transform.basis * Vector3(0, 0.9, 0.4)
	return wheel.global_position


func set_check_engine(on: bool) -> void:
	var lamp := get_node_or_null("Interior/CheckEngineLamp") as MeshInstance3D
	if lamp == null:
		return
	var mat := lamp.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		lamp.material_override = mat
	mat.emission_enabled = true
	mat.albedo_color = Color(1.0, 0.28, 0.05) if on else Color(0.22, 0.04, 0.02)
	mat.emission = Color(1.0, 0.16, 0.02) if on else Color(0.04, 0.0, 0.0)
	mat.emission_energy_multiplier = 4.0 if on else 0.0


func set_panel_open(panel_id: String, open: bool, instant := false) -> bool:
	var pivot := panels.get(panel_id) as Node3D
	if pivot == null:
		return false
	var sign := float(pivot.get_meta("open_sign", 1.0 if pivot.position.x < 0.0 else -1.0))
	var target := sign * (0.95 if open else 0.0)
	if _panel_tweens.has(panel_id) and _panel_tweens[panel_id]:
		(_panel_tweens[panel_id] as Tween).kill()
	if instant or not is_inside_tree():
		pivot.rotation.y = target
		return true
	var tween := create_tween()
	_panel_tweens[panel_id] = tween
	tween.tween_property(pivot, "rotation:y", target, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return true


func _rig_separated_doors() -> void:
	var body := get_node_or_null("Body") as Node3D
	if body == null:
		return
	for node_name in _DOOR_PARTS:
		var mesh := body.get_node_or_null(String(node_name)) as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var spec: Dictionary = _DOOR_PARTS[node_name]
		var bounds := mesh.mesh.get_aabb()
		var hinge := Vector3(
			bounds.position.x if bounds.get_center().x > 0.0 else bounds.end.x,
			bounds.get_center().y,
			bounds.end.z
		)
		var pivot := Node3D.new()
		pivot.name = String(spec["id"])
		pivot.position = hinge
		var door := StaticBody3D.new()
		door.set_script(load("res://scripts/interactable.gd"))
		door.set("part_id", spec["id"])
		door.set("display_name", spec["label"])
		pivot.add_child(door)
		mesh.get_parent().remove_child(mesh)
		door.add_child(mesh)
		mesh.position = -hinge
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = bounds.size
		shape.shape = box
		shape.position = -hinge + bounds.get_center()
		door.add_child(shape)
		body.add_child(pivot)
		panels[spec["id"]] = pivot


func _place_driver_camera() -> void:
	var eye := get_node_or_null("Interior/DriverEye") as Node3D
	if eye:
		eye.position = Vector3(0.10, 1.05, -0.08)
	var look := get_node_or_null("Interior/ClusterLook") as Node3D
	if look:
		look.position = Vector3(0.28, 0.96, 0.48)
	var cluster := get_node_or_null("Interior/Cluster") as Node3D
	if cluster:
		cluster.position = Vector3(0.36, 1.06, 0.60)
	var left := get_node_or_null("Interior/GaugeLeft") as Node3D
	if left:
		left.position = Vector3(0.28, 1.07, 0.63)
	var right := get_node_or_null("Interior/GaugeRight") as Node3D
	if right:
		right.position = Vector3(0.44, 1.07, 0.63)
	var lamp := get_node_or_null("Interior/CheckEngineLamp") as Node3D
	if lamp:
		lamp.position = Vector3(0.52, 1.10, 0.60)
		lamp.scale = Vector3(2.4, 2.4, 1.4)
	var obd := get_node_or_null("Interior/ObdPort") as Node3D
	if obd:
		obd.position = Vector3(0.18, 0.78, 0.40)
	var wheel := get_node_or_null("Interior/SteeringWheel") as Node3D
	if wheel:
		wheel.position = Vector3(0.34, 0.98, 0.40)


func _ensure_cabin_light() -> void:
	var interior := get_node_or_null("Interior") as Node3D
	if interior == null or interior.get_node_or_null("CabinLight") != null:
		return
	var light := OmniLight3D.new()
	light.name = "CabinLight"
	light.position = Vector3(0.1, 1.15, 0.2)
	light.light_color = Color(1.0, 0.94, 0.86)
	light.light_energy = 2.4
	light.omni_range = 2.4
	light.shadow_enabled = false
	interior.add_child(light)


func _register_scene_panels() -> void:
	for id in ["door_fl", "door_fr", "door_rl", "door_rr"]:
		if panels.has(id):
			continue
		var pivot := find_child(id, true, false) as Node3D
		if pivot:
			panels[id] = pivot


func get_component(component_id: String) -> RepairableComponent:
	return components.get(component_id)


func set_hood_open(open: bool, instant := false) -> void:
	if hood_pivot == null:
		return
	var target := Vector3(-deg_to_rad(hood_open_degrees) if open else 0.0, 0, 0)
	if _hood_tween:
		_hood_tween.kill()
	if instant or not is_inside_tree():
		hood_pivot.rotation = target
		return
	_hood_tween = create_tween()
	_hood_tween.tween_property(hood_pivot, "rotation", target, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
