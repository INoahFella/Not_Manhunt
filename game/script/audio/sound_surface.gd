class_name SoundSurface extends Resource

@export var sounds: Array[SoundEffect]
@export var default: SoundEffect

func find_sound(surface_id: int) -> SoundEffect:
	var index = sounds.find_custom(func(sound): return sound.has_surface(surface_id))
	return default if index == -1 else sounds.get(index)
