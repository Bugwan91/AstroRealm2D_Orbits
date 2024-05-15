class_name GravityHandler
extends Area2D

@export var line: Line2D
const POINTS = 256

var ship: Spaceship
var current_body: CelestialBody

func _ready():
	ship = get_parent()
	current_body = GravityManager.sun

func _process(delta):
	line.global_rotation = 0.0

func _physics_process(delta: float):
	var delta_p = current_body.global_position - ship.global_position
	var dir = delta_p.normalized()
	var dist = delta_p.length()
	var mass = current_body.mass
	var dv = (GravityManager.G * current_body.mass / pow(dist, 2)) * dir
	ship.add_velocity(dv * delta)
	_update_line()

func _update_line():
	var points: Array[Vector2] = []
	var m = current_body.mass
	var v = ship.absolute_velocity
	var w = ship.warp
	var p = ship.position
	points.append(p)
	for i in range(0, POINTS):
		var delta_p = current_body.global_position - p
		var dist = delta_p.length()
		var dir = delta_p / dist
		v += GravityManager.G * current_body.mass / pow(dist, 2) * dir
		p += v * (1.0 + w)
		points.append(p)
	line.points = points
