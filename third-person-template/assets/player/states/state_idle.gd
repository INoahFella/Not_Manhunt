extends State

const FRICTION: float = 25.0

func frame(delta: float, input: Vector3) -> void:
	if not input.is_zero_approx():
		machine.shift($"../Walk")
		return
	
	if player.is_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, FRICTION * delta * 10)
		player.velocity.z = move_toward(player.velocity.z, 0, FRICTION * delta * 10)
	
	player.move_and_slide()
