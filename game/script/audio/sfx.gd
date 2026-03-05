class_name Sfx
extends Node

signal emitted(type: String, position: Vector3, audio: SoundEffect)

var sounds: Dictionary[NodePath, AudioStreamPlayer3D] = {}

func play_all(sound_effects: Array[SoundEffect], where: Node3D) -> void:
	for sound_effect in sound_effects:
		play(sound_effect, where)

func play(sound_effect: SoundEffect, where: Node3D) -> void:
	var id = str(sound_effect.get_instance_id())
		
	if has_player(id, where):
		var player = get_player(id, where)
		player.bus = sound_effect.bus
		player.volume_db = sound_effect.volume
		player.name = id
		player.unit_size = sound_effect.size
		player.autoplay = true
		player.pitch_scale = sound_effect.pitch
		player.max_polyphony = 5
		if randf() < sound_effect.chance:
			player.play()
	else:
		var player = AudioStreamPlayer3D.new()
		player.bus = sound_effect.bus
		player.volume_db = sound_effect.volume
		player.stream = sound_effect.stream
		player.name = id
		player.autoplay = true
		player.unit_size = sound_effect.size
		player.pitch_scale = sound_effect.pitch
		player.max_polyphony = 5
		
		var node: Node3D
		if not where.has_node("SFX"):
			node = Node3D.new()
			node.name = "SFX"
			where.add_child(node)
		else:
			node = where.get_node("SFX")
			
		node.add_child(player)
		sounds.set(where.get_node("SFX/" + id).get_path(), player)

	emitted.emit(sound_effect.bus, where.global_position, sound_effect)

func play_surface(sound_surface: SoundSurface, where: Node3D) -> void:
	var surface_id = Game.get_surface_map().get_surface_id(where.global_position)
	var sound_effect = sound_surface.find_sound(surface_id)
	
	play(sound_effect, where)

func stop(identifier, where: Node3D) -> void:
	if has_player(identifier, where):
		var player = get_player(identifier, where)
		if player != null:
			player.stop()

func has_player(identifier, where: Node3D) -> bool:
	return where != null and where.has_node("SFX/" + str(identifier))

func get_player(identifier, where: Node3D) -> AudioStreamPlayer3D:
	if not has_player(identifier, where):
		return null
	var p: NodePath = where.get_node("SFX/" + str(identifier)).get_path()
	return sounds.get(p, null)
