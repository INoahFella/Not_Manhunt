extends EnemyState

func enter() -> void:
	pass
	
func frame(_delta: float) -> void:
	enemy.move_and_slide()
	
func leave() -> void:
	pass
