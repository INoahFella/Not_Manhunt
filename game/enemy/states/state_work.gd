extends EnemyState

func enter() -> void:
	await animate.animation_finished
	machine.shift($"../Idle")
	
func frame(_delta: float) -> void:
	enemy.move_and_slide()
	
func leave() -> void:
	pass
