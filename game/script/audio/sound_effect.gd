class_name SoundEffect extends Resource

@export var identifier: String
@export var streams: Array[SoundStream]
@export var volume: float = 0.0
@export var size: float = 1.0
@export var pitch_modulation: float = 1.0
@export var pitch_scale: float = 1.0
@export var bus: String = "Sfx"
@export var chance: float = 1.0

@export_category("Gameplay")
@export_range(0, 1.0, 0.1) var stealth_impact: float = 0.0
@export_range(0, 1.0, 0.1) var stealth_strength: float = 1.0

func play(where: Node3D) -> void:
	SFX.play(self, where)
func stop(where: Node3D) -> void:
	SFX.stop(self.identifier, where)
func has_player(where: Node3D) -> bool:
	return SFX.has_player(self.identifier, where)
func get_player(where: Node3D) -> AudioStreamPlayer3D:
	return SFX.get_player(self.identifier, where)
