@tool class_name SurfaceMap extends Node

@export_tool_button("Bake")
var bake_button = _bake

@export_category("Output")
@export var output_png_base_path: String = "res://surface_id"

@export_category("Bake")
@export var cell_size: float = 1.0
@export_range(-1.0, 1.0, 0.01) var min_up_normal_y: float = 0.35
@export var bounds_padding: float = 0.0

@export_category("Floors")
@export var floor_step: float = 3.0
@export var floor_origin_y: float = 0.0
@export_range(1, 64) var max_floor_layers: int = 8

@export_storage var baked_origin_xz: Vector2 = Vector2.ZERO
@export_storage var baked_size_px: Vector2i = Vector2i.ZERO
@export_storage var baked_floor_count: int = 0
var baked_floor_min_index: int = 0

class LayerData:
	var best_y: PackedFloat32Array
	var best_id: PackedInt32Array

var baked_images: Array[Image] = []

func _ready() -> void:
	baked_images.clear()
	for i in range(baked_floor_count):
		var path := "%s_f%02d.png" % [output_png_base_path, i + 1]
		var img := Image.load_from_file(path)
		baked_images.append(img)

func get_surface_id(world_pos: Vector3) -> int:
	if baked_images.is_empty():
		return 0

	var px := int(floor((world_pos.x - baked_origin_xz.x) / cell_size))
	var py := int(floor((world_pos.z - baked_origin_xz.y) / cell_size))

	if px < 0 or py < 0 or px >= baked_size_px.x or py >= baked_size_px.y:
		return 0

	var floor_idx := int(round((world_pos.y - floor_origin_y) / floor_step))
	var floor_layer := floor_idx - baked_floor_min_index

	if floor_layer < 0 or floor_layer >= baked_images.size():
		return 0

	var img := baked_images[floor_layer]
	if img == null:
		return 0

	var col := img.get_pixel(px, py)

	return int(round(col.r * 255.0))

func _bake() -> void:
	if not Engine.is_editor_hint():
		return

	if cell_size <= 0.0:
		push_error("cell_size must be > 0")
		return

	if floor_step <= 0.0:
		push_error("floor_step must be > 0")
		return

	var target := get_parent() as Node3D
	if target == null:
		push_error("target_root_path is invalid.")
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
		push_error("Computed image size is invalid: %dx%d" % [w, h])
		return

	var layers: Dictionary = {}
	var has_any_floor := false
	var floor_min := 0
	var floor_max := -1
	var tri_considered := 0

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

			var arrays := mesh.surface_get_arrays(surface_idx)
			if arrays.is_empty():
				continue

			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			if verts.is_empty():
				continue

			var sid = clamp(sm.id, 1, 255)

			var indices_any = arrays[Mesh.ARRAY_INDEX]
			if indices_any is PackedInt32Array and (indices_any as PackedInt32Array).size() > 0:
				var indices := indices_any as PackedInt32Array
				var tri_count := indices.size() / 3
				for t in range(tri_count):
					var v0 := xf * verts[indices[t * 3 + 0]]
					var v1 := xf * verts[indices[t * 3 + 1]]
					var v2 := xf * verts[indices[t * 3 + 2]]

					if abs(_tri_normal_y(v0, v1, v2)) >= min_up_normal_y:
						var used_floor := _raster_tri_to_layer(v0, v1, v2, origin, w, h, sid, layers)
						if used_floor != -1:
							if not has_any_floor:
								has_any_floor = true
								floor_min = used_floor
								floor_max = used_floor
							else:
								floor_min = min(floor_min, used_floor)
								floor_max = max(floor_max, used_floor)
						tri_considered += 1
			else:
				var tri_count2 := verts.size() / 3
				for t2 in range(tri_count2):
					var v0b := xf * verts[t2 * 3 + 0]
					var v1b := xf * verts[t2 * 3 + 1]
					var v2b := xf * verts[t2 * 3 + 2]

					if abs(_tri_normal_y(v0b, v1b, v2b)) >= min_up_normal_y:
						var used_floor2 := _raster_tri_to_layer(v0b, v1b, v2b, origin, w, h, sid, layers)
						if used_floor2 != -1:
							if not has_any_floor:
								has_any_floor = true
								floor_min = used_floor2
								floor_max = used_floor2
							else:
								floor_min = min(floor_min, used_floor2)
								floor_max = max(floor_max, used_floor2)
						tri_considered += 1

	baked_origin_xz = origin
	baked_size_px = Vector2i(w, h)

	if not has_any_floor or layers.is_empty():
		baked_floor_count = 0
		baked_floor_min_index = 0
		push_warning("No floor-ish triangles wrote any pixels (no layers).")
		return

	var desired_max := floor_min + (max_floor_layers - 1)
	for key in layers.keys():
		var k := int(key)
		if k < floor_min or k > desired_max:
			layers.erase(key)

	floor_max = min(floor_max, desired_max)

	baked_floor_min_index = floor_min
	baked_floor_count = (floor_max - floor_min + 1)

	for f in range(floor_min, floor_max + 1):
		var layer := layers.get(f) as LayerData
		if layer == null:
			_write_bw_floor_png(f, w, h, PackedInt32Array())
		else:
			_write_bw_floor_png(f, w, h, layer.best_id)

	print("Surface maps baked per floor.")
	print("Saved base: ", output_png_base_path)
	print("origin_xz: ", baked_origin_xz, " cell_size: ", cell_size, " size_px: ", baked_size_px)
	print("floor_origin_y: ", floor_origin_y, " floor_step: ", floor_step)
	print("floors: ", baked_floor_count, " world_floor_index_range: [", baked_floor_min_index, "..", baked_floor_min_index + baked_floor_count - 1, "]")
	print("Triangles considered: ", tri_considered)

