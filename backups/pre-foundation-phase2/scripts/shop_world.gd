extends Node3D

const MaterialsScript := preload("res://scripts/visuals/shop_materials.gd")
const MeshKitScript := preload("res://scripts/visuals/mesh_kit.gd")
const WorkshopBuilder := preload("res://scripts/visuals/workshop_builder.gd")
const AssetStage := preload("res://scripts/visuals/asset_stage.gd")

signal part_tapped(part_id: String)

const VIEW_BAY := "bay"
const VIEW_UNDER := "under"
const VIEW_ENGINE := "engine"

var camera: Camera3D
var hood: Node3D
var body_mesh: Node3D
var engine_root: Node3D
var oil_stream: MeshInstance3D
var parts: Dictionary = {}

var _view := VIEW_BAY
var _tweens: Tween
var _job_hood_open := false
var _body_rest := Vector3.ZERO


func _ready() -> void:
	var kit = MeshKitScript.new()
	kit.world = self
	kit.materials = MaterialsScript.new()
	kit.parts = parts
	kit.tapped_callback = _on_part_tapped
	_build_environment()
	WorkshopBuilder.new().build(self, kit)
	var stage: Dictionary = AssetStage.new().build(self, kit)
	hood = stage["body"]
	body_mesh = stage["body"]
	engine_root = stage["engine"]
	_body_rest = body_mesh.position
	_build_oil_stream()
	_build_camera()
	set_view(VIEW_BAY, true)


func set_view(view_name: String, instant: bool = false) -> void:
	_view = view_name
	var target := Transform3D.IDENTITY
	match view_name:
		VIEW_UNDER:
			camera.fov = 40
			target.origin = Vector3(0.0, 0.52, 1.9)
			target = target.looking_at(Vector3(0.0, 1.22, 0.35), Vector3.UP)
		VIEW_ENGINE:
			camera.fov = 34
			target.origin = Vector3(0.0, 1.92, 2.55)
			target = target.looking_at(Vector3(0.0, 1.5, 0.32), Vector3.UP)
		_:
			camera.fov = 48
			target.origin = Vector3(1.55, 1.42, 5.45)
			target = target.looking_at(Vector3(0.05, 1.15, 0.1), Vector3.UP)
	_apply_hood_for_view()
	if instant or camera == null:
		camera.global_transform = target
		return
	if _tweens:
		_tweens.kill()
	_tweens = create_tween()
	_tweens.tween_property(camera, "global_transform", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_hood_open(open: bool) -> void:
	_job_hood_open = open
	_apply_hood_for_view()


func _apply_hood_for_view() -> void:
	if engine_root:
		engine_root.visible = true
	if body_mesh == null:
		return
	var lift := 0.0
	if _view == VIEW_ENGINE or _job_hood_open:
		lift = 1.15
	elif _view == VIEW_UNDER:
		lift = 0.48
	body_mesh.position = _body_rest + Vector3(0, lift, 0)


func set_part_visible(part_id: String, on: bool) -> void:
	if parts.has(part_id):
		parts[part_id].set_visible_part(on)


func set_highlight(part_id: String, on: bool) -> void:
	for id in parts:
		parts[id].set_highlight(id == part_id and on)


func set_oil_draining(on: bool) -> void:
	if oil_stream:
		oil_stream.visible = on


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.72, 0.82)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.45, 0.42)
	env.ambient_light_energy = 1.05
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.05
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.shadow_enabled = false
	add_child(sun)
	var bay := OmniLight3D.new()
	bay.position = Vector3(0.2, 2.55, 0.8)
	bay.light_color = Color(1.0, 0.96, 0.88)
	bay.light_energy = 1.35
	bay.omni_range = 6.0
	bay.shadow_enabled = false
	add_child(bay)
	var daylight := DirectionalLight3D.new()
	daylight.rotation_degrees = Vector3(-18, 180, 0)
	daylight.light_energy = 0.85
	daylight.light_color = Color(0.86, 0.92, 1.0)
	daylight.shadow_enabled = false
	add_child(daylight)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-18, 130, 0)
	fill.light_energy = 0.4
	fill.light_color = Color(0.85, 0.90, 1.0)
	fill.shadow_enabled = false
	add_child(fill)
	var under := OmniLight3D.new()
	under.position = Vector3(0.1, 0.45, 1.15)
	under.light_color = Color(1.0, 0.92, 0.75)
	under.light_energy = 0.9
	under.omni_range = 1.8
	under.shadow_enabled = false
	add_child(under)


func _build_oil_stream() -> void:
	oil_stream = MeshInstance3D.new()
	var stream := CylinderMesh.new()
	stream.top_radius = 0.01
	stream.bottom_radius = 0.016
	stream.height = 0.38
	oil_stream.mesh = stream
	var oil_mat := StandardMaterial3D.new()
	oil_mat.albedo_color = Color(0.10, 0.07, 0.04)
	oil_stream.material_override = oil_mat
	oil_stream.visible = false
	add_child(oil_stream)
	if parts.has("drain_plug"):
		var plug: Node3D = parts["drain_plug"]
		oil_stream.global_position = plug.global_position + Vector3(0, -0.22, 0)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 48
	add_child(camera)


func _on_part_tapped(part_id: String) -> void:
	part_tapped.emit(part_id)
