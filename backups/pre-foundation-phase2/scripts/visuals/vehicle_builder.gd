extends RefCounted

const WHEEL_Z := 1.26
const WHEEL_X := 0.74
const WHEEL_Y := -0.36
const PAD_Y := 1.02


func build(root: Node3D, kit) -> Dictionary:
	var car := Node3D.new()
	car.name = "HarborCommute"
	car.position = Vector3(0, PAD_Y + 0.08, 0)
	root.add_child(car)
	_body(car, kit)
	_glass(car, kit)
	_lights(car, kit)
	_wheels(car, kit)
	var hood := _hood(car, kit)
	_undercarriage(car, kit)
	_mirrors(car, kit)
	var plate := Label3D.new()
	plate.text = "HARBOR COMMUTE"
	plate.position = Vector3(0, 0.18, 2.04)
	plate.font_size = 22
	plate.modulate = Color(0.9, 0.9, 0.88)
	car.add_child(plate)
	return {"car": car, "hood": hood}


static func _body(car: Node3D, kit) -> void:
	var m = kit.materials
	kit.add_box(car, Vector3(1.64, 0.42, 2.15), Vector3(0, 0.28, -0.42), m.paint)
	kit.add_box(car, Vector3(1.46, 0.58, 1.36), Vector3(0, 0.82, -0.38), m.paint)
	kit.add_box(car, Vector3(1.36, 0.06, 1.40), Vector3(0, 1.13, -0.36), m.paint_dark)
	kit.add_box(car, Vector3(0.10, 0.42, 1.15), Vector3(-0.72, 0.36, 1.12), m.paint)
	kit.add_box(car, Vector3(0.10, 0.42, 1.15), Vector3(0.72, 0.36, 1.12), m.paint)
	kit.add_box(car, Vector3(1.46, 0.08, 0.18), Vector3(0, 0.12, 1.55), m.cast_metal)
	kit.add_box(car, Vector3(1.46, 0.36, 0.08), Vector3(0, 0.32, 0.58), m.paint_dark)
	kit.add_box(car, Vector3(0.07, 0.46, 0.9), Vector3(-0.74, 0.78, 0.18), m.paint)
	kit.add_box(car, Vector3(0.07, 0.46, 0.9), Vector3(0.74, 0.78, 0.18), m.paint)
	kit.add_box(car, Vector3(0.07, 0.38, 0.55), Vector3(-0.72, 0.74, -0.95), m.paint)
	kit.add_box(car, Vector3(0.07, 0.38, 0.55), Vector3(0.72, 0.74, -0.95), m.paint)
	kit.add_box(car, Vector3(1.70, 0.24, 0.26), Vector3(0, 0.24, 1.86), m.paint_dark)
	kit.add_box(car, Vector3(1.68, 0.22, 0.24), Vector3(0, 0.22, -1.84), m.paint_dark)
	kit.add_box(car, Vector3(0.06, 0.26, 2.2), Vector3(-0.84, 0.18, -0.2), m.paint_dark)
	kit.add_box(car, Vector3(0.06, 0.26, 2.2), Vector3(0.84, 0.18, -0.2), m.paint_dark)
	for z in [-WHEEL_Z, WHEEL_Z]:
		for x in [-WHEEL_X, WHEEL_X]:
			kit.add_box(car, Vector3(0.20, 0.26, 0.48), Vector3(x, 0.06, z), m.plastic)


static func _glass(car: Node3D, kit) -> void:
	var m = kit.materials
	kit.add_box(car, Vector3(1.28, 0.40, 0.06), Vector3(0, 0.72, 0.28), m.glass, Vector3(-0.55, 0, 0))
	kit.add_box(car, Vector3(1.32, 0.30, 0.05), Vector3(0, 0.76, -1.02), m.glass, Vector3(0.28, 0, 0))
	kit.add_box(car, Vector3(0.04, 0.28, 0.85), Vector3(-0.80, 0.76, -0.18), m.glass)
	kit.add_box(car, Vector3(0.04, 0.28, 0.85), Vector3(0.80, 0.76, -0.18), m.glass)


static func _lights(car: Node3D, kit) -> void:
	var m = kit.materials
	kit.add_box(car, Vector3(0.32, 0.12, 0.08), Vector3(-0.58, 0.28, 1.98), m.light_lens)
	kit.add_box(car, Vector3(0.32, 0.12, 0.08), Vector3(0.58, 0.28, 1.98), m.light_lens)
	kit.add_box(car, Vector3(0.36, 0.11, 0.07), Vector3(-0.56, 0.26, -1.96), m.tail_lens)
	kit.add_box(car, Vector3(0.36, 0.11, 0.07), Vector3(0.56, 0.26, -1.96), m.tail_lens)
	kit.add_cyl(car, 0.035, 0.05, Vector3(0, 0.18, 2.02), m.steel, Vector3(1.5708, 0, 0))


