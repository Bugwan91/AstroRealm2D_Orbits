class_name GravityHandler
extends Area2D

@export var line: Line2D
@export var line_local: Line2D
@export var warp_line: Line2D
@export var line_width := 1.0
const POINTS := 256
const STEP := 50.0

var celestial: CelestialBody:
	set(value):
		celestial = value if is_instance_valid(value) else GravityManager.sun
		update_old_line()
		line_local.visible = not celestial.is_sun()
var body: FloatingOriginKinetic

var _orbit_old: Line2D
var _camera: Camera2D

func _ready():
	body = get_parent()
	celestial = GravityManager.sun
	_orbit_old = MainState.main_scene.orbit_line
	_camera = get_viewport().get_camera_2d()

func _process(delta):
	line.global_rotation = 0.0
	warp_line.global_rotation = 0.0
	line_local.global_rotation = 0.0
	line_local.global_position = celestial.global_position
	var w := line_width / _camera.zoom.x
	line.width = w
	warp_line.width = w
	_orbit_old.width = w
	line_local.width = w

func _physics_process(delta: float):
	var dv = celestial.gravity(body.global_position)
	DebugDraw2d.line_vector(global_position, global_position + dv * 10.0, Color(1,1,1), 4)
	MyDebug.info("gravity", dv.length())
	body.add_velocity(dv * delta)
	_update_line()

func _update_line():
	pass
	#var points: Array[Vector2] = []
	#var points_local: Array[Vector2] = []
	#var w := body.max_warp
	#
	#var v := body.absolute_velocity
	#var p := body.position
	#
	#var vl := body.absolute_velocity - celestial.current_velocity()
	#var pl := body.position - celestial.global_position
	#
	#var pw := body.position
	#var vw := v * (1.0 + w)
	#
	#var time := 0.0
	#var d := 0.0
	#
	#points.append(p)
	#points_local.append(pl)
	#
	#for i in range(0, POINTS):
		#celestial.set_virtual_time(time)
		#var dv := celestial.gravity(p, true)
		#d = STEP / dv.length()
		#v += dv * d
		#p += v * d
		#points.append(p)
		#
		#var dvl := dv - celestial.current_acceleration(true)
		#vl += dvl * d
		#pl += vl * d - celestial.current_velocity(true) * d
		#points_local.append(pl + Vector2(50.0, 50.0))
		#
		#time += d
	#line.points = points
	#line_local.points = points_local
	#
	#if body.max_warp < 0.001: return
	#var points_warp: Array[Vector2] = []
	#time = 0.0
	#d = 0.0
	#points_warp.append(pw)
	#for i in range(0, POINTS):
		#celestial.set_virtual_time(time)
		#var dvw := (1.0 + w) * celestial.gravity(p, true)
		#d = STEP / dvw.length()
		#vw += dvw * d
		#pw += vw * d
		#points_warp.append(pw)
		#time += d
	#warp_line.points = points_warp

func update_old_line():
	if not is_instance_valid(_orbit_old): return
	_orbit_old.position = body.global_position
	_orbit_old.points = line.points
