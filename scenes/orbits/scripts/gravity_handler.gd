class_name GravityHandler
extends Area2D

@export var line: Line2D
@export var line_local: Line2D
@export var warp_line: Line2D
@export var line_width := 1.0
const POINTS := 256
const STEP := 500.0
const MIN_STEP := 0.00033
const DIST_MOD := 0.001

var celestial: CelestialBody:
	set(value):
		celestial = value
		update_old_line()
		var exists := is_instance_valid(celestial)
		line_local.visible = exists and celestial.is_orbiting()
		line.visible = exists
		warp_line.visible = exists
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
	var w := line_width / _camera.zoom.x
	line.width = w
	warp_line.width = w
	_orbit_old.width = w
	line_local.width = w
	if not is_instance_valid(celestial): return
	line_local.global_position = celestial.global_position

func _physics_process(delta: float):
	if not is_instance_valid(celestial):
		MyDebug.info("gravity", 0.0)
		return
	var a = celestial.gravity(body.global_position)
	var precision_rate: int = min(floor(a.length() / 100.0), 50)
	if precision_rate > 0:
		var step := delta / precision_rate
		var p := body.global_position
		var v := body.absolute_velocity
		var a_step := Vector2.ZERO
		var shift := Vector2.ZERO
		for i in range(0, precision_rate):
			celestial.set_predict_time(i * step)
			a_step = celestial.gravity(p + shift, true)
			v += a_step * step
			shift += v * step
		a = (v - body.absolute_velocity) / delta
		body.add_position(shift)
	else:
		a = 0.5 * (a + celestial.gravity(body.global_position + (body.absolute_velocity + a * delta) * delta))
	MyDebug.info("gravity", a.length())
	body.add_velocity((a + celestial.current_acceleration()) * delta)
	_update_line()

func _update_line():
	if not is_instance_valid(celestial): return
	
	var p := body.global_position
	var v := body.absolute_velocity
	
	var P_start := celestial.global_position
	var p_l := body.position - celestial.global_position
	
	var points: Array[Vector2] = []
	var points_local: Array[Vector2] = []
	var time := 0.0
	var d := 0.0
	points.append(p)
	#points_local.append(pl)
	for i in range(0, POINTS):
		celestial.set_predict_time(time)
		var a := celestial.gravity(p, true)
		var P := celestial.current_position(true)
		var dp := P - p
		var dv := v - celestial.current_velocity(true)
		if dp.length() < celestial.r_influence and i % 10 == 0:
			DebugDraw2d.line_vector(p, dp, Color(1,1,0, 0.1), 1.0 / MainState.camera_zoom, 0.03)
			DebugDraw2d.line_vector(p, dv, Color(1,0,0,0.1), 1.0 / MainState.camera_zoom, 0.03)
		var dpL := sqrt(absf(dp.x * DIST_MOD + dp.y * DIST_MOD))
		d = max((50.0 * dpL) / (a.length() + 0.1 * dv.length()), MIN_STEP)
		v += (a + celestial.current_acceleration(true)) * d
		p += v * d
		points.append(p)
		
		var p_shift := P - P_start
		p_l += v * d + p_shift
		points_local.append(p_l)
		
		time += d
	line.points = points
	line_local.points = points_local
	
	
	var w := body.max_warp
	p = body.global_position
	v = body.absolute_velocity * (1.0 + w)
	if body.max_warp < 0.001: return
	var points_warp: Array[Vector2] = []
	time = 0.0
	d = 0.0
	points_warp.append(p)
	for i in range(0, POINTS):
		celestial.set_predict_time(time)
		var a := celestial.gravity(p, true)
		var dp := celestial.current_position(true) - p
		var dv := v - celestial.current_velocity(true)
		var dpL := sqrt(absf(dp.x * DIST_MOD + dp.y * DIST_MOD))
		d = max((50.0 * dpL) / (a.length() + 0.1 * dv.length()), MIN_STEP)
		v += (1.0 + w) * a * d + celestial.current_acceleration(true) * d
		p += v * d
		points_warp.append(p)
	warp_line.points = points_warp

func update_old_line():
	if not is_instance_valid(_orbit_old): return
	_orbit_old.position = body.global_position
	_orbit_old.points = line.points
