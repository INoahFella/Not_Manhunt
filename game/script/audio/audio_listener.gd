extends AudioStreamPlayer3D

signal audio_active
signal audio_silent

@export var threshold_db: float = -55.0
@export var analyzer_bus_name: String = "Dialog"
@export var open_duration: float = 0.1

var _was_active: bool = false
var _spectrum: AudioEffectInstance
var _cooldown_timer: float = 0.0

func _ready():
	bus = analyzer_bus_name
	var bus_index = AudioServer.get_bus_index(analyzer_bus_name)

	if bus_index == -1:
		set_process(false)
		return

	_spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)

func _process(delta):
	var is_peaking = false

	if playing:
		var magnitude = _spectrum.get_magnitude_for_frequency_range(0, 20000).length()
		var energy_db = linear_to_db(magnitude)
		is_peaking = energy_db > threshold_db

	if is_peaking:
		_cooldown_timer = open_duration
		_update_state(true)
	else:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0:
			_update_state(false)

func _update_state(is_now_active: bool):
	if is_now_active != _was_active:
		_was_active = is_now_active
		if is_now_active:
			audio_active.emit()
		else:
			audio_silent.emit()
