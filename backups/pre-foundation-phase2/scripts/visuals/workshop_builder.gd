extends RefCounted

const MeshKitScript := preload("res://scripts/visuals/mesh_kit.gd")

const POST_X := 1.72
const PAD_X := 0.42
const PAD_Z := 0.66
const PAD_Y := 1.02


func build(root: Node3D, kit) -> void:
	_floor(root, kit)
	_walls(root, kit)
	_door(root, kit)
	_lift(root, kit)
	_benches(root, kit)
	_service_gear(root, kit)
	_lights(root, kit)


static func _floor(root: Node3D, kit) -> void:
	var m = kit.materials
	kit.add_box(root, Vector3(14, 0.08, 12), Vector3(0, -0.04, 0), m.concrete)
	kit.add_box(root, Vector3(2.6, 0.012, 3.4), Vector3(0, 0.012, 0.15), m.oil_stain)
	var stripe: StandardMaterial3D = m.safety_yellow
	kit.add_box(root, Vector3(4.6, 0.01, 0.08), Vector3(0, 0.005, 2.55), stripe)
	kit.add_box(root, Vector3(4.6, 0.01, 0.08), Vector3(0, 0.005, -2.55), stripe)
	kit.add_box(root, Vector3(0.08, 0.01, 5.1), Vector3(-2.3, 0.005, 0), stripe)
	kit.add_box(root, Vector3(0.08, 0.01, 5.1), Vector3(2.3, 0.005, 0), stripe)
	for i in 6:
		kit.add_box(root, Vector3(0.7, 0.006, 0.18), Vector3(-5.4 + i * 0.85, 0.004, 4.4), m.paint_dark)


static func _walls(root: Node3D, kit) -> void:
	var m = kit.materials
	var wall: StandardMaterial3D = m.shop_wall
	kit.add_box(root, Vector3(14, 3.4, 0.16), Vector3(0, 1.7, -5.7), wall)
	var sign := Label3D.new()
	sign.text = "BAY 1"
	sign.position = Vector3(0, 2.35, -5.58)
	sign.rotation_degrees = Vector3(0, 180, 0)
	sign.font_size = 96
	sign.modulate = Color(0.16, 0.18, 0.20)
	sign.outline_modulate = Color(0.86, 0.70, 0.16)
	sign.outline_size = 16
	root.add_child(sign)
	kit.add_box(root, Vector3(0.16, 3.4, 12), Vector3(-6.9, 1.7, 0), wall)
	kit.add_box(root, Vector3(0.16, 3.4, 12), Vector3(6.9, 1.7, 0), wall)
	kit.add_box(root, Vector3(14, 0.12, 12), Vector3(0, 3.42, 0), m.cast_metal)
	kit.add_box(root, Vector3(0.12, 0.18, 11.4), Vector3(-2.2, 3.28, 0), m.steel)
	kit.add_box(root, Vector3(0.12, 0.18, 11.4), Vector3(2.2, 3.28, 0), m.steel)


static func _lift(root: Node3D, kit) -> void:
	var m = kit.materials
	var lift := Node3D.new()
	lift.name = "TwoPostLift"
	root.add_child(lift)
	for side in [-1.0, 1.0]:
		kit.add_box(lift, Vector3(0.28, 2.45, 0.34), Vector3(POST_X * side, 1.22, 0), m.steel)
		kit.add_box(lift, Vector3(0.38, 0.08, 0.46), Vector3(POST_X * side, 0.04, 0), m.cast_metal)
		kit.add_box(lift, Vector3(0.22, 0.34, 0.28), Vector3(POST_X * side, PAD_Y, 0), m.safety_yellow)
		for z_sign in [-1.0, 1.0]:
			var arm_z: float = PAD_Z * z_sign
			var mid_x: float = (POST_X * side + PAD_X * side) * 0.5
			kit.add_box(lift, Vector3(absf(POST_X - PAD_X), 0.07, 0.11), Vector3(mid_x, PAD_Y, arm_z), m.safety_yellow)
			kit.add_box(lift, Vector3(0.22, 0.06, 0.22), Vector3(PAD_X * side, PAD_Y + 0.04, arm_z), m.rubber)
			kit.add_box(lift, Vector3(0.16, 0.03, 0.16), Vector3(PAD_X * side, PAD_Y + 0.08, arm_z), m.steel)
	kit.add_box(lift, Vector3(3.55, 0.08, 0.12), Vector3(0, 2.38, 0), m.steel)
	kit.add_cyl(lift, 0.025, 0.42, Vector3(0.28, 2.12, 0.22), m.hose)
	var lamp_head := StandardMaterial3D.new()
	lamp_head.albedo_color = Color(0.95, 0.93, 0.84)
	lamp_head.emission_enabled = true
	lamp_head.emission = Color(1.0, 0.94, 0.78)
	lamp_head.emission_energy_multiplier = 1.4
	kit.add_box(lift, Vector3(0.28, 0.06, 0.16), Vector3(0.28, 1.88, 0.22), lamp_head)


