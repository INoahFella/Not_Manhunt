extends EnemyState

var next_state_time: int = 0

func enter() -> void:
	next_state_time = Time.get_ticks_msec() + randi_range(2500, 6000)
	if randf() > 0.5:
		$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("swap")

func frame(_delta: float) -> void:
	if Time.get_ticks_msec() >= next_state_time:
		machine.shift($"../Patrol")
		return

	enemy.velocity.x = 0
	enemy.velocity.z = 0
	enemy.move_and_slide()

func leave() -> void:
	$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("RESET")
