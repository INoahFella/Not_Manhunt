extends RigidBody3D

const break_sound = preload("res://assets/player/sounds/bottle_sfx.tres")

func _on_body_entered(body: Node) -> void:
	if body is not Player:
		SFX.play(break_sound, self)
		visible = false
		sleeping = true
		freeze = true
		await get_tree().create_timer(0.5).timeout
		queue_free()
