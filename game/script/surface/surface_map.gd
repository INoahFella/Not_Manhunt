class_name SurfaceMap extends Node

@export_category("Bake")
@export var cell_size: float = 1.0
@export_range(-1.0, 1.0, 0.01) var min_up_normal_y: float = 0.35
@export var bounds_padding: float = 0.0

@export_storage var baked_origin_xz: Vector2 = Vector2.ZERO
@export_storage var baked_size_px: Vector2i = Vector2i.ZERO
@export_storage var baked_ids: PackedByteArray = PackedByteArray()

func _ready() -> void:
	_bake()

func get_surface_id(world_pos: Vector3) -> int:
	if baked_ids.is_empty() or baked_size_px.x <= 0 or baked_size_px.y <= 0:
		return 0

	var px := int(floor((world_pos.x - baked_origin_xz.x) / cell_size))
	var py := int(floor((world_pos.z - baked_origin_xz.y) / cell_size))

	if px < 0 or py < 0 or px >= baked_size_px.x or py >= baked_size_px.y:
		return 0

	return int(baked_ids[py * baked_size_px.x + px])

func _bake() -> void:
	if not Engine.is_editor_hint():
		return

	if cell_size <= 0.0:
		push_error("cell_size must be > 0")
		return

	var target := get_parent() as Node3D
	if target == null:
		push_error("SurfaceMap must be a child of a Node3D (target root).")
		return

	var meshes := _collect_meshes(target)
	if meshes.is_empty():
		push_error("No MeshInstance3D found under target.")
		return

	var bounds := _combined_world_aabb(meshes)
	if bounds.size.x <= 0.0 or bounds.size.z <= 0.0:
		push_error("Combined bounds are invalid.")
		return

	bounds.position.x -= bounds_padding
	bounds.position.z -= bounds_padding
	bounds.size.x += bounds_padding * 2.0
	bounds.size.z += bounds_padding * 2.0

	var origin := Vector2(bounds.position.x, bounds.position.z)
	var w := int(ceil(bounds.size.x / cell_size))
	var h := int(ceil(bounds.size.z / cell_size))

	if w <= 0 or h <= 0:
		push_error("Computed bake size is invalid: %dx%d" % [w, h])
		return

	var best_y := PackedFloat32Array()
	var best_id := PackedByteArray()
	best_y.resize(w * h)
	best_id.resize(w * h)

	for i in range(w * h):
		best_y[i] = INF
		best_id[i] = 0

	var tri_considered := 0
	var updates := 0

	for mi in meshes:
		if mi == null:
			continue
		var mesh := mi.mesh
		if mesh == null:
			continue

		var xf := mi.global_transform
		var surface_count := mesh.get_surface_count()

		for surface_idx in range(surface_count):
			var sm := mi.get_active_material(surface_idx) as ShittyMaterial3D
			if sm == null:
				continue

			var sid = clamp(sm.id, 1, 255)

			var arrays := mesh.surface_get_arrays(surface_idx)
			if arrays.is_empty():
				continue

			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if verts.is_empty():
				continue

			var indices_any = arrays[Mesh.ARRAY_INDEX]
			if indices_any is PackedInt32Array and (indices_any as PackedInt32Array).size() > 0:
				var indices := indices_any as PackedInt32Array
				var tri_count := indices.size() / 3
				for t in range(tri_count):
					var v0 := xf * verts[indices[t * 3 + 0]]
					var v1 := xf * verts[indices[t * 3 + 1]]
					var v2 := xf * verts[indices[t * 3 + 2]]

					if abs(_tri_normal_y(v0, v1, v2)) >= min_up_normal_y:
						updates += _raster_tri_lowest(v0, v1, v2, origin, w, h, sid, best_y, best_id)
					tri_considered += 1
			else:
				var tri_count2 := verts.size() / 3
				for t2 in range(tri_count2):
					var v0b := xf * verts[t2 * 3 + 0]
					var v1b := xf * verts[t2 * 3 + 1]
					var v2b := xf * verts[t2 * 3 + 2]

					if abs(_tri_normal_y(v0b, v1b, v2b)) >= min_up_normal_y:
						updates += _raster_tri_lowest(v0b, v1b, v2b, origin, w, h, sid, best_y, best_id)
					tri_considered += 1

	baked_origin_xz = origin
	baked_size_px = Vector2i(w, h)
	baked_ids = best_id

	print("Surface bytes baked (single lowest layer).")
	print("origin_xz: ", baked_origin_xz, " cell_size: ", cell_size, " size_px: ", baked_size_px)
	print("triangles considered: ", tri_considered, " updates: ", updates)
	print("bytes: ", baked_ids.size(), " (~", snappedf(float(baked_ids.size()) / 1024.0, 0.01), " KB)")

func _collect_meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	_collect_meshes_rec(root, out)
	return out

func _collect_meshes_rec(n: Node, out: Array[MeshInstance3D]) -> void:
	if n is MeshInstance3D:
		out.append(n as MeshInstance3D)
	for c in n.get_children():
		_collect_meshes_rec(c, out)

func _combined_world_aabb(meshes: Array[MeshInstance3D]) -> AABB:
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

func _mesh_world_aabb(mi: MeshInstance3D) -> AABB:
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

func _tri_normal_y(v0: Vector3, v1: Vector3, v2: Vector3) -> float:
	var n := (v1 - v0).cross(v2 - v0)
	var lsq := n.length_squared()
	if lsq <= 0.0000001:
		return -1.0
	return n.y / sqrt(lsq)

func _raster_tri_lowest(
	v0: Vector3, v1: Vector3, v2: Vector3,
	origin: Vector2, w: int, h: int, sid: int,
	best_y: PackedFloat32Array, best_id: PackedByteArray
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

func _point_in_tri_2d(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var ab := (b - a).cross(p - a)
	var bc := (c - b).cross(p - b)
	var ca := (a - c).cross(p - c)

	var has_neg := (ab < 0.0) or (bc < 0.0) or (ca < 0.0)
	var has_pos := (ab > 0.0) or (bc > 0.0) or (ca > 0.0)
	return not (has_neg and has_pos)
