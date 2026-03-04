class_name StateMachine extends Node

signal on_enter(state: State)
signal on_leave(state: State)
signal on_frame(input: Vector2)

var state: State
var animate: AnimationPlayer
var player: Player
var camera: PlayerCamera
var queue: String:
	get(): return player.input_queue

func shift(to: State):
	if state:
		on_leave.emit(to)
		state.leave()
		SFX.play_all(state.LEAVE_SOUNDS, player)
	on_enter.emit(to)
	state = to
	to.enter()
	SFX.play_all(state.ENTER_SOUNDS, player)

func shift_forced(to: State):
	on_enter.emit(to)
	to.enter()
	state = to

func frame(delta: float, input: Vector3):
	if state: 
		state.frame(delta, input)
		on_frame.emit(input)
