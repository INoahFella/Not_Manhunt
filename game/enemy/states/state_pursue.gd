extends EnemyState

func enter() -> void:
	var player = Game.get_player()
	var player_pos = player.global_position

	var space = enemy.get_world_3d().direct_space_state
	var from = enemy.global_position + Vector3.UP * 1.6
	var to = player_pos + Vector3.UP * 1.2

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [enemy]
	query.collide_with_areas = false

	var result = space.intersect_ray(query)

	var has_los = result.is_empty() or result.collider == player or player.is_ancestor_of(result.collider)

	var target = player_pos if has_los else enemy.snapshot.belief_center

	enemy.move(target)
	await enemy.moved
	if not current: return

	if has_los and enemy.snapshot.player_visible > 0.80:
		machine.shift(self)
	else:
		machine.shift($"../Idle")
