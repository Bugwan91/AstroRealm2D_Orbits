extends Node2D

@export var enabled := true

@onready var origin_body: FloatingOriginKinetic = MainState.player_ship

## Position of current (0,0)
var origin := Vector2.ZERO

## Delta position of current (0,0) from last frame
var shift := Vector2.ZERO
### Hard set delta position of current (0,0)
var _extra_shift := Vector2.ZERO

## Delta position of current (0,0) from last physics tick
var phys_shift := Vector2.ZERO

## Current velocity of world
var velocity := Vector2.ZERO:
	set(value):
		velocity_delta += value - velocity
		velocity = value

var warp: float

var total_velocity: Vector2:
	get:
		return velocity * (1.0 + warp)

var speed: float:
	get:
		return total_velocity.length()

## Delta velocity of world from last frame
var velocity_delta := Vector2.ZERO

var last_update_time: float
var last_physic_time: float

func _ready():
	process_priority = -1000
	MainState.player_ship_updated.connect(reset_origin)
	last_update_time = Time.get_ticks_usec() * 0.000001
	last_physic_time = last_update_time

func _process(delta):
	if not enabled: return
	_shift_objects()

func _physics_process(delta):
	if not enabled: return
	last_physic_time = Time.get_ticks_usec() * 0.000001
	phys_shift = Vector2.ZERO
	velocity_delta = Vector2.ZERO
	MyDebug.info("origin", origin)
	MyDebug.info("origin velocity", velocity)
	MyDebug.info("warp factor", warp)
	MyDebug.info("speed base", velocity.length())
	MyDebug.info("speed total", speed)

func absolute_position(node: Node2D) -> Vector2:
	return node.global_position + origin

func _shift_objects():
	var time := Time.get_ticks_usec() * 0.000001
	shift = total_velocity * (time - last_update_time) + _extra_shift
	_extra_shift = Vector2.ZERO
	origin += shift
	for node in MainState.main_scene.get_children():
		if node is Node2D and not node == origin_body and not node.is_in_group("ignore_floating"):
			node.position -= shift
	phys_shift -= shift
	last_update_time = time

func reset_origin(body: FloatingOriginKinetic):
	origin_body = body
	if not origin_body:
		velocity_delta = -velocity
		warp = 1.0
		velocity = Vector2.ZERO

func move(delta: Vector2):
	_extra_shift += delta
