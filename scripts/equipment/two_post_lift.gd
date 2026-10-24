class_name TwoPostLift
extends Node3D
## Two-post lift. Moves both carriages (arms and pads) to a pad height and carries whatever
## vehicle is attached with attach_vehicle(). Height is the top of the lift pads above the floor.

const LOWERED := 0.19
const RAISED := 1.42

@export var pad_height: float = LOWERED:
	set(value):
		pad_height = value
		_apply()

var vehicle: Node3D
var _vehicle_offset := 0.0
var _tween: Tween


func _ready() -> void:
	_apply()


func attach_vehicle(v: Node3D, lift_point_height: float) -> void:
	vehicle = v
	_vehicle_offset = lift_point_height
	_apply()


func move_to(height: float, instant := false) -> void:
	if _tween:
		_tween.kill()
	if instant or not is_inside_tree():
		pad_height = height
		return
	var duration := clampf(absf(height - pad_height) * 1.4, 0.25, 1.6)
	_tween = create_tween()
	_tween.tween_property(self, "pad_height", height, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply() -> void:
	if not is_inside_tree():
		return
	for carriage in [get_node_or_null("LeftPost/Carriage"), get_node_or_null("RightPost/Carriage")]:
		if carriage:
			carriage.position.y = pad_height
	if vehicle:
		vehicle.position.y = pad_height - _vehicle_offset
