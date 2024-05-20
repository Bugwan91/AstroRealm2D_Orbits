class_name OrbitState
extends Node

@export var orbit: KeplerOrbit

var from_periapsis_time: float
var mean_anomaly: float
var eccentric_anomaly: float
var true_anomaly: float
var distance: float
var radial_distance: float
var position: Vector2
var velocity: Vector2
var acceleration: Vector2

var _time: float

func update(extra_time: float = 0.0):
	if not is_instance_valid(orbit): return
	_set_time(extra_time)
	_recalculate_state()

func _set_time(extra_time: float = 0.0):
	_time = MainState.current_time() + extra_time
	_from_periapsis_time()

func _recalculate_state():
	_anomalies()
	_distance()
	_radial_distance()
	_position()
	_velocity()
	_acceleration()

func _from_periapsis_time():
	var t := _time / orbit.T
	from_periapsis_time = t - floorf(t)

func _anomalies():
	mean_anomaly = from_periapsis_time * TAU
	eccentric_anomaly = Utils.newton_solver(
		func(x: float): return GravityManager.kepler_equation(x, orbit.eccentricity, mean_anomaly),
		func(x: float): return GravityManager.kepler_derivative(x, orbit.eccentricity),
		mean_anomaly)
	true_anomaly = 2.0 * atan(orbit.true_anomaly_const * tan(eccentric_anomaly / 2.0))

func _distance():
	distance = orbit.semi_major_axis * (1.0 - orbit.eccentricity * cos(eccentric_anomaly))

func _radial_distance():
	radial_distance = orbit.semi_major_axis * (1.0 - pow(orbit.eccentricity, 2.0))\
		/ (1.0 + orbit.eccentricity * cos(true_anomaly))

func _position():
	position = Vector2(
		distance * cos(orbit.argument_of_periapsis + true_anomaly),
		distance * sin(orbit.argument_of_periapsis + true_anomaly)
	)

func _velocity():
	var speed := sqrt(orbit.mu * (2.0 / radial_distance - 1.0 / orbit.semi_major_axis))
	velocity = Vector2(
		-speed * sin(true_anomaly),
		speed * (orbit.eccentricity + cos(true_anomaly))
	).rotated(orbit.argument_of_periapsis)

func _acceleration():
	var acc := -orbit.mu / (pow(radial_distance, 2.0))
	acceleration = Vector2(
		acc * cos(true_anomaly),
		acc * sin(true_anomaly)
	).rotated(orbit.argument_of_periapsis)

func orbit_points(segments_count: int = 128) -> Array[Vector2]:
	if not is_instance_valid(orbit): return []
	var points: Array[Vector2] = []
	var theta_step := TAU / segments_count
	for i in range(segments_count + 1):
		points.append(orbit.ellipse_point_for(true_anomaly - i * theta_step))
	return points
