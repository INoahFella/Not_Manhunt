class_name EnemyConfig extends Resource

@export_group("Actions")
@export var actions: Dictionary = {
	"hold": 0.0,        # hold still, listen
	"sweep": 0.0,       # sweep the area
	#"fallback": 0.0,    # fallback to friends
	#"return": 0.0,      # return to last known
	#"probe": 0.0,       # probe the area
	#"spots": 0.0,       # check the hiding spots
	#"lure": 0.0,        # lure the player, throw bottle, make noise
	#"flank": 0.0,       # offset from last known
	#"hide": 0.0,        # hide from the player
}

@export_group("Learning")
@export var learning_rate: float = 0.025
@export var epsilon: float = 0.05
@export var weight_decay: float = 0.0005
@export var reward_clip: float = 1.0
@export var baseline_lerp: float = 0.02

@export_group("Features")
@export var feature_min: float = 0.0
@export var feature_max: float = 1.0
@export var features: Array[Callable] = [
	EnemyFeatureList.ALLIES_NEARBY,
	EnemyFeatureList.ALONE_NORMAL,
	EnemyFeatureList.BELIEF_CONFIDENCE,
	EnemyFeatureList.BELIEF_RADIUS_NORMAL,
	EnemyFeatureList.FAR_FROM_LAST_KNOWN,
	EnemyFeatureList.FRESH_TRAIL,
	EnemyFeatureList.NOISE_RECENCY,
	EnemyFeatureList.NOISE_STRENGTH_NORMAL,
	EnemyFeatureList.PLAYER_NEAR,
	EnemyFeatureList.PLAYER_VISIBLE,
	EnemyFeatureList.SEEN_STALENESS,
	EnemyFeatureList.STRESS_LEVEL,
	EnemyFeatureList.SUSPICION_PRESSURE
]

@export_group("Model")
@export var baseline: float = 0.0
@export var model: Dictionary = {}
