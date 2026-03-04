@tool
extends EditorPlugin

const SCRIPT = preload("uid://c882y1sfipvc0")

func _enter_tree() -> void:
	add_custom_type("ShittyMaterial3D",
					"ShaderMaterial",
					SCRIPT,
					get_editor_interface().get_base_control().get_theme_icon("StandardMaterial3D", "EditorIcons"))

func _exit_tree() -> void:
	remove_custom_type("ShittyMaterial3D")
