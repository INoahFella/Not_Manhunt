extends State

const SPEED = 20.0
const STEP_SOUND = preload("res://assets/player/sounds/step_sfx.tres")

@onready var pivot_character = $"../../PivotCharacter"
@onready var pivot_character_mock = $"../../PivotCharacterMock"

func enter() -> void:
	camera.breath_fast()
	camera.zoom(camera.original_zoom + 5)

func frame(_delta: float, input: Vector3) -> void:
	if not Input.is_action_pressed("player_action1"):
		machine.shift($"../Walk")
		return
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
	camera.breath()
	camera.unzoom()
	
func play_step() -> void:
	SFX.play(STEP_SOUND, player)
