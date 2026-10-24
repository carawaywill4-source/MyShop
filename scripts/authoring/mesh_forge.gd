extends RefCounted
## Procedural mesh authoring for MyShop's original assets (car body, rims, lift, small parts).
## Every function returns a real ArrayMesh with smooth normals, so authored parts can be saved
## as resources, exported to glTF for Blender, and replaced by artist meshes later.

const FLAT := -1


## Closed 2D polygon extruded along +Z (depth centred on 0). Side walls smooth, caps flat.
static func extrude(profile: PackedVector2Array, depth: float, mat: Material = null) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := depth * 0.5
	var n := profile.size()
	st.set_smooth_group(1)
	for i in n:
		var a := profile[i]
		var b := profile[(i + 1) % n]
		_quad(st, Vector3(a.x, a.y, -half), Vector3(b.x, b.y, -half), Vector3(b.x, b.y, half), Vector3(a.x, a.y, half))
	st.set_smooth_group(FLAT)
	var tris := Geometry2D.triangulate_polygon(profile)
	for t in range(0, tris.size(), 3):
		var p0 := profile[tris[t]]
		var p1 := profile[tris[t + 1]]
		var p2 := profile[tris[t + 2]]
		_tri(st, Vector3(p0.x, p0.y, half), Vector3(p1.x, p1.y, half), Vector3(p2.x, p2.y, half))
		_tri(st, Vector3(p2.x, p2.y, -half), Vector3(p1.x, p1.y, -half), Vector3(p0.x, p0.y, -half))
	return _finish(st, mat)


## Rounded rectangle cross-section (X/Y) extruded along Z. Reads far better than BoxMesh under light.
static func beveled_box(size: Vector3, radius: float, mat: Material = null, segments := 3) -> ArrayMesh:
	return extrude(rounded_rect(Vector2(size.x, size.y), radius, segments), size.z, mat)


static func rounded_rect(size: Vector2, radius: float, segments := 3) -> PackedVector2Array:
	var r := minf(radius, minf(size.x, size.y) * 0.5)
	var hx := size.x * 0.5 - r
	var hy := size.y * 0.5 - r
	var pts := PackedVector2Array()
	var corners := [Vector2(hx, hy), Vector2(-hx, hy), Vector2(-hx, -hy), Vector2(hx, -hy)]
	for c in 4:
		for s in segments + 1:
			var ang := (c * 0.5 + float(s) / segments * 0.5) * PI
			pts.append(corners[c] + Vector2(cos(ang), sin(ang)) * r)
	return _ensure_ccw(pts)


## Revolve a (radius, height) profile around Y. Profile runs bottom to top.
static func lathe(profile: PackedVector2Array, segments := 24, mat: Material = null, cap_bottom := true, cap_top := true) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(1)
	for s in segments:
		var a0 := TAU * s / segments
		var a1 := TAU * (s + 1) / segments
		for i in profile.size() - 1:
			var p := profile[i]
			var q := profile[i + 1]
			var v0 := Vector3(cos(a0) * p.x, p.y, sin(a0) * p.x)
			var v1 := Vector3(cos(a1) * p.x, p.y, sin(a1) * p.x)
			var v2 := Vector3(cos(a1) * q.x, q.y, sin(a1) * q.x)
			var v3 := Vector3(cos(a0) * q.x, q.y, sin(a0) * q.x)
			_quad(st, v0, v3, v2, v1)
	st.set_smooth_group(FLAT)
	if cap_bottom and profile[0].x > 0.0001:
		_disc(st, profile[0].x, profile[0].y, segments, false)
	if cap_top and profile[profile.size() - 1].x > 0.0001:
		_disc(st, profile[profile.size() - 1].x, profile[profile.size() - 1].y, segments, true)
	return _finish(st, mat)