static func _benches(root: Node3D, kit) -> void:
	var m = kit.materials
	var cabinet := Node3D.new()
	cabinet.name = "ToolCabinet"
	cabinet.position = Vector3(-4.55, 0, -3.7)
	root.add_child(cabinet)
	kit.add_box(cabinet, Vector3(1.35, 0.92, 0.58), Vector3(0, 0.46, 0), m.paint_dark)
	for i in 4:
		kit.add_box(cabinet, Vector3(1.22, 0.08, 0.04), Vector3(0, 0.22 + i * 0.18, 0.28), m.steel)
		kit.add_box(cabinet, Vector3(0.16, 0.03, 0.04), Vector3(0, 0.22 + i * 0.18, 0.31), m.aluminum)

	var bench := Node3D.new()
	bench.name = "Workbench"
	bench.position = Vector3(4.4, 0, -3.55)
	root.add_child(bench)
	kit.add_box(bench, Vector3(1.8, 0.08, 0.7), Vector3(0, 0.86, 0), m.cast_metal)
	kit.add_box(bench, Vector3(0.1, 0.82, 0.1), Vector3(-0.78, 0.41, -0.26), m.steel)
	kit.add_box(bench, Vector3(0.1, 0.82, 0.1), Vector3(0.78, 0.41, -0.26), m.steel)
	kit.add_box(bench, Vector3(0.1, 0.82, 0.1), Vector3(-0.78, 0.41, 0.26), m.steel)
	kit.add_box(bench, Vector3(0.1, 0.82, 0.1), Vector3(0.78, 0.41, 0.26), m.steel)
	kit.add_box(bench, Vector3(0.42, 0.08, 0.28), Vector3(-0.55, 0.95, 0.05), m.plastic)
	kit.add_cyl(bench, 0.07, 0.18, Vector3(-0.12, 1.00, 0.08), m.steel)
	kit.add_cyl(bench, 0.05, 0.22, Vector3(0.18, 1.02, -0.08), m.safety_yellow, Vector3(0, 0, 0.6))
	kit.add_box(bench, Vector3(0.22, 0.16, 0.16), Vector3(0.55, 0.98, 0.1), m.plastic)
	kit.add_cyl(bench, 0.09, 0.22, Vector3(0.72, 0.97, -0.12), m.oil_black)

	var board := Node3D.new()
	board.name = "Pegboard"
	board.position = Vector3(4.4, 1.55, -4.0)
	root.add_child(board)
	kit.add_box(board, Vector3(1.7, 0.95, 0.04), Vector3(0, 0, 0), m.rust_dark)
	for i in 5:
		kit.add_cyl(board, 0.012, 0.16, Vector3(-0.6 + i * 0.28, 0.18, 0.08), m.steel, Vector3(1.2, 0, 0))
		kit.add_box(board, Vector3(0.04, 0.22, 0.03), Vector3(-0.6 + i * 0.28, -0.12, 0.06), m.aluminum)

	var shelves := Node3D.new()
	shelves.name = "PartsShelves"
	shelves.position = Vector3(-5.9, 0, 1.2)
	root.add_child(shelves)
	kit.add_box(shelves, Vector3(0.7, 1.7, 1.6), Vector3(0, 0.85, 0), m.paint_dark)
	for i in 3:
		kit.add_box(shelves, Vector3(0.62, 0.04, 1.48), Vector3(0, 0.35 + i * 0.42, 0), m.steel)
		kit.add_box(shelves, Vector3(0.16, 0.14, 0.12), Vector3(-0.16, 0.46 + i * 0.42, -0.4), m.plastic_yellow)
		kit.add_box(shelves, Vector3(0.16, 0.14, 0.12), Vector3(0.14, 0.46 + i * 0.42, 0.15), m.plastic_white)


