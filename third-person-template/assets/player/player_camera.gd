class_name PlayerCamera extends Camera3D

@onready var player = $"../../.."
var shake_time = 0.0
var shake_intensity = 0.0
var shake_decay_speed = 5.0
var original_zoom = fov
var original_h_offset = h_offset
var original_v_offset = v_offset
var to_zoom = fov
var breath_tween: Tween
var overlook_tween: Tween
var overlooking: bool

func shake(duration: float, intensity: float):
	shake_time = duration
	shake_intensity = intensity

func zoom(to: float):
	to_zoom = to
	
func unzoom():
	to_zoom = original_zoom

func breath_fast():
	if breath_tween:
		breath_tween.kill()
	
	breath_tween = create_tween().set_parallel(true).set_loops()
	breath_tween.tween_property(self, "v_offset", 0.2, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breath_tween.chain().tween_property(self, "v_offset", -0.1, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
func breath():
	if breath_tween:
		breath_tween.kill()
	
	breath_tween = create_tween().set_parallel(true).set_loops()
	breath_tween.tween_property(self, "v_offset", 0.1, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breath_tween.chain().tween_property(self, "v_offset", -0.1, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func unbreath():
	if breath_tween:
		breath_tween.kill()

func overlook():
	overlooking = true
	
	if overlook_tween:
		overlook_tween.kill()
	if breath_tween:
		breath_tween.kill()
	
	overlook_tween = create_tween().set_parallel()
	overlook_tween.tween_property(self, "h_offset", 1.5, 0.1).set_ease(Tween.EASE_IN_OUT)
	overlook_tween.tween_property(self, "v_offset", 1.5, 0.1).set_ease(Tween.EASE_IN_OUT)
	
func unoverlook():
	
	if overlook_tween:
		overlook_tween.kill()
	if breath_tween:
		breath_tween.kill()
	
	overlook_tween = create_tween().set_parallel()
	overlook_tween.tween_property(self, "h_offset", original_h_offset, 0.1).set_ease(Tween.EASE_IN_OUT)
	overlook_tween.tween_property(self, "v_offset", original_v_offset, 0.1).set_ease(Tween.EASE_IN_OUT)
	
	await overlook_tween.finished
	
	overlooking = false

func smooth_look_at(target_pos: Vector3, duration: float = 0.18) -> void:
	if player.camera_tween:
		player.camera_tween.kill()

	var start_q = global_transform.basis.get_rotation_quaternion()
	
	var original_transform = global_transform
	look_at(target_pos, Vector3.UP)
	var end_q = global_transform.basis.get_rotation_quaternion()
	global_transform = original_transform

	player.camera_tween = create_tween()
	player.camera_tween.tween_method(
		func(t: float): 
			var current_q = start_q.slerp(end_q, t)
			global_basis = Basis(current_q),
		0.0, 1.0, duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _process(delta: float):
	fov = lerp(fov, to_zoom, 0.005)
	
	if shake_time > 0.0:
		shake_time -= delta

		h_offset = randf_range(-shake_intensity, shake_intensity)
		v_offset = randf_range(-shake_intensity, shake_intensity)

		shake_intensity = lerp(shake_intensity, 0.0, delta * shake_decay_speed)
	elif not breath_tween or not breath_tween.is_running() and not overlooking:
		h_offset = original_h_offset
		v_offset = original_v_offset
