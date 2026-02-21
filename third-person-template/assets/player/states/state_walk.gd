extends State

const SPEED = 12.5

@onready var pivot_character = $"../../PivotCharacter"
@onready var pivot_character_mock = $"../../PivotCharacterMock"

func enter() -> void:
	pass

func frame(_delta: float, input: Vector3) -> void:
	if input.is_zero_approx():
		machine.shift($"../Idle")
		return
	if not player.is_floor():
		machine.shift($"../Fall")
		return
		
	player.velocity.x = input.x * SPEED * player.damping
	player.velocity.z = input.z * SPEED * player.damping
	player.move_and_slide()
	
	if not input.is_zero_approx():
		pivot_character_mock.look_at(player.global_position + input)
		pivot_character.rotation.y = lerp_angle(pivot_character.rotation.y, pivot_character_mock.rotation.y, 0.5)

func leave() -> void:
	pass