static func _door(root: Node3D, kit) -> void:
	var m = kit.materials
	var wall_z := 4.15
	var wall: StandardMaterial3D = m.shop_wall
	kit.add_box(root, Vector3(5.2, 3.4, 0.16), Vector3(-4.4, 1.7, wall_z), wall)
	kit.add_box(root, Vector3(5.2, 3.4, 0.16), Vector3(4.4, 1.7, wall_z), wall)
	kit.add_box(root, Vector3(3.5, 0.7, 0.16), Vector3(0, 3.05, wall_z), wall)
	for i in 5:
		var slat_y: float = 2.72 - float(i) * 0.08
		kit.add_box(root, Vector3(3.35, 0.06, 0.08), Vector3(0, slat_y, wall_z + 0.02), m.steel)
	kit.add_box(root, Vector3(0.08, 2.7, 0.1), Vector3(-1.72, 1.35, wall_z), m.safety_yellow)
	kit.add_box(root, Vector3(0.08, 2.7, 0.1), Vector3(1.72, 1.35, wall_z), m.safety_yellow)
	kit.add_cyl(root, 0.08, 0.55, Vector3(-1.95, 0.85, wall_z - 0.2), m.drum_red)


static func _service_gear(root: Node3D, kit) -> void:
	var m = kit.materials
	var cart := Node3D.new()
	cart.name = "ToolCart"
	cart.position = Vector3(1.55, 0, -0.15)
	root.add_child(cart)
	kit.add_box(cart, Vector3(0.55, 0.04, 0.38), Vector3(0, 0.78, 0), m.steel)
	kit.add_box(cart, Vector3(0.5, 0.22, 0.34), Vector3(0, 0.62, 0), m.paint)
	kit.add_box(cart, Vector3(0.5, 0.16, 0.34), Vector3(0, 0.4, 0), m.paint_dark)
	kit.add_cyl(cart, 0.04, 0.08, Vector3(-0.18, 0.06, 0.12), m.rubber)
	kit.add_cyl(cart, 0.04, 0.08, Vector3(0.18, 0.06, 0.12), m.rubber)
	kit.add_cyl(cart, 0.04, 0.08, Vector3(-0.18, 0.06, -0.12), m.rubber)
	kit.add_cyl(cart, 0.04, 0.08, Vector3(0.18, 0.06, -0.12), m.rubber)
	for i in 4:
		kit.add_cyl(cart, 0.012, 0.16, Vector3(-0.16 + float(i) * 0.1, 0.86, 0), m.aluminum)

	var drum := Node3D.new()
	drum.name = "WasteOil"
	drum.position = Vector3(-2.15, 0, -1.7)
	root.add_child(drum)
	kit.add_cyl(drum, 0.28, 0.9, Vector3(0, 0.45, 0), m.cast_metal)
	kit.add_box(drum, Vector3(0.5, 0.08, 0.02), Vector3(0, 0.55, 0.27), m.safety_yellow)
	kit.add_cyl(drum, 0.06, 0.08, Vector3(0, 0.94, 0), m.oil_black)

	for i in 3:
		kit.add_cyl(root, 0.06, 0.22, Vector3(2.15, 0.2, -1.35 + float(i) * 0.16), m.plastic_yellow)


static func _lights(root: Node3D, kit) -> void:
	var m = kit.materials
	for x in [-2.0, 2.0]:
		kit.add_box(root, Vector3(1.6, 0.08, 0.22), Vector3(x, 3.22, 0.2), m.steel)
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(0.92, 0.90, 0.82)
		glow.emission_enabled = true
		glow.emission = Color(0.95, 0.92, 0.8)
		glow.emission_energy_multiplier = 0.8
		kit.add_box(root, Vector3(1.45, 0.04, 0.14), Vector3(x, 3.16, 0.2), glow)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(x, 2.85, 0.35)
		lamp.light_color = Color(1.0, 0.96, 0.86)
		lamp.light_energy = 0.55
		lamp.omni_range = 6.5
		lamp.shadow_enabled = false
		root.add_child(lamp)
