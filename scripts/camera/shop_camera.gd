class_name ShopCamera
extends Camera3D
## Fixed gameplay camera with named view presets (Bay, Under car, Engine). Positions are
## world space for the workshop_bay scene with the lift at the origin. Framing leaves room
## for the HUD bars at the top and bottom of a landscape phone screen.

const VIEWS := {
	"bay": {"pos": Vector3(3.9, 2.15, 5.7), "look": Vector3(-0.1, 1.45, 0.0), "fov": 50.0},
	"under": {"pos": Vector3(0.35, 0.72, 3.05), "look": Vector3(0.16, 1.42, 1.50), "fov": 50.0},
	"engine": {"pos": Vector3(0.55, 2.05, 2.35), "look": Vector3(0.0, 0.85, 1.15), "fov": 48.0},
}

var _tween: Tween


## height_offset raises the engine-bay framing for taller vehicles (SUVs, trucks).
func go_to(view_name: String, instant := false, height_offset := 0.0) -> void:
	var preset: Dictionary = VIEWS.get(view_name, VIEWS["bay"])
	var lift := Vector3(0, height_offset if view_name == "engine" else height_offset * 0.5, 0)
	if view_name == "under":
		lift = Vector3.ZERO
	var pos: Vector3 = preset["pos"] + lift
	var look: Vector3 = preset["look"] + lift
	var target := Transform3D.IDENTITY.looking_at(look - pos, Vector3.UP)
	target.origin = pos
	if _tween:
		_tween.kill()
	if instant or not is_inside_tree():
		transform = target
		fov = preset["fov"]
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "transform", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "fov", preset["fov"], 0.55)


## Called by shop_world.gd for the cabin view. No other camera helper frames a moving seat.
func look_from(eye: Vector3, focus: Vector3, camera_fov: float, instant := false) -> void:
	var target := Transform3D.IDENTITY.looking_at(focus - eye, Vector3.UP)
	target.origin = eye
	if _tween:
		_tween.kill()
	if instant or not is_inside_tree():
		transform = target
		fov = camera_fov
		return
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "transform", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "fov", camera_fov, 0.55)
