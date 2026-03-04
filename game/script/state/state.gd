class_name State extends Node

@export_category('Animation')
@export var ANIMATION_ENABLED: bool
@export var ANIMATION_NAME: String
@export var ANIMATION_SPEED: float = 1.0
@export_range(0, 5.0, 0.1) var ANIMATION_BLEND: float
@export_category('Audio')
@export var ENTER_SOUNDS: Array[SoundEffect]
@export var LEAVE_SOUNDS: Array[SoundEffect]

var machine: StateMachine:
	get(): return get_parent() as StateMachine
var animate: AnimationPlayer:
	get(): return machine.animate as AnimationPlayer
var animate_sword: AnimationPlayer:
	get(): return machine.animate_sword as AnimationPlayer
var state: State:
	get(): return machine.state as State
var player: Player:
	get(): return machine.player as Player
var camera: PlayerCamera:
	get(): return machine.camera as PlayerCamera
var queue: String:
	get(): return machine.queue as String

func enter() -> void: pass
	
func leave() -> void: pass
	
func frame(_delta: float, _input: Vector3) -> void: pass
