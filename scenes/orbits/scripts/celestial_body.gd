@tool
class_name CelestialBody
extends Node2D

@export var mass := 1.0
@export var dynamic := true
@export var orbit: KeplerOrbit
@export var orbit_color: Gradient

var parent: CelestialBody
var main_state: OrbitState = OrbitState.new()
var predict_state: OrbitState = OrbitState.new()

var r_influence: float:
	set(value):
		r_influence = value
		_influence_circle.radius = r_influence
		_influence_area.monitoring = r_influence > 0.1

var _equilibrium: float
var _influence_area := Area2D.new()
var _influence_circle: CircleShape2D

var _orbit_line: Line2D
var _global_orbit_line: Line2D

func _ready():
	_setup_parent()
	_setup_influence_area()
	_setup_orbit()
	_update()

func _process(delta: float):
	if Engine.is_editor_hint(): return
	_update_orbit_lines()
	if dynamic:
		_update()
		main_state.update()
		position =  main_state.position
		draw_orbit()

func _physics_process(_delta: float):
	_update_influence_area()

func _get_tool_buttons() -> Array:
	return [
		_update_influence_area
	]

func on_entered(object: Area2D):
	if not object is GravityHandler: return
	(object as GravityHandler).celestial = self

func on_exit(object: Area2D):
	if not object is GravityHandler: return
	(object as GravityHandler).celestial = parent

func _update():
	main_state.update()
	if Engine.is_editor_hint(): return
	position = main_state.position
	draw_orbit()

func _setup_influence_area():
	var shape := CollisionShape2D.new()
	shape.debug_color.a = 0.01
	_influence_circle = CircleShape2D.new()
	shape.shape = _influence_circle
	add_child(_influence_area)
	_influence_area.add_child(shape)
	_influence_area.monitorable = false
	_influence_area.area_entered.connect(on_entered)
	_influence_area.area_exited.connect(on_exit)
	_update_influence_area()

func _setup_parent():
	var p = get_parent()
	if p is CelestialBody:
		parent = p
	else:
		GravityManager.sun = self
		dynamic = false

func _setup_orbit():
	if is_sun(): return
	orbit.semi_major_axis = position.length()
	orbit.M = parent.mass
	orbit.recalculate_const_properties()
	main_state.orbit = orbit
	main_state.update()
	predict_state.orbit = orbit
	_setup_orbit_line()

func _setup_orbit_line():
	_orbit_line = Line2D.new()
	_orbit_line.gradient = orbit_color
	_orbit_line.width = 2.0
	_orbit_line.closed = true
	add_child(_orbit_line)
	
	_global_orbit_line = Line2D.new()
	_global_orbit_line.gradient = orbit_color
	_global_orbit_line.width = 1.0
	_global_orbit_line.closed = false
	add_child(_global_orbit_line)

func _update_orbit_lines():
	if is_sun(): return
	_orbit_line.global_position = parent.global_position
	_orbit_line.width = 2.0 / MainState.camera_zoom
	if not is_instance_valid(GravityManager.sun): return
	_global_orbit_line.global_position = GravityManager.sun.global_position
	_global_orbit_line.width = 1.0 / MainState.camera_zoom

func draw_orbit():
	_update_orbit_lines()
	if is_sun(): return
	_orbit_line.points = main_state.orbit_points()
	if not is_instance_valid(GravityManager.sun): return
	_global_orbit_line.points = _global_orbit_points()

func is_sun() -> bool:
	return not is_instance_valid(parent)

func is_orbiting() -> bool:
	return not is_sun() and dynamic

func gravity(p: Vector2, predict: bool = false) -> Vector2:
	var delta_p = current_position(predict) - p
	var dir = delta_p.normalized()
	var a: Vector2 = (GravityManager.G * mass / delta_p.length_squared()) * dir
	if GravityManager.FULL_GRAVITY and not is_sun(): a += parent.gravity(p, predict)
	return a

func set_predict_time(time: float):
	predict_state.update(time)
	if not is_sun(): parent.set_predict_time(time)

func state(predict: bool = false) -> OrbitState:
	return predict_state if predict and is_orbiting() else main_state

func current_position(predict: bool = false) -> Vector2:
	if is_sun(): return global_position
	return state(predict).position + parent.current_position(predict)

func current_velocity(predict: bool = false) -> Vector2:
	if is_sun(): return Vector2.ZERO
	return state(predict).velocity + parent.current_velocity(predict)

func current_acceleration(predict: bool = false) -> Vector2:
	if is_sun(): return Vector2.ZERO
	return state(predict).acceleration + parent.current_acceleration(predict)

func _sphere_of_influence() -> float:
	if is_sun(): return sqrt(GravityManager.G * mass / GravityManager.GRAVITY_THRESHOLD)
	var m := mass
	var M := parent.mass
	var R := position.length()
	return R * pow(m/M, 2.0 / 5.0)

func _calculate_equlibrium_radius() -> float:
	if is_sun(): return sqrt(GravityManager.G * mass / GravityManager.GRAVITY_THRESHOLD)
	var m := mass
	var M := parent.mass
	var R := position.length()
	if abs(M - m) < 0.01: return 0.5 * R
	var r = R*(sqrt(m*M) - m)/(M-m)
	return abs(r)

func _update_influence_area():
	r_influence = _calculate_equlibrium_radius()
	#_sphere_of_influence()
	

func _global_orbit_points(segments_count: int = 256, rotations: int = 5.0) -> Array[Vector2]:
	if not is_orbiting() or not parent.is_orbiting(): return []
	var points: Array[Vector2] = []
	var ratio = orbit.T / parent.orbit.T
	var theta_step := TAU / segments_count
	for i in range(segments_count * rotations):
		var p_l := orbit.ellipse_point_for(state().true_anomaly + i * theta_step)
		var p_g := parent.orbit.ellipse_point_for(parent.state().true_anomaly + i * theta_step * ratio)
		points.append(p_l + p_g)
	return points
