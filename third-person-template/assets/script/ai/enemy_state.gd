class_name EnemyState extends Node

@export_category('Animation')
@export var ANIMATION_ENABLED: bool
@export var ANIMATION_NAME: String
@export var ANIMATION_SPEED: float = 1.0
@export var ANIMATION_NAME_STRESSED: String
@export_range(0, 5.0, 0.1) var ANIMATION_BLEND: float
@export_category('Audio')
@export var ENTER_SOUNDS: Array[SoundEffect]
@export var LEAVE_SOUNDS: Array[SoundEffect]

var machine: EnemyMachine:
	get(): return get_parent() as EnemyMachine
var animate: AnimationPlayer:
	get(): return machine.animate as AnimationPlayer
var state: EnemyState:
	get(): return machine.state as EnemyState
var enemy: Enemy:
	get(): return machine.enemy as Enemy

func enter() -> void: pass
	
func leave() -> void: pass

func prize(_start: EnemySnapshot, _end: EnemySnapshot) -> void: pass
	
func frame(_delta: float) -> void: pass
