extends EnemyState

func enter() -> void:
	pass

func frame(delta: float) -> void:
	enemy.move_and_slide()

func leave() -> void:
	pass

func prize(start: EnemySnapshot, end: EnemySnapshot) -> void:
	var r = 0.0
	EnemyAi.reward(enemy, clamp(r, -1.0, 1.0))
