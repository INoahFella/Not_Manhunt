extends State

const SPEED = 4.5
const FRICTION: float = 25.0

@onready var pivot_character = $"../../PivotCharacter"
@onready var pivot_character_mock = $"../../PivotCharacterMock"
@onready var pivot_camera = $"../../PivotCameraMock"
@onready var pivot_weapon = $"../../PivotCharacter/PivotWeapon"

const BOTTLE = preload("uid://yum63ja5vum3")

func enter() -> void:
	camera.zoom(camera.original_zoom - 5)
	camera.overlook()

func frame(_delta: float, input: Vector3) -> void:
	if not Input.is_action_pressed("player_action2"):
		machine.shift($"../Idle")
		return

	player.velocity.x = input.x * SPEED * player.damping
	player.velocity.z = input.z * SPEED * player.damping
	player.move_and_slide()

	if not input.is_zero_approx():
		animate.play("Human Armature|Walk", 0.1, 0.5)
	else:
		animate.play("Human Armature|Idle", 0.1, 1.0)

	pivot_character_mock.look_at(pivot_camera.global_position)
	pivot_character.rotation.y = lerp_angle(pivot_character.rotation.y, pivot_character_mock.rotation.y, 0.5)

func leave() -> void:
	var bottle = BOTTLE.instantiate() as RigidBody3D
	Game.get_root().add_child(bottle)
	bottle.global_position = pivot_weapon.global_position
	bottle.apply_force((camera.global_position.direction_to(pivot_camera.global_position) + (Vector3.UP * 0.25)) * 300.0, Vector3(0.0, 0.045, 0.0))

	camera.unzoom()
	await camera.unoverlook()
	camera.breath()
