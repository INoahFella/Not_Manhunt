class_name Sfx
extends Node

signal emitted(type: String, position: Vector3, audio: SoundEffect)

var sounds: Dictionary[NodePath, AudioStreamPlayer3D] = {}

func play_all(sound_effects: Array[SoundEffect], where: Node3D) -> void:
	for sound_effect in sound_effects:
		play(sound_effect, where)

func play(sound_effect: SoundEffect, where: Node3D) -> void:
	if sound_effect == null or where == null:
		return

	if randf() >= sound_effect.chance:
		return

	var surface_id: int = 0
	var smap = Game.get_surface_map()
	if smap != null:
		surface_id = smap.get_surface_id(where.global_position)

	var chosen_streams: Array[AudioStream] = []
	var fallback_streams: Array[AudioStream] = []

	for ss in sound_effect.streams:
		if ss == null or ss.stream == null:
			continue

		if ss.surfaces.is_empty():
			fallback_streams.append(ss.stream)
			continue

		for mat in ss.surfaces:
			if mat != null and mat.id == surface_id:
				chosen_streams.append(ss.stream)
				break

	if chosen_streams.is_empty():
		chosen_streams = fallback_streams

	if chosen_streams.is_empty():
		for ss2 in sound_effect.streams:
			if ss2 != null and ss2.stream != null:
				chosen_streams.append(ss2.stream)

	var player: AudioStreamPlayer3D
	if has_player(sound_effect.identifier, where):
		player = get_player(sound_effect.identifier, where)
		if player == null:
			return
	else:
		player = AudioStreamPlayer3D.new()
		player.name = sound_effect.identifier

		var node: Node3D
		if not where.has_node("SFX"):
			node = Node3D.new()
			node.name = "SFX"
			where.add_child(node)
		else:
			node = where.get_node("SFX") as Node3D

		node.add_child(player)
		sounds[player.get_path()] = player

	# Rebuild randomizer each play (since clear_streams() doesn't exist)
	var stream_random := AudioStreamRandomizer.new()
	for i in range(chosen_streams.size()):
		stream_random.add_stream(i, chosen_streams[i])
	stream_random.random_pitch = sound_effect.pitch_modulation
	player.stream = stream_random

	player.bus = sound_effect.bus
	player.volume_db = sound_effect.volume
	player.autoplay = true
	player.pitch_scale = sound_effect.pitch_scale
	player.unit_size = sound_effect.size
	player.max_polyphony = 5

	player.play()

	emitted.emit(sound_effect.bus, where.global_position, sound_effect)

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
