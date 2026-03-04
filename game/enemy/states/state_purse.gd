extends EnemyState

func enter() -> void:
	enemy.move(Game.get_player().global_position)
	await enemy.moved
	
	if enemy.snapshot.player_visible > 0.80:
		machine.shift(self)
		print(enemy.snapshot.player_visible)
	else:
		machine.shift($"../Idle")
