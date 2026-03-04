class_name EnemySnapshot extends Resource

@export var noise_strength: float = 0.0
@export var seconds_since_last_noise: float = 999.0
@export var seconds_since_seen: float = 999.0
@export var dist_to_last_known: float = 0.0
@export var allies_nearby_norm: float = 0.0
@export var stress_level: float = 0.0
@export var player_visible: float = 0.0
@export var player_distance: float = 0.0
@export var belief_center: Vector3 = Vector3.INF
@export var belief_radius: float = 0.0
@export var belief_confidence: float = 0.0

func _to_string() -> String:
	return "[EnemySnapshot] " + \
		"noise=%.2f " % noise_strength + \
		"noise_age=%.2f " % seconds_since_last_noise + \
		"seen_age=%.2f " % seconds_since_seen + \
		"dist_last=%.2f " % dist_to_last_known + \
		"allies=%.2f " % allies_nearby_norm + \
		"stress=%.2f " % stress_level + \
		"visible=%.1f " % player_visible + \
		"player_dist=%.2f " % player_distance + \
		"belief_center=(%.2f, %.2f, %.2f) " % [belief_center.x, belief_center.y, belief_center.z] + \
		"belief_radius=%.2f " % belief_radius + \
		"belief_conf=%.2f" % belief_confidence
