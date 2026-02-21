extends Node

func get_root(): return get_node("/root/Level")
func get_root_node(path: NodePath): return get_root().get_node(path) if get_root().has_node(path) else null
func get_player(): return get_root_node("Player") as Player
func get_camera(): return get_player().state_camera
func get_sfx(): return get_root_node("SFX")
func get_spawn(): return get_root_node("PlayerSpawn")