## Sweep a circle along a polyline (hoses, wires, exhaust). Path is smoothed with Catmull-Rom.
static func tube(path: PackedVector3Array, radius: float, mat: Material = null, sides := 10, subdiv := 6) -> ArrayMesh:
	var pts := _catmull(path, subdiv)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(1)
	var prev_normal := Vector3.UP
	var rings: Array[PackedVector3Array] = []
	for i in pts.size():
		var tangent: Vector3
		if i == 0:
			tangent = (pts[1] - pts[0]).normalized()
		elif i == pts.size() - 1:
			tangent = (pts[i] - pts[i - 1]).normalized()
		else:
			tangent = (pts[i + 1] - pts[i - 1]).normalized()
		var normal := prev_normal - tangent * prev_normal.dot(tangent)
		if normal.length() < 0.01:
			normal = tangent.cross(Vector3.RIGHT)
		normal = normal.normalized()
		prev_normal = normal
		var binormal := tangent.cross(normal)
		var ring := PackedVector3Array()
		for s in sides:
			var ang := TAU * s / sides
			ring.append(pts[i] + (normal * cos(ang) + binormal * sin(ang)) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		for s in sides:
			var t := (s + 1) % sides
			_quad(st, rings[i][s], rings[i][t], rings[i + 1][t], rings[i + 1][s])
	return _finish(st, mat)


## Loft between cross-sections that all have the same point count.
## classify(segment_index, section_index) returns a surface index so one mesh can carry
## several materials (paint, glass, trim); -1 skips the face. smooth(segment_index) picks a smooth group.
static func loft(sections: Array, mats: Array, classify: Callable, closed_profile := false, smooth: Callable = Callable()) -> ArrayMesh:
	var tools: Array[SurfaceTool] = []
	for _m in mats:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools.append(st)
	var used := []
	used.resize(mats.size())
	used.fill(false)
	var count: int = (sections[0] as PackedVector3Array).size()
	var segs := count if closed_profile else count - 1
	for j in sections.size() - 1:
		var a: PackedVector3Array = sections[j]
		var b: PackedVector3Array = sections[j + 1]
		for i in segs:
			var k := (i + 1) % count
			var surf: int = classify.call(i, j)
			if surf < 0:
				continue
			var st := tools[surf]
			st.set_smooth_group(smooth.call(i) if smooth.is_valid() else 1)
			used[surf] = true
			_quad(st, a[i], a[k], b[k], b[i])
	var mesh := ArrayMesh.new()
	for m in mats.size():
		if not used[m]:
			continue
		tools[m].generate_normals()
		tools[m].commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mats[m])
	return mesh


## Mirror a half profile (x >= 0, ordered bottom centre -> top centre) into a full closed loop.
static func mirror_profile(half: PackedVector3Array) -> PackedVector3Array:
	var out := PackedVector3Array(half)
	for i in range(half.size() - 2, 0, -1):
		var p := half[i]
		out.append(Vector3(-p.x, p.y, p.z))
	return out


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b - a).cross(c - a).length_squared() < 1e-14:
		return
	# Callers pass counter-clockwise triangles; Godot's front faces are clockwise.
	st.set_uv(Vector2(a.x + a.z, a.y))
	st.add_vertex(a)
	st.set_uv(Vector2(c.x + c.z, c.y))
	st.add_vertex(c)
	st.set_uv(Vector2(b.x + b.z, b.y))
	st.add_vertex(b)


static func _disc(st: SurfaceTool, r: float, y: float, segments: int, up: bool) -> void:
	var centre := Vector3(0, y, 0)
	for s in segments:
		var a0 := TAU * s / segments
		var a1 := TAU * (s + 1) / segments
		var p0 := Vector3(cos(a0) * r, y, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y, sin(a1) * r)
		if up:
			_tri(st, centre, p1, p0)
		else:
			_tri(st, centre, p0, p1)


static func _finish(st: SurfaceTool, mat: Material) -> ArrayMesh:
	st.generate_normals()
	var mesh := st.commit()
	if mat:
		mesh.surface_set_material(0, mat)
	return mesh


static func _ensure_ccw(pts: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(pts):
		pts.reverse()
	return pts


static func _catmull(path: PackedVector3Array, subdiv: int) -> PackedVector3Array:
	if path.size() < 3:
		return path
	var out := PackedVector3Array()
	for i in path.size() - 1:
		var p0 := path[maxi(i - 1, 0)]
		var p1 := path[i]
		var p2 := path[i + 1]
		var p3 := path[mini(i + 2, path.size() - 1)]
		for s in subdiv:
			var t := float(s) / subdiv
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(path[path.size() - 1])
	return out