static func _wheels(car: Node3D, kit) -> void:
	var m = kit.materials
	for x in [-WHEEL_X, WHEEL_X]:
		for z in [-WHEEL_Z, WHEEL_Z]:
			var wheel := Node3D.new()
			wheel.position = Vector3(x, WHEEL_Y, z)
			car.add_child(wheel)
			var axle := Vector3(0.0, 1.5708, 0.0)
			kit.add_torus(wheel, 0.21, 0.31, Vector3.ZERO, m.rubber, axle)
			kit.add_cyl(wheel, 0.17, 0.13, Vector3.ZERO, m.aluminum, axle)
			kit.add_cyl(wheel, 0.06, 0.15, Vector3.ZERO, m.steel, axle)
			for i in 5:
				var angle := i * TAU / 5.0
				kit.add_box(wheel, Vector3(0.04, 0.16, 0.03), Vector3(0, cos(angle) * 0.08, sin(angle) * 0.08), m.aluminum)
			kit.add_cyl(wheel, 0.13, 0.05, Vector3(0.03 * signf(x), 0, 0), m.cast_metal, axle)


static func _hood(car: Node3D, kit) -> Node3D:
	var m = kit.materials
	var hood := Node3D.new()
	hood.name = "HoodPivot"
	hood.position = Vector3(0, 0.50, 0.62)
	car.add_child(hood)
	kit.add_pickable_box(hood, Vector3(1.52, 0.05, 1.22), Vector3(0, 0.03, 0.62), m.paint, "hood", "Hood")
	kit.add_box(hood, Vector3(0.04, 0.03, 1.05), Vector3(-0.38, 0.07, 0.62), m.paint_dark)
	kit.add_box(hood, Vector3(0.04, 0.03, 1.05), Vector3(0.38, 0.07, 0.62), m.paint_dark)
	return hood


static func _undercarriage(car: Node3D, kit) -> void:
	var m = kit.materials
	var under := Node3D.new()
	under.name = "Undercarriage"
	car.add_child(under)
	kit.add_box(under, Vector3(1.28, 0.05, 2.85), Vector3(0, 0.02, 0.05), m.cast_metal)
	kit.add_box(under, Vector3(0.08, 0.08, 2.6), Vector3(-0.42, 0.0, 0.0), m.steel)
	kit.add_box(under, Vector3(0.08, 0.08, 2.6), Vector3(0.42, 0.0, 0.0), m.steel)
	kit.add_box(under, Vector3(0.42, 0.16, 0.55), Vector3(0.0, -0.02, -0.15), m.cast_metal)
	kit.add_cyl(under, 0.045, 1.55, Vector3(-0.28, -0.08, -0.35), m.rust_dark, Vector3(1.5708, 0, 0))
	kit.add_box(under, Vector3(0.22, 0.16, 0.42), Vector3(-0.28, -0.10, -1.15), m.cast_metal)
	kit.add_cyl(under, 0.04, 0.35, Vector3(-0.28, -0.10, -1.42), m.rust_dark, Vector3(1.5708, 0, 0))
	kit.add_box(under, Vector3(0.55, 0.02, 0.35), Vector3(0.0, -0.06, 0.55), m.steel)
	for z in [-WHEEL_Z, WHEEL_Z]:
		kit.add_box(under, Vector3(1.15, 0.05, 0.08), Vector3(0, -0.12, z), m.steel)
		kit.add_box(under, Vector3(0.08, 0.05, 0.38), Vector3(-0.42, -0.16, z), m.cast_metal)
		kit.add_box(under, Vector3(0.08, 0.05, 0.38), Vector3(0.42, -0.16, z), m.cast_metal)
		kit.add_cyl(under, 0.11, 0.04, Vector3(-WHEEL_X + 0.12, WHEEL_Y + 0.02, z), m.rust_dark, Vector3(0, 0, 1.5708))
		kit.add_cyl(under, 0.11, 0.04, Vector3(WHEEL_X - 0.12, WHEEL_Y + 0.02, z), m.rust_dark, Vector3(0, 0, 1.5708))
	kit.add_box(under, Vector3(0.18, 0.04, 0.18), Vector3(-0.80, 0.0, 1.00), m.rubber)
	kit.add_box(under, Vector3(0.18, 0.04, 0.18), Vector3(0.80, 0.0, 1.00), m.rubber)
	kit.add_box(under, Vector3(0.18, 0.04, 0.18), Vector3(-0.80, 0.0, -1.00), m.rubber)
	kit.add_box(under, Vector3(0.18, 0.04, 0.18), Vector3(0.80, 0.0, -1.00), m.rubber)


static func _mirrors(car: Node3D, kit) -> void:
	var m = kit.materials
	kit.add_box(car, Vector3(0.18, 0.08, 0.12), Vector3(-0.92, 0.62, 0.55), m.paint)
	kit.add_box(car, Vector3(0.18, 0.08, 0.12), Vector3(0.92, 0.62, 0.55), m.paint)
	kit.add_box(car, Vector3(0.14, 0.07, 0.02), Vector3(-1.00, 0.62, 0.50), m.aluminum)
	kit.add_box(car, Vector3(0.14, 0.07, 0.02), Vector3(1.00, 0.62, 0.50), m.aluminum)
