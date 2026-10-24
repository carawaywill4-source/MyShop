extends RefCounted


func build(car: Node3D, root: Node3D, kit) -> void:
	var m = kit.materials
	var engine := Node3D.new()
	engine.name = "EngineAssembly"
	engine.position = Vector3(0.04, 0.18, 1.12)
	car.add_child(engine)

	var block := Node3D.new()
	block.name = "EngineBlock"
	engine.add_child(block)
	kit.add_box(block, Vector3(0.46, 0.28, 0.52), Vector3(0, 0.02, 0), m.cast_metal)
	kit.add_box(block, Vector3(0.42, 0.10, 0.48), Vector3(0, 0.20, 0), m.cast_metal)
	kit.add_box(block, Vector3(0.08, 0.12, 0.12), Vector3(-0.26, -0.02, 0.18), m.steel)
	kit.add_box(block, Vector3(0.08, 0.12, 0.12), Vector3(0.26, -0.02, 0.18), m.steel)

	var head := Node3D.new()
	head.name = "CylinderHead"
	engine.add_child(head)
	kit.add_box(head, Vector3(0.40, 0.10, 0.46), Vector3(0, 0.28, 0), m.aluminum)

	var cover := Node3D.new()
	cover.name = "ValveCover"
	engine.add_child(cover)
	kit.add_box(cover, Vector3(0.36, 0.07, 0.42), Vector3(0, 0.36, 0), m.plastic)
	for i in 3:
		kit.add_box(cover, Vector3(0.30, 0.015, 0.02), Vector3(0, 0.40, -0.12 + i * 0.12), m.plastic)
	kit.add_cyl(cover, 0.012, 0.03, Vector3(-0.14, 0.405, -0.16), m.steel)
	kit.add_cyl(cover, 0.012, 0.03, Vector3(0.14, 0.405, -0.16), m.steel)
	kit.add_cyl(cover, 0.012, 0.03, Vector3(-0.14, 0.405, 0.16), m.steel)
	kit.add_cyl(cover, 0.012, 0.03, Vector3(0.14, 0.405, 0.16), m.steel)

	kit.add_pickable_cyl(cover, 0.035, 0.05, Vector3(-0.10, 0.42, 0.12), m.plastic, "fill_cap", "Oil fill cap")
	kit.add_pickable_box(engine, Vector3(0.03, 0.16, 0.03), Vector3(0.20, 0.28, -0.10), m.tail_lens, "dipstick", "Dipstick")

	var intake := Node3D.new()
	intake.name = "IntakeAssembly"
	engine.add_child(intake)
	kit.add_box(intake, Vector3(0.30, 0.10, 0.18), Vector3(0, 0.30, -0.28), m.aluminum)
	kit.add_cyl(intake, 0.045, 0.10, Vector3(0.12, 0.30, -0.36), m.aluminum, Vector3(1.2, 0, 0))
	kit.add_box(intake, Vector3(0.12, 0.08, 0.08), Vector3(0.12, 0.30, -0.42), m.plastic)
	kit.add_cyl(intake, 0.04, 0.22, Vector3(0.28, 0.30, -0.22), m.hose, Vector3(0, 0, 1.2))
	kit.add_box(intake, Vector3(0.22, 0.16, 0.18), Vector3(0.42, 0.22, -0.05), m.plastic)

	var alt := Node3D.new()
	alt.name = "Alternator"
	engine.add_child(alt)
	kit.add_cyl(alt, 0.07, 0.12, Vector3(-0.28, 0.10, 0.22), m.aluminum, Vector3(0, 0, 1.5708))
	kit.add_cyl(alt, 0.035, 0.04, Vector3(-0.28, 0.10, 0.30), m.steel, Vector3(0, 0, 1.5708))

	kit.add_cyl(engine, 0.09, 0.03, Vector3(-0.16, 0.12, 0.30), m.steel, Vector3(1.5708, 0, 0))
	kit.add_cyl(engine, 0.06, 0.03, Vector3(0.10, 0.08, 0.30), m.steel, Vector3(1.5708, 0, 0))
	kit.add_torus(engine, 0.09, 0.11, Vector3(-0.03, 0.10, 0.30), m.rubber, Vector3(1.5708, 0, 0))

	var rad := Node3D.new()
	rad.name = "RadiatorAssembly"
	rad.position = Vector3(0, 0.12, 0.48)
	engine.add_child(rad)
	kit.add_box(rad, Vector3(0.62, 0.32, 0.06), Vector3(0, 0, 0), m.aluminum)
	kit.add_box(rad, Vector3(0.58, 0.28, 0.02), Vector3(0, 0, -0.03), m.cast_metal)
	kit.add_cyl(rad, 0.11, 0.03, Vector3(0, 0.02, -0.06), m.plastic, Vector3(1.5708, 0, 0))
	kit.add_box(rad, Vector3(0.16, 0.03, 0.02), Vector3(0, 0.02, -0.07), m.steel)
	kit.add_box(rad, Vector3(0.03, 0.16, 0.02), Vector3(0, 0.02, -0.07), m.steel)
	kit.add_cyl(engine, 0.018, 0.28, Vector3(-0.22, 0.18, 0.32), m.hose, Vector3(1.1, 0, 0))
	kit.add_cyl(engine, 0.018, 0.22, Vector3(0.20, 0.06, 0.32), m.hose, Vector3(1.1, 0, 0))

	var battery := Node3D.new()
	battery.name = "Battery"
	engine.add_child(battery)
	kit.add_box(battery, Vector3(0.18, 0.14, 0.12), Vector3(0.42, 0.10, 0.28), m.plastic)
	kit.add_cyl(battery, 0.015, 0.03, Vector3(0.37, 0.18, 0.28), m.tail_lens)
	kit.add_cyl(battery, 0.015, 0.03, Vector3(0.47, 0.18, 0.28), m.steel)
	kit.add_cyl(engine, 0.008, 0.26, Vector3(0.30, 0.22, 0.12), m.plastic, Vector3(0, 0, 1.0))

	var coolant := Node3D.new()
	coolant.name = "CoolantReservoir"
	engine.add_child(coolant)
	kit.add_box(coolant, Vector3(0.10, 0.16, 0.08), Vector3(0.40, 0.22, 0.42), m.plastic_white)
	kit.add_cyl(coolant, 0.02, 0.03, Vector3(0.40, 0.31, 0.42), m.plastic)

	var brake := Node3D.new()
	brake.name = "BrakeFluidReservoir"
	engine.add_child(brake)
	kit.add_box(brake, Vector3(0.08, 0.08, 0.08), Vector3(-0.38, 0.32, -0.28), m.plastic_white)

	var pan := Node3D.new()
	pan.name = "OilPan"
	engine.add_child(pan)
	kit.add_box(pan, Vector3(0.36, 0.10, 0.40), Vector3(0, -0.16, 0.0), m.cast_metal)
	kit.add_pickable_cyl(pan, 0.022, 0.04, Vector3(0.10, -0.22, 0.06), m.steel, "drain_plug", "Drain plug")
	kit.add_pickable_cyl(engine, 0.045, 0.09, Vector3(-0.18, -0.08, 0.18), m.oil_black, "oil_filter", "Oil filter", Vector3(0, 0, 0.7))

	kit.add_box(engine, Vector3(0.08, 0.10, 0.08), Vector3(-0.26, -0.02, -0.18), m.steel)
	kit.add_box(engine, Vector3(0.08, 0.10, 0.08), Vector3(0.26, -0.02, -0.18), m.steel)

	kit.add_pickable_box(root, Vector3(0.42, 0.08, 0.55), Vector3(0.12, 0.34, 1.18), m.plastic_yellow, "drain_pan_spot", "Drain pan spot")
	kit.add_box(root, Vector3(0.36, 0.05, 0.48), Vector3(0.12, 0.38, 1.18), m.oil_black)
