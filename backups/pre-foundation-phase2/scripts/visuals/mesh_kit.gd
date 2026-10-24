extends RefCounted

const InteractableScript := preload("res://scripts/interactable.gd")

var world: Node3D
var materials
var parts: Dictionary
var tapped_callback: Callable


func add_box(parent: Node3D, size: Vector3, origin: Vector3, mat: StandardMaterial3D, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = origin
	mesh.rotation = rot
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func add_cyl(parent: Node3D, radius: float, height: float, origin: Vector3, mat: StandardMaterial3D, rot := Vector3.ZERO, top_radius := -1.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = radius
	cyl.top_radius = radius if top_radius < 0.0 else top_radius
	cyl.height = height
	cyl.radial_segments = 12
	mesh.mesh = cyl
	mesh.position = origin
	mesh.rotation = rot
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func add_sphere(parent: Node3D, radius: float, origin: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 10
	sphere.rings = 6
	mesh.mesh = sphere
	mesh.position = origin
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func add_torus(parent: Node3D, inner: float, outer: float, origin: Vector3, mat: StandardMaterial3D, rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 16
	torus.ring_segments = 10
	mesh.mesh = torus
	mesh.position = origin
	mesh.rotation = rot
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func add_pickable_box(parent: Node3D, size: Vector3, origin: Vector3, mat: StandardMaterial3D, part_id: String, label: String) -> Node3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var body := InteractableScript.new()
	parent.add_child(body)
	body.position = origin
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.setup(part_id, label, mesh, mat.albedo_color, mat)
	if tapped_callback.is_valid():
		body.tapped.connect(tapped_callback)
	parts[part_id] = body
	return body


func add_pickable_cyl(parent: Node3D, radius: float, height: float, origin: Vector3, mat: StandardMaterial3D, part_id: String, label: String, rot := Vector3.ZERO) -> Node3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 12
	mesh.mesh = cyl
	mesh.rotation = rot
	var body := InteractableScript.new()
	parent.add_child(body)
	body.position = origin
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cyl_shape := CylinderShape3D.new()
	cyl_shape.radius = radius
	cyl_shape.height = height
	shape.shape = cyl_shape
	shape.rotation = rot
	body.add_child(shape)
	body.setup(part_id, label, mesh, mat.albedo_color, mat)
	if tapped_callback.is_valid():
		body.tapped.connect(tapped_callback)
	parts[part_id] = body
	return body
