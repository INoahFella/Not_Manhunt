class_name Sfx extends Node

signal emitted(type: String, position: Vector3, strength: float)

var sounds: Dictionary[NodePath, AudioStreamPlayer3D] = {}

func play_all(sound_effects: Array[SoundEffect], where: Node3D) -> void:
	for sound_effect in sound_effects:
		play(sound_effect, where)

func play(sound_effect: SoundEffect, where: Node3D) -> void:
	if has_player(sound_effect.identifier, where):
		var player = get_player(sound_effect.identifier, where)
		player.bus = sound_effect.bus
		player.volume_db = sound_effect.volume
		player.name = sound_effect.identifier
		player.autoplay = true
		player.pitch_scale = sound_effect.pitch_scale
		player.max_polyphony = 5
		if randf() < sound_effect.chance:
			player.play()
	else:
		var player = AudioStreamPlayer3D.new()
		var stream_random = AudioStreamRandomizer.new()
		
		for i in sound_effect.streams.size():
			var stream = sound_effect.streams[i]
			stream_random.add_stream(i, stream)
		
		stream_random.random_pitch = sound_effect.pitch_modulation
		
		player.bus = sound_effect.bus
		player.volume_db = sound_effect.volume
		player.stream = stream_random
		player.name = sound_effect.identifier
		player.autoplay = true
		player.pitch_scale = sound_effect.pitch_scale
		player.max_polyphony = 5
		
		var node: Node3D
		if not where.has_node("SFX"):
			node = Node3D.new()
			node.name = "SFX"
			where.add_child(node)
		else:
			node = where.get_node("SFX")
			
		node.add_child(player)
		sounds.set(where.get_node("SFX/" + sound_effect.identifier).get_path(), player)

	emitted.emit(sound_effect.bus, where.global_position, sound_effect.volume)

func stop(identifier, where: Node3D) -> void:
	if has_player(identifier, where):
		var player = get_player(identifier, where)
		player.stop()

func has_player(identifier, where: Node3D) -> bool:
	return where.has_node("SFX/" + identifier)

func get_player(identifier, where: Node3D) -> AudioStreamPlayer3D:
	if has_player(identifier, where): 
		return sounds[where.get_node("SFX/" + identifier).get_path()]
	else:
		return null
