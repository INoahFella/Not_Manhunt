class_name EnemyMachine extends Node

signal on_enter(state: EnemyState)
signal on_leave(state: EnemyState)
signal on_frame()

var state: EnemyState
var animate: AnimationPlayer
var enemy: Enemy
var snapshot_frozen: EnemySnapshot

func shift(to: EnemyState):
	if state and snapshot_frozen:
		state.prize(snapshot_frozen, enemy.snapshot.duplicate(true))
	if state:
		on_leave.emit(to)
		state.leave()
		SFX.play_all(state.LEAVE_SOUNDS, enemy)
	on_enter.emit(to)
	state = to
	snapshot_frozen = enemy.snapshot.duplicate(true)
	to.enter()
	SFX.play_all(state.ENTER_SOUNDS, enemy)

func shift_forced(to: EnemyState):
	on_enter.emit(to)
	to.enter()
	state = to

func frame(delta: float):
	if state: 
		state.frame(delta)
		on_frame.emit()
