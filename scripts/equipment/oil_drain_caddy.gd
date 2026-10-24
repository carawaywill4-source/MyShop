class_name OilDrainCaddy
extends Node3D
## Rolling oil drain caddy. Parked beside the bay until the player places it under the car.

@export var parked_position := Vector3(2.35, 0, 1.2)
@export var funnel_lowered := 0.62
@export var funnel_raised := 1.18

var _tween: Tween


func place(under_position: Vector3, raised: bool, instant := false) -> void:
	_move(under_position, funnel_raised if raised else funnel_lowered, instant)


func park(instant := false) -> void:
	_move(parked_position, funnel_lowered, instant)


func _move(pos: Vector3, funnel_y: float, instant: bool) -> void:
	var funnel := get_node_or_null("Funnel") as Node3D
	if _tween:
		_tween.kill()
	if instant or not is_inside_tree():
		position = pos
		if funnel:
			funnel.position.y = funnel_y
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position", pos, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if funnel:
		_tween.tween_property(funnel, "position:y", funnel_y, 0.7)
