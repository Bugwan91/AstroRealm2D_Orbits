@tool
class_name KeplerOrbit
extends Resource

@export var semi_major_axis: float
@export var eccentricity: float
@export var argument_of_periapsis: float
@export var M: float

var semi_minor_axis: float
var linear_eccentricity: float
var true_anomaly_const: float
var mu: float
var T: float

func recalculate_const_properties():
	linear_eccentricity = eccentricity * semi_major_axis
	semi_minor_axis = sqrt(pow(semi_major_axis, 2) - pow(linear_eccentricity, 2))
	true_anomaly_const = sqrt((1 + eccentricity) / (1 - eccentricity))
	mu = GravityManager.G * M
	T = TAU * sqrt(pow(semi_major_axis, 3) / mu)

func ellipse_point_for(true_anomaly: float) -> Vector2:
	var distance := semi_major_axis * (1.0 - eccentricity * eccentricity) / (1.0 + eccentricity * cos(true_anomaly))
	return Vector2(
		distance * cos(argument_of_periapsis + true_anomaly),
		distance * sin(argument_of_periapsis + true_anomaly)
	)