func _write_bw_floor_png(floor_idx: int, w: int, h: int, best_id: PackedInt32Array) -> void:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color(0, 0, 0))

	if best_id.size() == w * h:
		for y in range(h):
			for x in range(w):
				var idx := y * w + x
				var id := best_id[idx]
				if id != 0:
					var v := float(id) / 255.0
					img.set_pixel(x, y, Color(v, v, v))

	var file_idx := (floor_idx - baked_floor_min_index) + 1
	var out_path := "%s_f%02d.png" % [output_png_base_path, file_idx]

	var err := img.save_png(out_path)
	if err != OK:
		push_error("Failed to save PNG: %s (err=%s)" % [out_path, str(err)])

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
		Vector3(p.x,       p.y,       p.z),
		Vector3(p.x + s.x, p.y,       p.z),
		Vector3(p.x,       p.y + s.y, p.z),
		Vector3(p.x + s.x, p.y + s.y, p.z),
		Vector3(p.x,       p.y,       p.z + s.z),
		Vector3(p.x + s.x, p.y,       p.z + s.z),
		Vector3(p.x,       p.y + s.y, p.z + s.z),
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

func _get_or_create_layer(layers: Dictionary, floor_idx: int, w: int, h: int) -> LayerData:
	var existing := layers.get(floor_idx) as LayerData
	if existing != null:
		return existing

	var layer := LayerData.new()
	layer.best_y = PackedFloat32Array()
	layer.best_id = PackedInt32Array()
	layer.best_y.resize(w * h)
	layer.best_id.resize(w * h)

	for i in range(w * h):
		layer.best_y[i] = INF
		layer.best_id[i] = 0

	layers[floor_idx] = layer
	return layer

func _raster_tri_to_layer(
	v0: Vector3, v1: Vector3, v2: Vector3,
	origin: Vector2, w: int, h: int, sid: int,
	layers: Dictionary
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
	var step = max(0.000001, floor_step)
	var floor_idx := int(round((y_candidate - floor_origin_y) / step))

	if abs(floor_idx) > 1024:
		return -1

	var layer := _get_or_create_layer(layers, floor_idx, w, h)
	var best_y := layer.best_y
	var best_id := layer.best_id

	for yy in range(y0, y1 + 1):
		for xx in range(x0, x1 + 1):
			var cx := origin.x + (float(xx) + 0.5) * cell_size
			var cy := origin.y + (float(yy) + 0.5) * cell_size
			if _point_in_tri_2d(Vector2(cx, cy), p0, p1, p2):
				var idx := yy * w + xx
				if y_candidate < best_y[idx]:
					best_y[idx] = y_candidate
					best_id[idx] = sid

	return floor_idx

func _point_in_tri_2d(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var ab := (b - a).cross(p - a)
	var bc := (c - b).cross(p - b)
	var ca := (a - c).cross(p - c)

	var has_neg := (ab < 0.0) or (bc < 0.0) or (ca < 0.0)
	var has_pos := (ab > 0.0) or (bc > 0.0) or (ca > 0.0)
	return not (has_neg and has_pos)
