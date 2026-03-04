extends RigidBody3D

const break_sound = preload("uid://cw0q2ark88iws")

func _on_body_entered(body: Node) -> void:
	if body is not Player:
		SFX.play(break_sound, self)
		visible = false
		sleeping = true
		freeze = true
		await get_tree().create_timer(0.5).timeout
		queue_free()
