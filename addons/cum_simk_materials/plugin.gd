@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type("ShittyMaterial3D", 
					"ShaderMaterial", 
					load("res://addons/cum_simk_materials/materials/shitty_material_3d.gd"), 
					get_editor_interface().get_base_control().get_theme_icon("StandardMaterial3D", "EditorIcons"))

func _exit_tree() -> void:
	remove_custom_type("ShittyMaterial3D")
