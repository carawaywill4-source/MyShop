extends StaticBody3D

signal tapped(part_id: String)

@export var part_id: String = ""
@export var display_name: String = ""

var _mesh: MeshInstance3D
var _base_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D


func setup(id: String, label: String, mesh: MeshInstance3D, base_color: Color, source_mat: StandardMaterial3D = null) -> void:
	part_id = id
	display_name = label
	_mesh = mesh
	collision_layer = 2
	collision_mask = 0
	input_ray_pickable = true
	if source_mat:
		_base_material = source_mat.duplicate()
	else:
		_base_material = StandardMaterial3D.new()
		_base_material.albedo_color = base_color
		_base_material.roughness = 0.55
	_highlight_material = _base_material.duplicate()
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(0.95, 0.72, 0.28)
	_highlight_material.emission_energy_multiplier = 0.85
	if _mesh:
		_mesh.material_override = _base_material


func set_highlight(on: bool) -> void:
	if _mesh == null:
		return
	_mesh.material_override = _highlight_material if on else _base_material


func set_visible_part(on: bool) -> void:
	visible = on
	if _mesh:
		_mesh.visible = on


func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
			tapped.emit(part_id)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			tapped.emit(part_id)
