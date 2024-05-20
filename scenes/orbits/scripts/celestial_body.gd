@tool
class_name CelestialBody
extends Node2D

@export var mass := 1.0
@export var dynamic := true
@export var orbit: KeplerOrbit
@export var orbit_color: Gradient

var parent: CelestialBody
var main_state: OrbitState
var virtual_state: OrbitState

var _equilibrium: float
var _influence_area := Area2D.new()
var _influence_circle: CircleShape2D

var _orbit_line: Line2D

func _ready():
	_setup_parent()
	_setup_influence_area()
	_setup_orbit()

func _process(delta: float):
	if Engine.is_editor_hint(): return
	if dynamic:
		main_state.update()
		position = main_state.point
		draw_orbit()

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
	main_state = OrbitState.new()
	main_state.orbit = orbit
	main_state.update()
	virtual_state = OrbitState.new()
	virtual_state.orbit = orbit
	_setup_orbit_line()

func _setup_orbit_line():
	_orbit_line = Line2D.new()
	_orbit_line.gradient = orbit_color
	_orbit_line.width = 2.0
	_orbit_line.closed = true
	add_child(_orbit_line)

func draw_orbit():
	if is_sun(): return
	_orbit_line.points = main_state.draw_orbit()
	_orbit_line.global_position = parent.global_position
	_orbit_line.width = 2.0 / MainState.camera_zoom

func is_sun() -> bool:
	return not is_instance_valid(parent)

func is_orbiting() -> bool:
	return not is_sun() and dynamic

func gravity(p: Vector2, virtual: bool = false) -> Vector2:
	var delta_p = current_position(virtual) - p
	var dist = delta_p.length()
	var dir = delta_p / dist
	var a: Vector2 = (GravityManager.G * mass / pow(dist, 2)) * dir
	if GravityManager.FULL_GRAVITY and not is_sun(): a += parent.gravity(p, virtual)
	return a

func set_virtual_time(time: float):
	if is_sun(): return
	virtual_state.time = time
	parent.set_virtual_time(time)

func state(virtual: bool = false) -> OrbitState:
	return virtual_state if virtual else main_state

func current_position(virtual: bool = false) -> Vector2:
	return state(virtual).point if is_orbiting() else global_position + _parent_position(virtual)

func _parent_position(virtual: bool = false) -> Vector2:
	return parent.current_position(virtual) if not is_sun() else Vector2.ZERO

func current_velocity(virtual: bool = false) -> Vector2:
	return (state(virtual).velocity if is_orbiting() else Vector2.ZERO) + _parent_velocity(virtual)

func _parent_velocity(virtual: bool = false) -> Vector2:
	return parent.current_velocity(virtual) if not is_sun() else Vector2.ZERO

func current_acceleration(virtual: bool = false) -> Vector2:
	return (state(virtual).acceleration if is_orbiting else Vector2.ZERO) + _parent_acceleration(virtual)

func _parent_acceleration(virtual: bool = false) -> Vector2:
	return parent.current_acceleration(virtual) if not is_sun() else Vector2.ZERO

func _sphere_of_influence() -> float:
	if is_sun(): return 0.0
	var m := mass
	var M := parent.mass
	var R := position.length()
	return R * pow(m/M, 2.0 / 5.0)

func _calculate_equlibrium_radius() -> float:
	if is_sun(): return 0.0
	var m := mass
	var M := parent.mass
	var R := position.length()
	if abs(M - m) < 0.01: return 0.5 * R
	var r = R*(sqrt(m*M) - m)/(M-m)
	return abs(r)

func _update_influence_area():
	_setup_parent()
	_influence_circle.radius = _calculate_equlibrium_radius()
	#_influence_circle.radius = _sphere_of_influence()
	_influence_area.monitoring = _influence_circle.radius > 0.1


