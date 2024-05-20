class_name SpeedMonitor
extends Node2D

@export var enabled := false

var _last_position: Vector2
var _v: Vector2

func _ready():
	_last_position = global_position + FloatingOrigin.origin

func _physics_process(delta):
	if not enabled: return
	var p := global_position + FloatingOrigin.origin
	_v = (p - _last_position) / delta
	MyDebug.info("spd", _v.length())
	_last_position = p
