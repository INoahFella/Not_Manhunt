class_name SurfaceMapBakeData extends Resource

@export var origin_xz: Vector2 = Vector2.ZERO
@export var size_px: Vector2i = Vector2i.ZERO
@export var cell_size: float = 1.0

@export var grid_ids: PackedByteArray = PackedByteArray()
@export var grid_y: PackedFloat32Array = PackedFloat32Array()

func is_valid() -> bool:
	if size_px.x <= 0 or size_px.y <= 0:
		return false
	var n := size_px.x * size_px.y
	return grid_ids.size() == n and grid_y.size() == n

func pos_to_cell(pos: Vector3) -> Vector2i:
	var x := int(floor((pos.x - origin_xz.x) / cell_size))
	var y := int(floor((pos.z - origin_xz.y) / cell_size))
	return Vector2i(x, y)

func get_id_at_cell(cell: Vector2i) -> int:
	if cell.x < 0 or cell.y < 0 or cell.x >= size_px.x or cell.y >= size_px.y:
		return 0
	return int(grid_ids[cell.y * size_px.x + cell.x])

func get_y_at_cell(cell: Vector2i) -> float:
	if cell.x < 0 or cell.y < 0 or cell.x >= size_px.x or cell.y >= size_px.y:
		return 0.0
	return float(grid_y[cell.y * size_px.x + cell.x])
