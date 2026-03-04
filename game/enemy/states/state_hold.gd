extends EnemyState

func enter() -> void:
	enemy.move_cancel()
	enemy.look(enemy.snapshot.belief_center)
	animate.play("Human Armature|Idle")

	#$"../../PivotCharacter/Animated Human/Human Armature/Skeleton3D/LookAtModifier3D".active = true
	#$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("swap", 0.5, enemy.get_stress_scale())

	if randf() < 0.1 or enemy.snapshot.belief_confidence > 0.6:
		if enemy.is_stressed():
			animate.play("Human Armature|Run")
		else:
			animate.play("Human Armature|Walk")

		var center := enemy.snapshot.belief_center
		var radius := enemy.snapshot.belief_radius

		var angle := randf() * TAU
		var r := sqrt(randf()) * radius

		var offset := Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		var target := center + offset

		enemy.move(target)
		await enemy.moved

	if not current: return
	animate.play("Human Armature|Idle")
	await get_tree().create_timer(randf_range(3, 6)).timeout

	if not current: return

	machine.shift($"../Idle")

func leave() -> void:
	pass
	#$"../../PivotCharacter/Animated Human/Marker3D/AnimationPlayer".play("RESET", 0.5)
