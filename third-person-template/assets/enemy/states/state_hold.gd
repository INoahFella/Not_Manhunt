extends EnemyState

const rotation_speed: float = 3.0

var next_state_time: int = 0

@onready var pivot_character = $"../../PivotCharacter"

func enter() -> void:
	next_state_time = Time.get_ticks_msec() + randi_range(3000, 6000)
	$"../../PivotCharacter/Animated Human/Human Armature/Skeleton3D/LookAtModifier3D".active = true
	$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("swap", -1, enemy.snapshot.stress_level * 2.0)
	
func frame(delta: float) -> void:
	if Time.get_ticks_msec() >= next_state_time:
		machine.shift($"../Idle")
		return
	
	var direction = enemy.global_position.direction_to(enemy.snapshot.belief_center)
	var look_dir = Vector3(direction.x, 0, direction.z).normalized()
	if look_dir.length() > 0.01:
		var target_basis = Basis.looking_at(look_dir)
		pivot_character.basis = pivot_character.basis.slerp(target_basis, rotation_speed * delta)
		
	enemy.velocity = Vector3.ZERO

func leave() -> void:
	$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("RESET")
	$"../../PivotCharacter/Animated Human/Human Armature/Skeleton3D/LookAtModifier3D".active = false
	
func prize(start: EnemySnapshot, end: EnemySnapshot) -> void:
	var r = 0.0

	if end.player_visible >= 1.0:
		r = 1.0
	else:
		var noise_got_fresher = (start.seconds_since_last_noise - end.seconds_since_last_noise) / 3.0
		var noise_got_stronger = (end.noise_strength - start.noise_strength)

		var belief_tightened = (start.belief_radius - end.belief_radius) / 8.0
		var confidence_up = (end.belief_confidence - start.belief_confidence)

		var got_closer = (start.dist_to_last_known - end.dist_to_last_known) / 8.0

		r += clamp(noise_got_fresher, -0.2, 0.2)
		r += clamp(noise_got_stronger, -0.2, 0.2)
		r += clamp(belief_tightened, -0.15, 0.15)
		r += clamp(confidence_up, -0.15, 0.15)
		r += clamp(got_closer, -0.1, 0.1)

		if end.seconds_since_last_noise > start.seconds_since_last_noise and end.player_visible < 1.0:
			r -= 0.1

		if abs(r) < 0.03:
			r -= 0.05

	EnemyAi.reward(enemy, clamp(r, -1.0, 1.0))
