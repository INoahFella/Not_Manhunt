class_name EnemyFeatureList

static var SCALE = 1.0

static var ALLIES_NEARBY: Callable = func(snap: EnemySnapshot) -> float:
	return clamp(snap.allies_nearby_norm, 0.0, 1.0) * SCALE
	
static var ALONE_NORMAL: Callable = func(snap: EnemySnapshot) -> float:
	return (1.0 - clamp(snap.allies_nearby_norm, 0.0, 1.0)) * SCALE
	
static var BELIEF_CONFIDENCE: Callable = func(snap: EnemySnapshot) -> float:
	return clamp(snap.belief_confidence, 0.0, 1.0) * SCALE
	
static var BELIEF_RADIUS_NORMAL: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_DISTANCE = 40.0
	return clamp(snap.belief_radius / MAX_DISTANCE, 0.0, 1.0) * SCALE
	
static var FAR_FROM_LAST_KNOWN: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_DISTANCE = 30.0
	return clamp(snap.dist_to_last_known / MAX_DISTANCE, 0.0, 1.0) * SCALE
	
static var FRESH_TRAIL: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_NOISE = 1.0
	const MAX_NOISE_SECONDS = 10.0
	
	if MAX_NOISE <= 0.0 or MAX_NOISE_SECONDS <= 0.0:
		return 0.0
	var n = clamp(snap.noise_strength / MAX_NOISE, 0.0, 1.0)
	var t = clamp(snap.seconds_since_last_noise / MAX_NOISE_SECONDS, 0.0, 1.0)
	var recency = 1.0 - t
	return (n * recency) * SCALE
	
static var NEAR_LAST_KNOWN: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_DISTANCE = 30.0
	var d = clamp(snap.dist_to_last_known / MAX_DISTANCE, 0.0, 1.0)
	return (1.0 - d) * SCALE
	
static var NOISE_RECENCY: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_SECONDS = 10.0
	var t = clamp(snap.seconds_since_last_noise / MAX_SECONDS, 0.0, 1.0)
	return (1.0 - t) * SCALE
	
static var NOISE_STRENGTH_NORMAL: Callable = func(snap: EnemySnapshot) -> float:
	return clamp(snap.noise_strength, 0.0, 1.0) * SCALE
	
static var PLAYER_NEAR: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_DISTANCE = 20.0
	var d = clamp(snap.player_distance / MAX_DISTANCE, 0.0, 1.0)
	return (1.0 - d) * SCALE
	
static var PLAYER_VISIBLE: Callable = func(snap: EnemySnapshot) -> float:
	return clamp(snap.player_visible, 0.0, 1.0) * SCALE
	
static var SEEN_STALENESS: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_SECONDS = 30.0
	return clamp(snap.seconds_since_seen / MAX_SECONDS, 0.0, 1.0) * SCALE
	
static var STRESS_LEVEL: Callable = func(snap: EnemySnapshot) -> float:
	return clamp(snap.stress_level, 0.0, 1.0) * SCALE
	
static var SUSPICION_PRESSURE: Callable = func(snap: EnemySnapshot) -> float:
	const MAX_SEEN_SECONDS = 10.0
	var stress = clamp(snap.stress_level, 0.0, 1.0)
	var seen_stale = clamp(snap.seconds_since_seen / MAX_SEEN_SECONDS, 0.0, 1.0)
	return (stress * seen_stale) * SCALE
