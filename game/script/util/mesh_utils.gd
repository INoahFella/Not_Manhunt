class_name MeshUtil extends Node

static func _collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	_collect_meshes_rec(root, out)
	return out

static func _collect_meshes_rec(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_meshes_rec(c, out)

static func _combined_world_aabb(meshes: Array[MeshInstance3D]) -> AABB:
	var first := true
	var combined := AABB()

	for mi in meshes:
		if mi == null or mi.mesh == null:
			continue

		var world_aabb := _mesh_world_aabb(mi)
		if world_aabb.size == Vector3.ZERO:
			continue

		if first:
			combined = world_aabb
			first = false
		else:
			combined = combined.merge(world_aabb)

	return combined

static func _mesh_world_aabb(mi: MeshInstance3D) -> AABB:
	var local_aabb := mi.get_aabb()
	if local_aabb.size == Vector3.ZERO:
		return AABB()

	var xf := mi.global_transform
	var p := local_aabb.position
	var s := local_aabb.size

	var corners: Array[Vector3] = [
		Vector3(p.x, p.y, p.z),
		Vector3(p.x + s.x, p.y, p.z),
		Vector3(p.x, p.y + s.y, p.z),
		Vector3(p.x + s.x, p.y + s.y, p.z),
		Vector3(p.x, p.y, p.z + s.z),
		Vector3(p.x + s.x, p.y, p.z + s.z),
		Vector3(p.x, p.y + s.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
	]

	var w0 := xf * corners[0]
	var min_v := w0
	var max_v := w0

	for i in range(1, corners.size()):
		var w := xf * corners[i]
		min_v.x = min(min_v.x, w.x)
		min_v.y = min(min_v.y, w.y)
		min_v.z = min(min_v.z, w.z)
		max_v.x = max(max_v.x, w.x)
		max_v.y = max(max_v.y, w.y)
		max_v.z = max(max_v.z, w.z)

	return AABB(min_v, max_v - min_v)

static func _tri_normal_y(v0: Vector3, v1: Vector3, v2: Vector3) -> float:
	var n := (v1 - v0).cross(v2 - v0)
	var lsq := n.length_squared()

	if lsq <= 0.0000001:
		return -1.0

	return n.y / sqrt(lsq)

static func _raster_tri_lowest(
	v0: Vector3,
	v1: Vector3,
	v2: Vector3,
	origin: Vector2,
	w: int,
	h: int,
	cell_size: float,
	sid: int,
	best_y: PackedFloat32Array,
	best_id: PackedByteArray
) -> int:
	var p0 := Vector2(v0.x, v0.z)
	var p1 := Vector2(v1.x, v1.z)
	var p2 := Vector2(v2.x, v2.z)

	var minx = min(p0.x, p1.x, p2.x)
	var maxx = max(p0.x, p1.x, p2.x)
	var miny = min(p0.y, p1.y, p2.y)
	var maxy = max(p0.y, p1.y, p2.y)

	var x0 = clamp(int(floor((minx - origin.x) / cell_size)), 0, w - 1)
	var x1 = clamp(int(floor((maxx - origin.x) / cell_size)), 0, w - 1)
	var y0 = clamp(int(floor((miny - origin.y) / cell_size)), 0, h - 1)
	var y1 = clamp(int(floor((maxy - origin.y) / cell_size)), 0, h - 1)

	var y_candidate := (v0.y + v1.y + v2.y) / 3.0
	var wrote := 0

	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			var cx := origin.x + (float(xx) + 0.5) * cell_size
			var cy := origin.y + (float(yy) + 0.5) * cell_size

			if _point_in_tri_2d(Vector2(cx, cy), p0, p1, p2):
				var idx := yy * w + xx

				if y_candidate < best_y[idx]:
					best_y[idx] = y_candidate
					best_id[idx] = sid
					wrote += 1

	return wrote

static func _point_in_tri_2d(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var ab := (b - a).cross(p - a)
	var bc := (c - b).cross(p - b)
	var ca := (a - c).cross(p - c)

	var has_neg := (ab < 0.0) or (bc < 0.0) or (ca < 0.0)
	var has_pos := (ab > 0.0) or (bc > 0.0) or (ca > 0.0)

	return not (has_neg and has_pos)
