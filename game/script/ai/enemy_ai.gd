extends Node

var config: EnemyConfig = preload("uid://cu8fhcw6uythd")
var _pending: Dictionary = {}

func _ready():
	initialize()

func initialize() -> void:
	_pending.clear()

	for k in config.actions.keys():
		var action := StringName(str(k))
		if not config.model.has(action):
			var v := PackedFloat32Array()
			v.resize(config.features.size())
			for i in v.size():
				v[i] = 0.0
			config.model[action] = v

func decide(enemy: Node, snap: EnemySnapshot) -> String:
	if config == null or enemy == null or snap == null:
		return ""
	if config.actions.is_empty() or config.features.is_empty():
		return ""

	var x := _eval_features(snap)

	var explore := randf() < config.epsilon
	var chosen_action := ""
	var chosen_pred := -INF

	if explore:
		var keys := config.actions.keys()
		chosen_action = str(keys[randi() % keys.size()])
		chosen_pred = _score_action(chosen_action, x)
	else:
		var best := -INF
		for k in config.actions.keys():
			var action := str(k)
			var s := _score_action(action, x)
			if s > best:
				best = s
				chosen_action = action
				chosen_pred = s

	_pending[enemy.get_instance_id()] = {
		"action": StringName(chosen_action),
		"x": x,
		"pred": chosen_pred
	}

	return chosen_action

func reward(enemy: Node, reward_value: float) -> void:
	if config == null or enemy == null:
		return

	var id := enemy.get_instance_id()
	if not _pending.has(id):
		return

	var rec: Dictionary = _pending[id]
	_pending.erase(id)

	var action: StringName = rec["action"]
	var x: PackedFloat32Array = rec["x"]
	var pred: float = float(rec["pred"])

	var r = clamp(float(reward_value), -config.reward_clip, config.reward_clip)

	# baseline update
	config.baseline = lerp(config.baseline, r, config.baseline_lerp)

	# prediction error
	var err = (r - config.baseline) - pred

	# update weights for that action
	var w: PackedFloat32Array = config.model[action]
	for i in x.size():
		w[i] = w[i] * (1.0 - config.weight_decay)
		w[i] += config.learning_rate * err * x[i]
	config.model[action] = w

func clear_enemy(enemy: Node) -> void:
	if enemy == null:
		return
	_pending.erase(enemy.get_instance_id())

func is_executing(enemy: Node) -> bool:
	return _pending.has(enemy.get_instance_id())

func _score_action(action: String, x: PackedFloat32Array) -> float:
	var a := StringName(action)
	var w: PackedFloat32Array = config.model[a]

	var s := 0.0
	for i in x.size():
		s += w[i] * x[i]

	# Add the bias weight from config.actions
	s += float(config.actions.get(action, 0.0))
	return s

func _eval_features(snap: EnemySnapshot) -> PackedFloat32Array:
	var x := PackedFloat32Array()
	x.resize(config.features.size())

	for i in config.features.size():
		var f := config.features[i]
		var raw := float(f.call(snap)) * float(EnemyFeatureList.SCALE)
		x[i] = clamp(raw, config.feature_min, config.feature_max)

	return x
