class_name GravityHandler
extends Area2D

@export var line: Line2D
@export var line_local: Line2D
@export var warp_line: Line2D
@export var line_width := 1.0
const POINTS := 64
const MIN_STEP := 0.01
const MAX_STEP_MULT := 100.0

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

func _physics_process(dt: float):
	if not is_instance_valid(celestial):
		MyDebug.info("gravity", 0.0)
		return
	var res := Utils.integrator_runge_kutta_4(
		body.global_position,
		body.absolute_velocity,
		MainState.current_time(),
		dt,
		celestial
	)
	body.force_update(res.dp, res.dv + res.dV)
	MyDebug.info("gravity", res.dv.length() / dt)
	_update_line(MainState.current_time(), dt)

func _update_line(time: float, delta: float):
	if not is_instance_valid(celestial): return
	
	var p := body.global_position
	var v := body.absolute_velocity
	
	var p_l := body.global_position - celestial.global_position
	
	var points: Array[Vector2] = []
	var points_local: Array[Vector2] = []
	var min_d := delta * 2.0
	var max_d := delta * 100.0
	var d := min_d
	points.append(p)
	points_local.append(p_l)
	
	var steps := POINTS / celestial.level()
	for i in range(0, steps):
		celestial.set_predict_time(time)
		var P := celestial.current_position(true)
		var V := celestial.current_velocity(true)
		var a := celestial.gravity(p, true)
		var dp := P - p
		var dv := v - V
		if dp.length() < celestial.influence_radius and i % 10 == 0:
			DebugDraw2d.line_vector(p, dp, Color(1,1,0, 0.1), 1.0 / MainState.camera_zoom, 0.03)
			DebugDraw2d.line_vector(p, dv, Color(1,0,0,0.1), 1.0 / MainState.camera_zoom, 0.03)
		var dvL = max((dv * 0.1).length(), 0.0001)
		d = clamp(100.0 / sqrt(dvL * a.length()), min_d, max_d)
		var res := Utils.integrator_runge_kutta_4(p, v, time, d, celestial)
		v += res.dv + res.dV
		p += res.dp
		points.append(p)
		if celestial.is_orbiting() and dp.length() < celestial.influence_radius:
			p_l += res.dp - res.dP
			points_local.append(p_l)
		time += d
	line.points = points
	line_local.points = points_local
	
	var w := body.max_warp
	var p_w := body.global_position
	var v_w := body.absolute_velocity * (1.0 + w)
	var points_warp: Array[Vector2] = []
	time = 0.0
	d = 0.0
	points_warp.append(p_w)
	for i in range(0, steps / 2):
		celestial.set_predict_time(time)
		var P := celestial.current_position(true)
		var V := celestial.current_velocity(true)
		var a_w := celestial.gravity(p_w, true)
		##var p_half = p_w + 0.5 * (v_w + a_w * d) * d
		#a_w = celestial.gravity(p_half, true)
		var dp := P - p
		var dv := v - V
		var dvL = max((dv * 0.1).length(), 0.0001)
		d = clamp(100.0 / sqrt(dvL * a_w.length()), delta, delta * MAX_STEP_MULT)
		v_w += (1.0 + w) * a_w * d
		p_w += v_w * d
		points_warp.append(p_w)
	warp_line.points = points_warp

func update_old_line():
	if not is_instance_valid(_orbit_old): return
	_orbit_old.position = body.global_position
	_orbit_old.points = line.points
