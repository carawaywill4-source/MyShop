extends Node3D

const ShopInteractableScript := preload("res://scripts/interactable.gd")

signal part_tapped(part_id: String)

const VIEW_BAY := "bay"
const VIEW_UNDER := "under"
const VIEW_ENGINE := "engine"

var camera: Camera3D
var hood: Node3D
var oil_stream: MeshInstance3D
var parts: Dictionary = {}

var _view := VIEW_BAY
var _tweens: Tween


func _ready() -> void:
	_build_environment()
	_build_shop()
	_build_lift()
	_build_car()
	_build_camera()
	set_view(VIEW_BAY, true)


func set_view(view_name: String, instant: bool = false) -> void:
	_view = view_name
	var target := Transform3D.IDENTITY
	match view_name:
		VIEW_UNDER:
			target.origin = Vector3(0.15, 0.38, 2.15)
			target = target.looking_at(Vector3(0.1, 0.22, 0.1), Vector3.UP)
		VIEW_ENGINE:
			target.origin = Vector3(0.55, 1.55, 1.55)
			target = target.looking_at(Vector3(0.0, 1.05, 0.15), Vector3.UP)
		_:
			target.origin = Vector3(3.4, 1.8, 3.6)
			target = target.looking_at(Vector3(0.0, 0.7, 0.0), Vector3.UP)
	if instant or camera == null:
		camera.global_transform = target
		return
	if _tweens:
		_tweens.kill()
	_tweens = create_tween()
	_tweens.tween_property(camera, "global_transform", target, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_hood_open(open: bool) -> void:
	var angle := -1.15 if open else 0.0
	var tween := create_tween()
	tween.tween_property(hood, "rotation:x", angle, 0.35)


func set_part_visible(part_id: String, on: bool) -> void:
	if parts.has(part_id):
		parts[part_id].set_visible_part(on)


func set_highlight(part_id: String, on: bool) -> void:
	for id in parts:
		parts[id].set_highlight(id == part_id and on)


func set_oil_draining(on: bool) -> void:
	if oil_stream:
		oil_stream.visible = on


func _add_box(parent: Node3D, size: Vector3, origin: Vector3, color: Color, pickable_id: String = "", label: String = "") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = origin
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	mesh.material_override = mat
	if pickable_id == "":
		parent.add_child(mesh)
		return mesh
	var body := ShopInteractableScript.new()
	parent.add_child(body)
	body.position = origin
	mesh.position = Vector3.ZERO
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.setup(pickable_id, label, mesh, color)
	body.tapped.connect(_on_part_tapped)
	parts[pickable_id] = body
	return mesh


func _add_cylinder(parent: Node3D, radius: float, height: float, origin: Vector3, color: Color, rot_z: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	mesh.position = origin
	mesh.rotation.z = rot_z
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.43, 0.46)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	add_child(sun)


func _build_shop() -> void:
	_add_box(self, Vector3(12, 0.12, 10), Vector3(0, -0.06, 0), Color(0.22, 0.22, 0.24))
	_add_box(self, Vector3(12, 3.2, 0.16), Vector3(0, 1.6, -4.8), Color(0.33, 0.31, 0.28))
	_add_box(self, Vector3(0.16, 3.2, 10), Vector3(-5.8, 1.6, 0), Color(0.30, 0.29, 0.27))
	_add_box(self, Vector3(2.4, 1.1, 0.7), Vector3(-4.2, 0.55, -3.8), Color(0.28, 0.32, 0.36))
	_add_box(self, Vector3(0.7, 1.4, 0.45), Vector3(3.6, 0.7, -3.6), Color(0.18, 0.18, 0.2))
	var bench_label := Label3D.new()
	bench_label.text = "BAY 1"
	bench_label.position = Vector3(-4.2, 1.25, -3.4)
	bench_label.font_size = 48
	bench_label.modulate = Color(0.92, 0.78, 0.42)
	add_child(bench_label)


func _build_lift() -> void:
	var lift := Node3D.new()
	lift.name = "Lift"
	add_child(lift)
	var yellow := Color(0.86, 0.72, 0.18)
	_add_box(lift, Vector3(0.18, 1.15, 0.18), Vector3(-1.15, 0.52, 1.1), yellow)
	_add_box(lift, Vector3(0.18, 1.15, 0.18), Vector3(1.15, 0.52, 1.1), yellow)
	_add_box(lift, Vector3(0.18, 1.15, 0.18), Vector3(-1.15, 0.52, -1.3), yellow)
	_add_box(lift, Vector3(0.18, 1.15, 0.18), Vector3(1.15, 0.52, -1.3), yellow)
	_add_box(lift, Vector3(2.6, 0.08, 0.22), Vector3(0, 1.08, 1.1), yellow)
	_add_box(lift, Vector3(2.6, 0.08, 0.22), Vector3(0, 1.08, -1.3), yellow)


func _build_car() -> void:
	var car := Node3D.new()
	car.name = "HarborCommute"
	car.position = Vector3(0, 1.12, 0)
	add_child(car)
	var body := Color(0.27, 0.42, 0.58)
	var dark := Color(0.12, 0.13, 0.15)
	_add_box(car, Vector3(1.85, 0.42, 3.5), Vector3(0, 0.28, 0.05), body)
	_add_box(car, Vector3(1.7, 0.38, 1.7), Vector3(0, 0.68, -0.15), Color(0.22, 0.34, 0.48))
	_add_cylinder(car, 0.28, 0.18, Vector3(-0.82, 0.02, 1.15), dark, PI * 0.5)
	_add_cylinder(car, 0.28, 0.18, Vector3(0.82, 0.02, 1.15), dark, PI * 0.5)
	_add_cylinder(car, 0.28, 0.18, Vector3(-0.82, 0.02, -1.2), dark, PI * 0.5)
	_add_cylinder(car, 0.28, 0.18, Vector3(0.82, 0.02, -1.2), dark, PI * 0.5)

	hood = Node3D.new()
	hood.name = "HoodPivot"
	hood.position = Vector3(0, 0.48, 1.15)
	car.add_child(hood)
	_add_box(hood, Vector3(1.7, 0.06, 1.15), Vector3(0, 0.03, 0.55), Color(0.30, 0.45, 0.61), "hood", "Hood")

	_add_box(car, Vector3(0.16, 0.07, 0.16), Vector3(-0.22, 0.52, 1.35), Color(0.18, 0.18, 0.2), "fill_cap", "Oil fill cap")
	_add_box(car, Vector3(0.12, 0.08, 0.28), Vector3(0.28, 0.50, 1.05), Color(0.55, 0.18, 0.16), "dipstick", "Dipstick")
	_add_box(car, Vector3(0.12, 0.08, 0.12), Vector3(0.18, -0.08, 0.35), Color(0.45, 0.45, 0.48), "drain_plug", "Drain plug")
	_add_cylinder_part(car, 0.07, 0.11, Vector3(-0.22, -0.06, 0.18), Color(0.16, 0.16, 0.18), "oil_filter", "Oil filter")
	_add_box(self, Vector3(0.55, 0.08, 0.7), Vector3(0.05, 0.04, 0.25), Color(0.35, 0.36, 0.32), "drain_pan_spot", "Drain pan spot")

	oil_stream = MeshInstance3D.new()
	var stream := CylinderMesh.new()
	stream.top_radius = 0.012
	stream.bottom_radius = 0.018
	stream.height = 0.42
	oil_stream.mesh = stream
	oil_stream.position = Vector3(0.18, 0.85, 0.35)
	var oil_mat := StandardMaterial3D.new()
	oil_mat.albedo_color = Color(0.12, 0.09, 0.05)
	oil_stream.material_override = oil_mat
	oil_stream.visible = false
	add_child(oil_stream)

	var plate := Label3D.new()
	plate.text = "HARBOR COMMUTE"
	plate.position = Vector3(0, 0.18, 1.82)
	plate.font_size = 28
	plate.modulate = Color(0.92, 0.92, 0.9)
	car.add_child(plate)


func _add_cylinder_part(parent: Node3D, radius: float, height: float, origin: Vector3, color: Color, pickable_id: String, label: String) -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	var body := ShopInteractableScript.new()
	parent.add_child(body)
	body.position = origin
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = height
	shape.shape = cyl_shape
	body.add_child(shape)
	body.setup(pickable_id, label, mesh, color)
	body.tapped.connect(_on_part_tapped)
	parts[pickable_id] = body


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 52
	add_child(camera)


func _on_part_tapped(part_id: String) -> void:
	part_tapped.emit(part_id)
