class_name Map extends Node

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
	var meshes := MeshUtil._collect_meshes(self)
	var bounds := MeshUtil._combined_world_aabb(meshes)

	bounds.position.x -= bounds_padding
	bounds.position.z -= bounds_padding
	bounds.size.x += bounds_padding * 2.0
	bounds.size.z += bounds_padding * 2.0

	var origin := Vector2(bounds.position.x, bounds.position.z)
	var w := int(ceil(bounds.size.x / cell_size))
	var h := int(ceil(bounds.size.z / cell_size))
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
				var tri_count := int(indices.size() / 3.0)
				for t in range(tri_count):
					var v0 := xf * verts[indices[t * 3 + 0]]
					var v1 := xf * verts[indices[t * 3 + 1]]
					var v2 := xf * verts[indices[t * 3 + 2]]

					if abs(MeshUtil._tri_normal_y(v0, v1, v2)) >= min_up_normal_y:
						updates += MeshUtil._raster_tri_lowest(v0, v1, v2, origin, w, h, cell_size, sid, best_y, best_id)
					tri_considered += 1
			else:
				var tri_count2 := int(verts.size() / 3.0)
				for t2 in range(tri_count2):
					var v0b := xf * verts[t2 * 3 + 0]
					var v1b := xf * verts[t2 * 3 + 1]
					var v2b := xf * verts[t2 * 3 + 2]

					if abs(MeshUtil._tri_normal_y(v0b, v1b, v2b)) >= min_up_normal_y:
						updates += MeshUtil._raster_tri_lowest(v0b, v1b, v2b, origin, w, h, cell_size, sid, best_y, best_id)
					tri_considered += 1

	baked_origin_xz = origin
	baked_size_px = Vector2i(w, h)
	baked_ids = best_id

	print("Surface bytes baked (single lowest layer).")
	print("origin_xz: ", baked_origin_xz, " cell_size: ", cell_size, " size_px: ", baked_size_px)
	print("triangles considered: ", tri_considered, " updates: ", updates)
	print("bytes: ", baked_ids.size(), " (~", snappedf(float(baked_ids.size()) / 1024.0, 0.01), " KB)")
