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
var _hood_tween: Tween

@onready var hood_pivot: Node3D = get_node_or_null("Body/HoodPivot")


func _ready() -> void:
	for node in find_children("*", "Node3D", true, false):
		if node is RepairableComponent:
			components[node.component_id] = node


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
