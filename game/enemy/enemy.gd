class_name Enemy extends CharacterBody3D

signal spotted(at: Vector3)
signal heard(at: Vector3)
signal moved(at: Vector3)

@onready var state_machine = $Machine as EnemyMachine
@onready var state_default = $Machine/Idle as EnemyState
@onready var state_animate = $"PivotCharacter/Animated Human/AnimationPlayer" as AnimationPlayer

var gravity_enabled = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var agent_rid: RID
var enabled = true
var hear_max = 50.0
var hear_min = 2.0

var move_target: Vector3 = Vector3.INF
var move_target_path: PackedVector3Array
var move_target_velocity: Vector3
var look_target: Vector3

var move_speed: float = 8.0
var move_speed_stressed: float = 22.0
var look_speed: float = 10.0

var snapshot: EnemySnapshot

func _ready() -> void:
	agent_rid = NavigationServer3D.agent_create()
	NavigationServer3D.agent_set_map(agent_rid, get_world_3d().get_navigation_map())
	NavigationServer3D.agent_set_avoidance_enabled(agent_rid, true)
	NavigationServer3D.agent_set_avoidance_callback(agent_rid, func(x): move_target_velocity = x)

	snapshot = EnemySnapshot.new()

	state_machine.enemy = self
	state_machine.animate = state_animate
	state_machine.shift(state_default)

	SFX.emitted.connect(_sound)

func _physics_process(delta: float) -> void:
	if enabled:
		_state(delta)
		_gravity(delta)
		_snapshot(delta)
		_look(delta)
		_move(delta)

func _state(delta: float) -> void:
	state_machine.frame(delta)

func _gravity(delta: float) -> void:
	if gravity_enabled:
		velocity.y -= gravity * delta

func _snapshot(_delta: float) -> void:
	if Engine.get_physics_frames() % int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second")) != 0: return
	if not snapshot: snapshot = EnemySnapshot.new()

	var player = Game.get_player()
	if not player: return

	var my_pos = global_position
	var player_pos = player.global_position

	snapshot.seconds_since_last_noise = min(snapshot.seconds_since_last_noise + 1.0, 999.0)
	snapshot.seconds_since_seen = min(snapshot.seconds_since_seen + 1.0, 999.0)
	snapshot.player_distance = my_pos.distance_to(player_pos)
	snapshot.player_visible = lerp(snapshot.player_visible, 0.0, 0.08)
	snapshot.dist_to_last_known = my_pos.distance_to(snapshot.belief_center)

	var allies = 0.0
	var allies_radius = 100.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if n == self: continue
		if not (n is Node3D): continue
		if my_pos.distance_to(n.global_position) <= allies_radius: allies += 1.0
	snapshot.allies_nearby_norm = clamp(allies / 4.0, 0.0, 1.0)

	if snapshot.player_visible < 1.0:
		snapshot.belief_radius = min(snapshot.belief_radius + 1.5, 40.0)
		snapshot.belief_confidence = max(snapshot.belief_confidence - 0.10, 0.0)

	snapshot.stress_level = max(snapshot.stress_level - 0.01, 0.0)

	debug_draw_belief()

func _sound(type: String, pos: Vector3, sound: SoundEffect) -> void:
	var strength = sound.enemy_perception

	if type != "Player": return

	var d = global_position.distance_to(pos)
	var t = clamp((d - hear_min) / (hear_max - hear_min), 0.0, 1.0)
	var falloff = 1.0 - t
	var s = clamp(strength, 0.0, 10.0) * (falloff * falloff) * (1.0 - Game.get_player().sneakiness * sound.stealth_dampen)

	if s <= 0.08: return

	snapshot.noise_strength = max(snapshot.noise_strength, s)
	snapshot.seconds_since_last_noise = 0.0

	if snapshot.player_visible >= 1.0:
		return

	var target_radius = lerp(10.0, 5.0, s)
	if s >= 0.75:
		target_radius = 1.0

	var snap_alpha = lerp(0.65, 1.0, s)

	var has_belief := snapshot.belief_confidence > 0.0 or snapshot.belief_radius > 0.0 or snapshot.belief_center != Vector3.ZERO

	if not has_belief:
		snapshot.belief_center = pos
		snapshot.belief_radius = target_radius
		snapshot.belief_confidence = lerp(0.35, 0.70, s)
		heard.emit(pos)
		return

	snapshot.belief_center = pos
	snapshot.belief_radius = lerp(snapshot.belief_radius, target_radius, snap_alpha)
	snapshot.belief_confidence = clamp(snapshot.belief_confidence + 0.15 * s, 0.0, 1.0)

	heard.emit(pos)

func _look(delta: float) -> void:
	var dir := look_target - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.001: return
	$PivotCharacter.basis = $PivotCharacter.basis.slerp(Basis.looking_at(dir.normalized()), look_speed * delta)
	if $PivotCharacter/Eyes/ShapeCast3D.is_colliding():
		spotted.emit(Game.get_player().global_position)

