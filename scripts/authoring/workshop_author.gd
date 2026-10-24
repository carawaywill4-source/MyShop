extends RefCounted
## Authors the one-bay workshop: room shell, lighting, and dressed work areas using CC0
## Poly Haven props. Room is 10 m wide (X) x 10.5 m deep (Z) x 4.2 m high. The lift sits at
## the origin, the roller door is behind the car (-Z), the camera side is +Z.

const Forge := preload("res://scripts/authoring/mesh_forge.gd")
const PH := "res://assets/models/polyhaven/%s/%s_1k.gltf"

const HALF_X := 5.0
const BACK_Z := -5.5
const FRONT_Z := 6.4
const HEIGHT := 4.2
const BLOCK_H := 1.3

var M: Dictionary
var save_mesh: Callable


func _init(materials: Dictionary, mesh_saver: Callable) -> void:
	M = materials
	save_mesh = mesh_saver


func _mi(name: String, mesh: Mesh, pos := Vector3.ZERO, basis := Basis.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.transform = Transform3D(basis, pos)
	return mi


func _box(name: String, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	return _mi(name, mesh, pos)


func _prop(parent: Node3D, id: String, pos: Vector3, yaw_deg := 0.0, scale := 1.0, name := "") -> Node3D:
	var node: Node3D = (load(PH % [id, id]) as PackedScene).instantiate()
	node.name = name if name != "" else id.to_pascal_case()
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	node.scale = Vector3.ONE * scale
	parent.add_child(node)
	return node


func build(lift: Node3D, caddy: Node3D, drain_spot: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "WorkshopBay"
	_environment(root)
	_room(root)
	_lighting(root)
	var equipment := Node3D.new()
	equipment.name = "Equipment"
	root.add_child(equipment)
	equipment.add_child(lift)
	equipment.add_child(caddy)
	caddy.position = Vector3(2.35, 0, 1.2)
	equipment.add_child(drain_spot)
	_workbench(root)
	_storage(root)
	_floor_clutter(root)
	var anchor := Marker3D.new()
	anchor.name = "VehicleAnchor"
	root.add_child(anchor)
	return root


func _environment(root: Node3D) -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.09, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.63, 0.66)
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.4
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	world.environment = env
	root.add_child(world)


func _room(root: Node3D) -> void:
	var room := Node3D.new()
	room.name = "Room"
	root.add_child(room)
	var depth := FRONT_Z - BACK_Z
	var cz := (FRONT_Z + BACK_Z) * 0.5
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(HALF_X * 2.0, depth)
	floor_mesh.material = M["garage_floor"]
	(M["garage_floor"] as StandardMaterial3D).uv1_scale = Vector3(HALF_X * 2.0 / 3.0, depth / 3.0, 1)
	room.add_child(_mi("Floor", floor_mesh, Vector3(0, 0, cz)))
	var ceiling := PlaneMesh.new()
	ceiling.size = Vector2(HALF_X * 2.0, depth)
	ceiling.flip_faces = true
	ceiling.material = M["ceiling"]
	room.add_child(_mi("Ceiling", ceiling, Vector3(0, HEIGHT, cz)))
	# Side walls: painted block lower course, profiled steel sheet above, steel cap rail.
	var pilaster: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.18, HEIGHT, 0.24), 0.02, M["wall_trim_steel"]), "pilaster")
	for side in [-1.0, 1.0]:
		var x: float = HALF_X * side
		room.add_child(_box("WallBlock", Vector3(0.2, BLOCK_H, depth), Vector3(x + 0.1 * side, BLOCK_H * 0.5, cz), M["wall_block"]))
		room.add_child(_box("WallSheet", Vector3(0.12, HEIGHT - BLOCK_H, depth), Vector3(x + 0.08 * side, BLOCK_H + (HEIGHT - BLOCK_H) * 0.5, cz), M["wall_sheet"]))
		room.add_child(_box("CapRail", Vector3(0.06, 0.08, depth), Vector3(x - 0.02 * side, BLOCK_H + 0.04, cz), M["wall_trim_steel"]))
		for k in 4:
			var z := BACK_Z + 0.4 + k * (depth - 0.8) / 3.0
			room.add_child(_mi("Pilaster", pilaster, Vector3(x - 0.06 * side, HEIGHT * 0.5, z)))
	# Back wall with the roller door opening behind the car.
	var door_w := 3.54
	var door_h := 2.76
	var seg_w := HALF_X - door_w * 0.5
	for side in [-1.0, 1.0]:
		var sx: float = side * (door_w * 0.5 + seg_w * 0.5)
		room.add_child(_box("BackBlock", Vector3(seg_w, BLOCK_H, 0.2), Vector3(sx, BLOCK_H * 0.5, BACK_Z - 0.1), M["wall_block"]))
		room.add_child(_box("BackSheet", Vector3(seg_w, HEIGHT - BLOCK_H, 0.12), Vector3(sx, BLOCK_H + (HEIGHT - BLOCK_H) * 0.5, BACK_Z - 0.06), M["wall_sheet"]))
		room.add_child(_box("DoorJamb", Vector3(0.14, door_h, 0.18), Vector3(side * (door_w * 0.5 + 0.07), door_h * 0.5, BACK_Z + 0.02), M["safety_yellow"]))
	room.add_child(_box("DoorHeader", Vector3(door_w + 0.28, HEIGHT - door_h, 0.12), Vector3(0, door_h + (HEIGHT - door_h) * 0.5, BACK_Z - 0.06), M["wall_sheet"]))
	room.add_child(_box("HeaderTrim", Vector3(door_w + 0.28, 0.12, 0.2), Vector3(0, door_h + 0.06, BACK_Z + 0.02), M["wall_trim_steel"]))
	# Clean ribbed sectional door (authored; the CC0 roller door carries graffiti).
	var rib := PackedVector2Array()
	var ribs := 23
	for k in ribs:
		var y0 := k * door_h / ribs
		rib.append(Vector2(0.0, y0))
		rib.append(Vector2(0.025, y0 + door_h / ribs * 0.2))
		rib.append(Vector2(0.025, y0 + door_h / ribs * 0.8))
	rib.append(Vector2(0.0, door_h))
	rib.append(Vector2(-0.02, door_h))
	rib.append(Vector2(-0.02, 0.0))
	var door_mesh := Forge.extrude(rib, door_w, M["door_slats"])
	room.add_child(_mi("RollerDoor", save_mesh.call(door_mesh, "roller_door"), Vector3(0, 0, BACK_Z - 0.05), Basis(Vector3.UP, PI * 0.5)))
	# Front wall (behind the bay camera) closes the room for reflections and bounce.
	room.add_child(_box("FrontBlock", Vector3(HALF_X * 2.0, BLOCK_H, 0.2), Vector3(0, BLOCK_H * 0.5, FRONT_Z + 0.1), M["wall_block"]))
	room.add_child(_box("FrontSheet", Vector3(HALF_X * 2.0, HEIGHT - BLOCK_H, 0.12), Vector3(0, BLOCK_H + (HEIGHT - BLOCK_H) * 0.5, FRONT_Z + 0.06), M["wall_sheet"]))
	# Floor markings: bay outline, lift zone hatching, floor drain.
	var line: Material = M["floor_line_yellow"]
	for side in [-1.0, 1.0]:
		room.add_child(_box("BayLine", Vector3(0.09, 0.004, 7.4), Vector3(side * 2.55, 0.002, -0.3), line))
	room.add_child(_box("BayLineFront", Vector3(5.19, 0.004, 0.09), Vector3(0, 0.002, 3.4), line))
	for k in 5:
		room.add_child(_box("Hatch", Vector3(0.5, 0.004, 0.07), Vector3(-2.2 + 0.0, 0.002, 2.7 + k * 0.14), line))
		room.add_child(_box("Hatch", Vector3(0.5, 0.004, 0.07), Vector3(2.2, 0.002, 2.7 + k * 0.14), line))
	room.add_child(_mi("FloorDrain", save_mesh.call(Forge.beveled_box(Vector3(0.42, 0.012, 0.42), 0.01, M["graphite_steel"]), "floor_drain"), Vector3(0.0, 0.003, -0.6), Basis(Vector3.RIGHT, PI * 0.5)))
	var stain := Decal.new()
	stain.name = "OilStain"
	stain.size = Vector3(2.0, 0.4, 2.6)
	stain.position = Vector3(0.1, 0.0, 0.9)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.05, 0.04, 0.03, 0.55))
	grad.set_color(1, Color(0.05, 0.04, 0.03, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	stain.texture_albedo = tex
	room.add_child(stain)
	var sign := Label3D.new()
	sign.name = "BaySign"
	sign.text = "MYSHOP  ·  BAY 1"
	sign.font_size = 72
	sign.pixel_size = 0.004
	sign.position = Vector3(0, 3.45, BACK_Z + 0.02)
	sign.modulate = Color(0.95, 0.93, 0.88)
	sign.outline_size = 0
	room.add_child(sign)


func _lighting(root: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "Lighting"
	root.add_child(lights)
	# One shadowed key from the overhead fixtures; everything else is cheap unshadowed fill.
	var key := DirectionalLight3D.new()
	key.name = "OverheadKey"
	key.rotation_degrees = Vector3(-68, 18, 0)
	key.light_color = Color(1.0, 0.97, 0.92)
	key.light_energy = 0.75
	key.shadow_enabled = true
	key.shadow_blur = 1.6
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	key.directional_shadow_max_distance = 14.0
	lights.add_child(key)
	var tube_mesh: Mesh = save_mesh.call(Forge.beveled_box(Vector3(1.18, 0.03, 0.05), 0.012, M["fluorescent_tube"]), "fluorescent_tube")
	for x in [-1.7, 1.7]:
		for z in [-2.8, 0.0, 2.8]:
			var fixture := _prop(lights, "mounted_fluorescent_lights", Vector3(x, HEIGHT - 0.02, z), 90.0, 1.3, "Fixture")
			fixture.rotation_degrees.x = 180.0
			lights.add_child(_mi("Tube", tube_mesh, Vector3(x, HEIGHT - 0.09, z), Basis(Vector3.UP, PI * 0.5)))
			var omni := OmniLight3D.new()
			omni.name = "FixtureFill"
			omni.position = Vector3(x, HEIGHT - 0.4, z)
			omni.light_color = Color(1.0, 0.96, 0.88)
			omni.light_energy = 0.55
			omni.omni_range = 5.5
			omni.omni_attenuation = 1.2
			lights.add_child(omni)
	var under := OmniLight3D.new()
	under.name = "UnderCarWorkLight"
	under.position = Vector3(0.7, 0.85, 1.6)
	under.light_color = Color(1.0, 0.92, 0.80)
	under.light_energy = 1.3
	under.omni_range = 3.2
	lights.add_child(under)
	var probe := ReflectionProbe.new()
	probe.name = "BayReflections"
	probe.size = Vector3(HALF_X * 2.0, HEIGHT, FRONT_Z - BACK_Z)
	probe.position = Vector3(0, HEIGHT * 0.5, (FRONT_Z + BACK_Z) * 0.5)
	probe.box_projection = true
	probe.interior = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.ambient_mode = ReflectionProbe.AMBIENT_COLOR
	probe.ambient_color = Color(0.5, 0.5, 0.52)
	probe.ambient_color_energy = 0.4
	lights.add_child(probe)


func _workbench(root: Node3D) -> void:
	var area := Node3D.new()
	area.name = "WorkbenchArea"
	area.position = Vector3(HALF_X - 0.42, 0, -1.6)
	area.rotation_degrees.y = -90.0
	root.add_child(area)
	var top: Mesh = save_mesh.call(Forge.beveled_box(Vector3(2.4, 0.05, 0.75), 0.01, M["wood_bench"]), "bench_top")
	var leg: Mesh = save_mesh.call(Forge.beveled_box(Vector3(0.06, 0.86, 0.06), 0.008, M["graphite_steel"]), "bench_leg")
	var rail: Mesh = save_mesh.call(Forge.beveled_box(Vector3(2.3, 0.05, 0.05), 0.008, M["graphite_steel"]), "bench_rail")
	var shelf: Mesh = save_mesh.call(Forge.beveled_box(Vector3(2.3, 0.03, 0.62), 0.008, M["graphite_steel"]), "bench_shelf")
	area.add_child(_mi("Top", top, Vector3(0, 0.885, 0)))
	for x in [-1.12, 1.12]:
		for z in [-0.32, 0.32]:
			area.add_child(_mi("Leg", leg, Vector3(x, 0.43, z)))
	area.add_child(_mi("Rail", rail, Vector3(0, 0.83, 0.33)))
	area.add_child(_mi("LowerShelf", shelf, Vector3(0, 0.16, 0)))
	var board: Mesh = save_mesh.call(Forge.beveled_box(Vector3(2.4, 1.05, 0.025), 0.006, M["pegboard"]), "pegboard")
	area.add_child(_mi("Pegboard", board, Vector3(0, 1.62, -0.36)))
	_prop(area, "bench_vice_01", Vector3(-0.95, 0.91, 0.12), 90.0, 1.0, "BenchVice")
	_prop(area, "metal_toolbox", Vector3(0.75, 0.91, -0.05), 8.0, 1.0, "Toolbox")
	_prop(area, "oil_tin", Vector3(0.25, 0.91, 0.1), -20.0, 1.0, "OilTin")
	_prop(area, "small_oil_can_01", Vector3(0.0, 0.91, -0.15), 35.0, 1.0, "OilCan")
	var wrench := _prop(area, "combination_wrench", Vector3(-0.35, 0.92, 0.2), 70.0, 1.0, "Wrench")
	wrench.rotation_degrees.x = 0.0
	_prop(area, "ratchet_wrench", Vector3(-0.55, 0.915, 0.05), 0.0, 1.0, "Ratchet").rotation_degrees = Vector3(0, 30, 90)
	for k in 6:
		var w := _prop(area, "combination_wrench", Vector3(0.2 + k * 0.09, 1.55 - k * 0.012, -0.33), 0.0, 0.8 + k * 0.06, "PegWrench")
		w.rotation_degrees = Vector3(90, 0, 0)
	for k in 3:
		var r := _prop(area, "ratchet_wrench", Vector3(-0.7 + k * 0.14, 1.65, -0.33), 0.0, 1.0, "PegRatchet")
		r.rotation_degrees = Vector3(0, 0, 0)
	_prop(area, "metal_jerrycan", Vector3(-0.5, 0.18, 0.05), 90.0, 1.0, "Jerrycan")
	_prop(area, "cardboard_box_01", Vector3(0.6, 0.18, 0.0), 12.0, 1.0, "PartsBox")
	# Tool chest and rolling cart near the bay so the bench area reads as the working side.
	_prop(root, "metal_tool_chest", Vector3(HALF_X - 0.45, 0.0, 0.6), -90.0, 1.0, "ToolChest")
	_prop(root, "tool_cart", Vector3(2.55, 0.0, 1.9), -110.0, 1.0, "ToolCart")


func _storage(root: Node3D) -> void:
	var area := Node3D.new()
	area.name = "PartsStorage"
	area.position = Vector3(-HALF_X + 0.35, 0, -2.2)
	area.rotation_degrees.y = 90.0
	root.add_child(area)
	for k in 2:
		var shelf := _prop(area, "steel_frame_shelves_01", Vector3(k * 1.2 - 0.6, 0, 0), 0.0, 0.1, "Shelves")
		shelf.scale = Vector3(0.1, 0.095, 0.1)
	var levels := [0.06, 0.70, 1.33]
	for k in 2:
		for li in levels.size():
			var y: float = levels[li] + 0.02
			var x := k * 1.2 - 0.6
			_prop(area, "cardboard_box_01", Vector3(x - 0.25, y, 0.0), 8.0 * li, 1.0, "Box")
			if li > 0:
				_prop(area, "oil_tin", Vector3(x + 0.12, y, 0.05), 15.0 * k, 1.0, "OilTin")
				_prop(area, "oil_tin", Vector3(x + 0.26, y, -0.05), -10.0, 1.0, "OilTin")
			else:
				_prop(area, "metal_jerrycan", Vector3(x + 0.2, y, 0.0), 0.0, 1.0, "Jerrycan")
	_prop(root, "korean_fire_extinguisher_01", Vector3(-HALF_X + 0.35, 0, -4.6), 90.0, 1.0, "FireExtinguisher")


func _floor_clutter(root: Node3D) -> void:
	var area := Node3D.new()
	area.name = "FloorClutter"
	root.add_child(area)
	for k in 3:
		var tyre := _prop(area, "old_tyre", Vector3(-HALF_X + 0.6, 0.08 + k * 0.16, 1.2), k * 23.0, 1.0, "TyreStack")
		tyre.rotation_degrees.x = 90.0
	var lean := _prop(area, "old_tyre", Vector3(-HALF_X + 0.55, 0.3, 2.05), 90.0, 1.0, "TyreLeaning")
	lean.rotation_degrees = Vector3(0, 90, -12)
	_prop(area, "barrel_03", Vector3(-HALF_X + 0.6, 0, 3.4), 30.0, 1.0, "WasteOilDrum")
	_prop(area, "barrel_03", Vector3(-HALF_X + 0.62, 0, 4.15), -10.0, 1.0, "CoolantDrum")
