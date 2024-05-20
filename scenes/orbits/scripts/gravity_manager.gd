@tool
extends Node

const G := 100_000_000.0
# solar mass is 1000
# mu is 100_000_000_000

const FULL_GRAVITY := false

var sun: CelestialBody

func kepler_equation(E: float, e: float, mean_anomaly: float) -> float:
	return mean_anomaly - E + e * sin(E)

func kepler_derivative(E: float, e: float) -> float:
	return -1 + e * cos(E)
