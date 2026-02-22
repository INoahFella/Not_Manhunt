class_name Player extends CharacterBody3D

const CAMERA_SPEED_HORIZONTAL = 2.5
const CAMERA_SPEED_VERTICAL = 1.0
const CAMERA_LOCK_MIN = deg_to_rad(-45)
const CAMERA_LOCK_MAX = deg_to_rad(45)
const MOUSE_SPEED = 0.002

@onready var state_machine := $Machine as StateMachine
@onready var state_default := $Machine/Idle as State
@onready var state_animate := $"PivotCharacter/Animated Human/AnimationPlayer" as AnimationPlayer
@onready var state_camera := $PivotCamera/SpringArm3D/Camera3D as PlayerCamera

@export var enabled = true

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_enabled = true
var damping = 1.0
var input_queue: String = ""
var input_time: int = 0
var target_camera_rotation: Vector3
var sneakiness = 0.0

func _ready() -> void:
	state_machine.player = self
	state_machine.animate = state_animate
	state_machine.camera = state_camera
	state_machine.shift(state_default)
	
	state_camera.breath()
	
func _physics_process(delta: float) -> void:
	if enabled:
		_input_queue()
		_camera(delta)
		_state(delta)
		_gravity(delta)

	if Input.is_action_just_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and Input.is_action_just_pressed("player_action3"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta: float) -> void:
	RenderingServer.global_shader_parameter_set("camera_position", $PivotCamera/SpringArm3D/Camera3D.global_position)
	
	if not enabled: return
	
	$VisibilityCaster/SubViewport/Camera3D.global_position = $VisibilityCaster.global_position
	if Engine.get_frames_drawn() % 20 == 0: _visibility(delta)
	
	$PivotCamera.rotation.x = lerp($PivotCamera.rotation.x, target_camera_rotation.x, 1.0 - exp(-25.0 * delta))
	$PivotCamera.rotation.y = lerp($PivotCamera.rotation.y, target_camera_rotation.y, 1.0 - exp(-25.0 * delta))
	
func _state(delta: float) -> void:
	var input = Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var direction = ($PivotCamera.transform.basis * Vector3(input.x, 0, input.y))
	state_machine.frame(delta, direction)
	
func _camera(delta: float) -> void:
	var input = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	var look_x = input.x * CAMERA_SPEED_HORIZONTAL
	var look_y = input.y * CAMERA_SPEED_VERTICAL

	target_camera_rotation.y -= look_x * delta
	target_camera_rotation.x -= look_y * delta
	target_camera_rotation.x = clampf(target_camera_rotation.x, CAMERA_LOCK_MIN, CAMERA_LOCK_MAX)

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_camera_rotation.y -= event.relative.x * MOUSE_SPEED
		target_camera_rotation.x -= event.relative.y * MOUSE_SPEED
		target_camera_rotation.x = clampf(target_camera_rotation.x, CAMERA_LOCK_MIN, CAMERA_LOCK_MAX)

func _gravity(delta: float) -> void:
	if gravity_enabled:
		velocity.y -= gravity * delta

func _input_queue() -> void:
	if Input.is_action_just_pressed("player_action1"):
		input_queue = "player_action1"
		input_time = Time.get_ticks_msec()
	if Input.is_action_just_pressed("player_action2"):
		input_queue = "player_action2"
		input_time = Time.get_ticks_msec()

func _on_machine_on_enter(state: State) -> void:
	if state.ANIMATION_ENABLED:
		state_animate.play(state.ANIMATION_NAME, state.ANIMATION_BLEND, state.ANIMATION_SPEED)

func _visibility(delta: float):
	var viewport = $VisibilityCaster/SubViewport
	var texture = viewport.get_texture()
	var img = texture.get_image()
	
	if img == null or img.is_empty(): 
		return
	
	var total_lum: float = 0.0
	var pixel_count: int = img.get_width() * img.get_height()
	
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var color = img.get_pixel(x, y)
			var lum = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			total_lum += lum
	
	var raw_visibility = total_lum / float(pixel_count)
	var processed_val = remap(raw_visibility, 0.05, 0.4, 1.0, 0.0)
	var target_sneakiness = clamp(processed_val, 0.0, 1.0)
	sneakiness = clamp(lerp(sneakiness, target_sneakiness, 50.0 * delta), 0.0, 1.0)
	sneakiness = round(sneakiness * 100.0) / 100.0

func input_queued(input: String):
	var just_pressed = Input.is_action_just_pressed(input)
	var queued = input_queue == input and Time.get_ticks_msec() - input_time <= 100
	
	if queued:
		input_queue = ""
		input_time = -1
	
	return just_pressed or queued

func is_wall() -> bool:
	return get_wall() != null

func get_wall() -> RayCast3D:
	for child in $WallCaster.get_children():
		if child.is_colliding() and not child.get_collider() is Player and not child.get_collider() is RigidBody3D:
			return child
	return null

func get_wall_direction():
	return get_wall().get_collision_normal()

func compare_wall_direction(vec: Vector3):
	var direction = get_wall_direction()
	direction.y = 0
	return direction.is_equal_approx(vec)

func is_floor():
	return is_on_floor()
