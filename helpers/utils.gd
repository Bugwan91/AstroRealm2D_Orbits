@tool
extends Node

func newton_solver(\
	F: Callable, DF: Callable,\
	initial_guess: float, accuracy_tolerance: float = 0.001, max_iterations: int = 10) -> float:
	var x := initial_guess
	var diff: float = INF
	var i := 0
	while diff > accuracy_tolerance and i < max_iterations:
		i += 1
		var x1: float = x - F.call(x) / DF.call(x)
		diff = abs(x1 - x)
		x = x1
	return x

static func solve_parabolic_anomaly(mean_anomaly: float) -> float:
	# Implement the solver for parabolic anomalies
	return 2 * atan(mean_anomaly / 2) # Simplified

static func solve_hyperbolic_anomaly(mean_anomaly: float, eccentricity: float) -> float:
	# Implement the solver for hyperbolic anomalies
	var H := mean_anomaly
	while true:
		var next_H := H - (H - eccentricity * sinh(H) - mean_anomaly) / (1 - eccentricity * cosh(H))
		if abs(next_H - H) < 1e-6: break
		H = next_H
	return H

func integrator_runge_kutta_4(p: Vector2, v: Vector2, t0: float, dt: float, celestial: CelestialBody) -> PositionVelocityDelta:
	var res := PositionVelocityDelta.new()
	celestial.set_predict_time(t0)
	var P0 := celestial.current_position(true)
	var V0 := celestial.current_velocity(true)
	var k1_a := celestial.gravity(p)
	var k1_v := v
	celestial.set_predict_time(t0 + 0.5 * dt)
	var k2_a := celestial.gravity(p + 0.5 * dt * k1_v, true)
	var k2_v := v + 0.5 * dt * k1_a
	var k3_a := celestial.gravity(p + 0.5 * dt * k2_v, true)
	var k3_v := v + 0.5 * dt * k2_a
	celestial.set_predict_time(t0 + dt)
	res.dV = celestial.current_velocity(true) - V0
	res.dP = celestial.current_position(true) - P0
	var k4_a := celestial.gravity(p + dt * k3_v, true)
	var k4_v := v + dt * k3_a
	res.dv = (dt / 6.0) * (k1_a + 2.0 * (k2_a + k3_a) + k4_a)
	res.dp = (dt / 6.0) * (k1_v + 2.0 * (k2_v + k3_v) + k4_v)
	return res
