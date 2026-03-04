@tool class_name ShittyMaterial3D extends ShaderMaterial

@export_range(0, 255) var id: int

func _init() -> void:
	if shader == null:
		shader = preload("uid://cu8otgjy1y6g0")