func _move(_delta: float) -> void:
	if move_target == Vector3.INF:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if global_position.distance_to(move_target) <= 1.0:
		NavigationServer3D.agent_set_velocity(agent_rid, Vector3.ZERO)
		move_target_velocity = Vector3.ZERO
		velocity.x = 0.0
		velocity.z = 0.0
		var finished := move_target
		move_target = Vector3.INF
		move_target_path.clear()
		move_and_slide()
		moved.emit(finished)
		return

	var next := move_target
	if move_target_path.size() >= 2:
		next = move_target_path[1]
		if global_position.distance_to(next) <= 1.0:
			move_target_path.remove_at(0)
			if move_target_path.size() >= 2:
				next = move_target_path[1]
			else:
				next = move_target

	look(next)

	var desired = global_position.direction_to(next) * move_speed * get_stress_scale()

	NavigationServer3D.agent_set_position(agent_rid, global_position)
	NavigationServer3D.agent_set_velocity(agent_rid, desired)
	NavigationServer3D.agent_set_max_speed(agent_rid, move_speed * get_stress_scale())

	if move_target_velocity.length_squared() <= 0.001:
		move_target_velocity = desired

	velocity.x = move_target_velocity.x
	velocity.z = move_target_velocity.z
	move_and_slide()

func _on_heard(_at: Vector3) -> void:
	snapshot.stress_level += 0.33
	snapshot.belief_confidence += 0.5
	if state_machine.state != $Machine/Pursue:
		state_machine.shift($Machine/Hold)

func _on_spotted(at: Vector3) -> void:
	snapshot.stress_level += 1.0
	snapshot.player_visible = 1.0
	snapshot.belief_center = at
	snapshot.belief_confidence = 1.0
	snapshot.belief_radius = 1.0
	snapshot.seconds_since_seen = 0.0
	snapshot.dist_to_last_known = global_position.distance_to(at)
	snapshot.player_distance = snapshot.dist_to_last_known

	if state_machine.state != $Machine/Pursue:
		state_machine.shift($Machine/Pursue)

func _on_machine_on_enter(state: EnemyState) -> void:
	if not state.ANIMATION_ENABLED: return

	var animation = state.ANIMATION_NAME_STRESSED if is_stressed() and state.ANIMATION_NAME_STRESSED != "" else state.ANIMATION_NAME

	state_animate.play(animation, state.ANIMATION_BLEND, state.ANIMATION_SPEED)

func look(at: Vector3):
	look_target = at

func move(to: Vector3) -> void:
	var map := get_world_3d().get_navigation_map()
	move_target = NavigationServer3D.map_get_closest_point(map, to)
	var start := NavigationServer3D.map_get_closest_point(map, global_position)
	move_target_path = NavigationServer3D.map_get_path(map, start, move_target, true)

	NavigationServer3D.agent_set_position(agent_rid, global_position)
	NavigationServer3D.agent_set_velocity(agent_rid, Vector3.ZERO)
	NavigationServer3D.agent_set_max_speed(agent_rid, move_speed * get_stress_scale())

func move_cancel() -> void:
	move_target = Vector3.INF

func get_stress_scale():
	var stress = clamp(snapshot.stress_level, 0.0, 1.0)
	var speed_scale = lerp(0.85, 1.5, stress)
	return speed_scale
func is_stressed():
	return snapshot.stress_level > 0.75

func _exit_tree() -> void:
	EnemyAi.clear_enemy(self)

	if agent_rid.is_valid():
		NavigationServer3D.free_rid(agent_rid)

var _debug_belief_mesh: MeshInstance3D
var _debug_belief_immediate: ImmediateMesh
var _debug_belief_mat: StandardMaterial3D

func debug_draw_belief() -> void:
	if not snapshot:
		return

	if not _debug_belief_mesh:
		_debug_belief_immediate = ImmediateMesh.new()

		_debug_belief_mat = StandardMaterial3D.new()
		_debug_belief_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_debug_belief_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		_debug_belief_mesh = MeshInstance3D.new()
		_debug_belief_mesh.mesh = _debug_belief_immediate
		_debug_belief_mesh.material_override = _debug_belief_mat

		get_tree().current_scene.add_child(_debug_belief_mesh)

		$PivotCharacter/Eyes/MeshInstance3D1.material_override = _debug_belief_mat
		$PivotCharacter/Eyes/MeshInstance3D2.material_override = _debug_belief_mat

	var r := snapshot.belief_radius
	if r <= 0.0:
		_debug_belief_immediate.clear_surfaces()
		return

	var conf = clamp(snapshot.belief_confidence, 0.0, 1.0)
	var col := Color(0.15, 1.0, 0.15, 0.5).lerp(Color(1.0, 0.15, 0.15, 0.5), conf)
	_debug_belief_mat.albedo_color = col

	var center := snapshot.belief_center
	var segments := 32

	_debug_belief_immediate.clear_surfaces()
	_debug_belief_immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(segments + 1):
		var a := TAU * float(i) / float(segments)
		var x := cos(a) * r
		var z := sin(a) * r
		_debug_belief_immediate.surface_add_vertex(center + Vector3(x, 0.05, z))

	_debug_belief_immediate.surface_end()
