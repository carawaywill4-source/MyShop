extends RefCounted

var paint: StandardMaterial3D
var paint_dark: StandardMaterial3D
var glass: StandardMaterial3D
var rubber: StandardMaterial3D
var plastic: StandardMaterial3D
var aluminum: StandardMaterial3D
var cast_metal: StandardMaterial3D
var steel: StandardMaterial3D
var concrete: StandardMaterial3D
var hose: StandardMaterial3D
var safety_yellow: StandardMaterial3D
var light_lens: StandardMaterial3D
var tail_lens: StandardMaterial3D
var oil_black: StandardMaterial3D
var plastic_yellow: StandardMaterial3D
var plastic_white: StandardMaterial3D
var rust_dark: StandardMaterial3D
var shop_wall: StandardMaterial3D
var oil_stain: StandardMaterial3D
var drum_red: StandardMaterial3D


func _init() -> void:
	paint = _make(Color(0.23, 0.36, 0.48), 0.42, 0.18)
	paint_dark = _make(Color(0.16, 0.20, 0.24), 0.50, 0.12)
	glass = _make(Color(0.32, 0.42, 0.50, 0.55), 0.08, 0.72)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rubber = _make(Color(0.07, 0.07, 0.08), 0.92, 0.04)
	plastic = _make(Color(0.09, 0.09, 0.10), 0.78, 0.08)
	aluminum = _make(Color(0.62, 0.64, 0.67), 0.38, 0.55)
	cast_metal = _make(Color(0.22, 0.22, 0.23), 0.72, 0.22)
	steel = _make(Color(0.48, 0.50, 0.52), 0.32, 0.62)
	concrete = _make(Color(0.48, 0.48, 0.49), 0.90, 0.03)
	hose = _make(Color(0.14, 0.08, 0.06), 0.86, 0.06)
	safety_yellow = _make(Color(0.86, 0.70, 0.16), 0.55, 0.12)
	light_lens = _make(Color(0.86, 0.90, 0.95), 0.18, 0.65)
	light_lens.emission_enabled = true
	light_lens.emission = Color(0.75, 0.82, 0.92)
	light_lens.emission_energy_multiplier = 0.55
	tail_lens = _make(Color(0.62, 0.10, 0.10), 0.28, 0.45)
	tail_lens.emission_enabled = true
	tail_lens.emission = Color(0.55, 0.08, 0.08)
	tail_lens.emission_energy_multiplier = 0.45
	oil_black = _make(Color(0.08, 0.06, 0.04), 0.55, 0.18)
	plastic_yellow = _make(Color(0.78, 0.66, 0.18), 0.62, 0.10)
	plastic_white = _make(Color(0.78, 0.80, 0.82), 0.58, 0.12)
	rust_dark = _make(Color(0.18, 0.12, 0.09), 0.90, 0.05)
	shop_wall = _make(Color(0.63, 0.66, 0.68), 0.84, 0.02)
	oil_stain = _make(Color(0.30, 0.29, 0.28), 0.96, 0.02)
	drum_red = _make(Color(0.55, 0.12, 0.10), 0.48, 0.18)


func _make(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return mat
