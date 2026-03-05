class_name SoundEffect extends Resource

@export var stream: AudioStream
@export_range(-60, 60, 0.5) var volume: float = 0.0
@export_range(0.0, 2.0, 0.01, "prefer_slider") var pitch: float = 1.0
@export_range(1.0, 50.0, 0.5, "prefer_slider") var size: float = 1.0
@export_enum("Sfx", "Player") var bus: String = "Sfx"
@export_range(0.0, 1.0, 0.05, "prefer_slider") var chance: float = 1.0

@export_category("Gameplay")
@export_range(0, 1.0, 0.1) var stealth_dampen: float = 0.0
@export_range(0, 10.0, 0.1) var enemy_perception: float = 1.0
@export var surfaces: Array[ShittyMaterial3D] = []

func play(where: Node3D) -> void:
	SFX.play(self, where)
func stop(where: Node3D) -> void:
	SFX.stop(self.identifier, where)
func has_player(where: Node3D) -> bool:
	return SFX.has_player(self.identifier, where)
func get_player(where: Node3D) -> AudioStreamPlayer3D:
	return SFX.get_player(self.identifier, where)
func has_surface(surface_id: int) -> bool:
	return surfaces.any(func(x): return x.id == surface_id)
