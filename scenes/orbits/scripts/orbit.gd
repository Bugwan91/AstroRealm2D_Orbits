class_name OrbitCalculator
extends Node

func calculate_point_on_orbit(\
		centre_of_mass: Vector2, periapsis: float, apoapsis: float, t: float) -> Vector2:
	return Vector2.ZERO
	var semi_major_length := (periapsis + apoapsis) / 2.0
	var linear_eccentricity := semi_major_length - periapsis
	var eccentricity := linear_eccentricity / semi_major_length
	var semi_minor_length := sqrt(pow(semi_major_length, 2) - pow(linear_eccentricity, 2))
	var ellipse_centre := Vector2(centre_of_mass.x - linear_eccentricity, centre_of_mass.y)
	
	var mean_anomaly := t * PI * 2.0
	var eccentric_anomaly := _solve(\
		func(x: float): _kepler_equasion(x, mean_anomaly, eccentricity),\
		mean_anomaly, 10)
	
	return Vector2(\
		cos(eccentric_anomaly) * semi_major_length + ellipse_centre.x,\
		sin(eccentric_anomaly) * semi_minor_length + ellipse_centre.y)


func _kepler_equasion(E: float, M: float, e: float) -> float:
	return M - E + e * sin(E)


func _solve(equasion: Callable, initial_guess: float, max_iterations: int) -> float:
	const h := 0.0001
	const acceptable_error := 0.0000001
	var guess := initial_guess
	var i := 0
	var y: float
	var slope: float
	var step: float
	
	while i < max_iterations:
		i += 1
		y = equasion.call(guess)
		if abs(y) < acceptable_error: return guess
		slope = (equasion.call(guess + h) - y) / h
		step = y / slope
		guess -= step
	return guess
