extends RefCounted

const SEDAN := "res://assets/models/sources/sedan.glb"
const ENGINE := "res://assets/models/sources/car-engine.glb"
const RADIATOR := "res://assets/models/sources/car-radiator.glb"
const BATTERY := "res://assets/models/sources/car-battery.glb"


func build(root: Node3D, kit) -> Dictionary:
	var car := Node3D.new()
	car.name = "HarborCommute"
	car.position = Vector3(0, 1.12, 0)
	root.add_child(car)

	var sedan := (load(SEDAN) as PackedScene).instantiate()
	sedan.name = "Sedan"
	car.add_child(sedan)
	var body: Node3D = sedan.get_node("body")

	var engine := Node3D.new()
	engine.name = "EngineAssembly"
	engine.position = Vector3(0, 0.08, 0.58)
	car.add_child(engine)

	var engine_model := (load(ENGINE) as PackedScene).instantiate()
	engine_model.name = "EngineBlock"
	engine_model.scale = Vector3(0.78, 0.78, 0.78)
	engine.add_child(engine_model)

	var radiator := (load(RADIATOR) as PackedScene).instantiate()
	radiator.name = "RadiatorAssembly"
	radiator.position = Vector3(0, 0.04, 0.42)
	radiator.scale = Vector3(0.62, 0.62, 0.62)
	engine.add_child(radiator)

	var battery := (load(BATTERY) as PackedScene).instantiate()
	battery.name = "Battery"
	battery.position = Vector3(0.36, 0.02, -0.08)
	battery.scale = Vector3(0.85, 0.85, 0.85)
	engine.add_child(battery)

	var m = kit.materials
	var hood_pick: Node3D = kit.add_pickable_box(body, Vector3(1.1, 0.28, 0.85), Vector3(0, 0.42, 0.45), m.paint, "hood", "Hood")
	for child in hood_pick.get_children():
		if child is MeshInstance3D:
			child.visible = false
	kit.add_pickable_cyl(engine, 0.028, 0.02, Vector3(-0.02, 0.62, 0.02), m.plastic, "fill_cap", "Oil fill cap")
	kit.add_pickable_box(engine, Vector3(0.02, 0.1, 0.02), Vector3(0.16, 0.42, -0.04), m.plastic_yellow, "dipstick", "Dipstick")
	kit.add_pickable_cyl(engine, 0.038, 0.055, Vector3(-0.22, 0.14, 0.06), m.oil_black, "oil_filter", "Oil filter")
	kit.add_pickable_cyl(engine, 0.016, 0.02, Vector3(0.04, 0.02, 0.0), m.steel, "drain_plug", "Drain plug")
	kit.add_pickable_box(root, Vector3(0.46, 0.05, 0.52), Vector3(0.0, 0.38, 0.58), m.plastic_yellow, "drain_pan_spot", "Drain pan spot")

	return {"car": car, "body": body, "engine": engine}
