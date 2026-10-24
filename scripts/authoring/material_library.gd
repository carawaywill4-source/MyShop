extends RefCounted
## Shared MyShop materials. Stylized realism: clean PBR values, real roughness/metal ranges,
## restrained palette. build_foundation.gd saves each one to res://assets/materials/<name>.tres
## so scenes share them and they can be tuned in the Godot inspector.

const TEX := "res://assets/textures/polyhaven/"

var mats: Dictionary = {}


func build() -> Dictionary:
	# Vehicle
	var paint := _pbr("car_paint_harbor_blue", Color(0.10, 0.30, 0.42), 0.26, 0.55)
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.7
	paint.clearcoat_roughness = 0.12
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pbr("car_paint_inner", Color(0.07, 0.17, 0.24), 0.6, 0.2).cull_mode = BaseMaterial3D.CULL_DISABLED
	# Kessler GT6: deep metallic green with a hard clearcoat, gloss-black and carbon trim.
	var sedan := _pbr("sedan_paint", Color(0.04, 0.36, 0.24), 0.24, 0.6)
	sedan.clearcoat_enabled = true
	sedan.clearcoat = 0.9
	sedan.clearcoat_roughness = 0.06
	sedan.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pbr("piano_black", Color(0.012, 0.013, 0.015), 0.08, 0.2)
	var carbon := _pbr("carbon_roof", Color(0.035, 0.037, 0.04), 0.24, 0.35)
	carbon.clearcoat_enabled = true
	carbon.clearcoat = 0.8
	_pbr("grille_mesh", Color(0.02, 0.02, 0.022), 0.6, 0.3)
	var drl := _pbr("drl", Color(0.95, 0.97, 1.0), 0.2, 0.0)
	drl.emission_enabled = true
	drl.emission = Color(0.85, 0.92, 1.0)
	drl.emission_energy_multiplier = 2.2
	_pbr("exhaust_tip", Color(0.16, 0.16, 0.17), 0.18, 1.0)
	_pbr("tyre_rubber", Color(0.045, 0.045, 0.048), 0.88, 0.0)
	_pbr("wheel_dark", Color(0.24, 0.25, 0.26), 0.3, 0.9)
	_pbr("wheel_machined", Color(0.78, 0.79, 0.80), 0.2, 1.0)
	var glass := _pbr("car_glass", Color(0.05, 0.07, 0.08, 0.72), 0.03, 0.5)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pbr("trim_black", Color(0.035, 0.037, 0.04), 0.55, 0.0)
	_pbr("trim_chrome", Color(0.82, 0.84, 0.86), 0.12, 1.0)
	_pbr("underbody", Color(0.17, 0.17, 0.18), 0.85, 0.05).cull_mode = BaseMaterial3D.CULL_DISABLED
	_pbr("interior_fabric", Color(0.13, 0.13, 0.14), 0.95, 0.0)
	_pbr("interior_plastic", Color(0.07, 0.07, 0.075), 0.7, 0.0)
	_pbr("wheel_alloy", Color(0.70, 0.72, 0.74), 0.28, 0.9)
	_pbr("brake_disc", Color(0.42, 0.41, 0.40), 0.45, 0.85)
	_pbr("brake_caliper", Color(0.06, 0.20, 0.62), 0.35, 0.3)
	var head := _pbr("headlight_lens", Color(0.80, 0.86, 0.92, 0.85), 0.05, 0.6)
	head.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	head.emission_enabled = true
	head.emission = Color(0.55, 0.62, 0.70)
	head.emission_energy_multiplier = 0.15
	var tail := _pbr("taillight_lens", Color(0.55, 0.05, 0.05), 0.1, 0.3)
	tail.emission_enabled = true
	tail.emission = Color(0.45, 0.03, 0.03)
	tail.emission_energy_multiplier = 0.5
	var amber := _pbr("indicator_lens", Color(0.85, 0.45, 0.08), 0.12, 0.3)
	amber.emission_enabled = true
	amber.emission = Color(0.5, 0.25, 0.02)
	amber.emission_energy_multiplier = 0.3
	_pbr("plate", Color(0.92, 0.92, 0.88), 0.5, 0.0)
	# Engine bay
	_pbr("cast_aluminum", Color(0.60, 0.61, 0.62), 0.42, 0.85)
	_pbr("engine_black", Color(0.05, 0.05, 0.055), 0.45, 0.1)
	_pbr("cast_iron", Color(0.20, 0.20, 0.21), 0.7, 0.6)
	_pbr("bay_black", Color(0.05, 0.05, 0.055), 0.72, 0.0)
	_pbr("rubber_hose", Color(0.04, 0.04, 0.045), 0.8, 0.0)
	_pbr("oil_filter_blue", Color(0.06, 0.24, 0.62), 0.38, 0.35)
	_pbr("zinc_bolt", Color(0.72, 0.70, 0.62), 0.32, 0.95)
	_pbr("cap_yellow", Color(0.95, 0.72, 0.08), 0.45, 0.0)
	var tank := _pbr("reservoir_plastic", Color(0.86, 0.85, 0.80, 0.82), 0.4, 0.0)
	tank.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var coolant := _pbr("coolant_fluid", Color(0.95, 0.35, 0.55), 0.3, 0.0)
	coolant.emission_enabled = true
	coolant.emission = Color(0.3, 0.05, 0.1)
	_pbr("used_oil", Color(0.06, 0.04, 0.02), 0.12, 0.2)
	# Equipment
	_pbr("lift_red", Color(0.62, 0.08, 0.06), 0.42, 0.25)
	_pbr("graphite_steel", Color(0.16, 0.17, 0.18), 0.5, 0.65)
	_pbr("bare_steel", Color(0.55, 0.56, 0.57), 0.35, 0.95)
	_pbr("rubber_pad", Color(0.06, 0.06, 0.06), 0.9, 0.0)
	_pbr("safety_yellow", Color(0.93, 0.70, 0.06), 0.5, 0.05)
	_pbr("caddy_yellow", Color(0.88, 0.62, 0.05), 0.45, 0.2)
	var ghost := _pbr("placement_ghost", Color(1.0, 0.78, 0.2, 0.35), 0.5, 0.0)
	ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.emission_enabled = true
	ghost.emission = Color(0.9, 0.6, 0.1)
	ghost.emission_energy_multiplier = 0.6
	ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_pbr("wood_bench", Color(0.52, 0.36, 0.21), 0.7, 0.0)
	_pbr("pegboard", Color(0.62, 0.52, 0.38), 0.85, 0.0)
	var tube := _pbr("fluorescent_tube", Color(1, 1, 0.96), 0.3, 0.0)
	tube.emission_enabled = true
	tube.emission = Color(1.0, 0.97, 0.90)
	tube.emission_energy_multiplier = 3.0
	# Room
	var floor := _textured("garage_floor", "garage_floor", Color(0.70, 0.71, 0.72), Vector3(0.33, 0.33, 0.33), true)
	floor.roughness = 0.85
	var wall := _textured("wall_block", "concrete_block_wall", Color(1.0, 0.99, 0.96), Vector3(0.45, 0.45, 0.45), true)
	wall.uv1_triplanar = true
	var sheet := _textured("wall_sheet", "box_profile_metal_sheet", Color(0.92, 0.95, 0.97), Vector3(0.5, 0.5, 0.5), true)
	sheet.uv1_triplanar = true
	sheet.metallic = 0.4
	_pbr("wall_trim_steel", Color(0.30, 0.32, 0.34), 0.5, 0.6)
	_pbr("floor_line_yellow", Color(0.90, 0.70, 0.10), 0.7, 0.0)
	_pbr("ceiling", Color(0.42, 0.43, 0.44), 0.8, 0.3)
	_pbr("door_slats", Color(0.78, 0.80, 0.81), 0.45, 0.6)
	return mats


func _pbr(name: String, color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = name
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	m.metallic_specular = 0.5
	mats[name] = m
	return m


func _textured(name: String, tex_id: String, tint: Color, uv_scale: Vector3, neutral := false) -> StandardMaterial3D:
	var m := _pbr(name, tint, 1.0, 0.0)
	m.albedo_texture = load("%s%s/%s_diff_1k%s.jpg" % [TEX, tex_id, tex_id, "_neutral" if neutral else ""])
	m.normal_enabled = true
	m.normal_texture = load("%s%s/%s_nor_gl_1k.jpg" % [TEX, tex_id, tex_id])
	m.normal_scale = 0.8
	m.roughness_texture = load("%s%s/%s_rough_1k.jpg" % [TEX, tex_id, tex_id])
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.uv1_scale = uv_scale
	return m
