extends EnemyState

static var index: int = 1

@onready var patrol_path = $"../../Path3D"
@onready var pivot_character = $"../../PivotCharacter"

func enter() -> void:
	var curve = patrol_path.curve
	var point_count = curve.point_count
	var target_pos = patrol_path.to_global(curve.get_point_position(index))
	
	enemy.move(target_pos)
	await enemy.moved
	machine.shift($"../Idle")

func frame(delta: float) -> void:
	pass

func leave() -> void:
	var curve = patrol_path.curve
	var point_count = curve.point_count
	index = (index + 1) % point_count
