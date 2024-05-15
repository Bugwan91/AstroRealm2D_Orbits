@tool
class_name CelestialBody
extends Node2D

@export var mass := 1.0
@export var velocity := Vector2.ZERO
@export var parent: CelestialBody

var _equilibrium: float

var _influence_circle: CircleShape2D

func _ready():
	if not is_instance_valid(parent):
		if Engine.is_editor_hint(): return
		GravityManager.sun = self
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	_influence_circle = CircleShape2D.new()
	_update_influence_area()
	shape.shape = _influence_circle
	add_child(area)
	area.add_child(shape)
	area.monitorable = false
	area.area_entered.connect(on_entered)
	area.area_exited.connect(on_exit)

func _calculate_equlibrium_radius() -> float:
	if not is_instance_valid(parent): return 1000 * mass
	var m = mass
	var M = parent.mass
	var R = (position - parent.position).length()
	if abs(M - m) < 0.01: return 0.5 * R
	var r = R*(sqrt(m*M) - m)/(M-m)
	return abs(r)

func on_entered(object: Area2D):
	if not object is GravityHandler: return
	(object as GravityHandler).current_body = self

func on_exit(object: Area2D):
	if not object is GravityHandler: return
	(object as GravityHandler).current_body = parent

func _update_influence_area():
	_influence_circle.radius = _calculate_equlibrium_radius()

func _get_tool_buttons() -> Array:
	return [
		_update_influence_area
	]
