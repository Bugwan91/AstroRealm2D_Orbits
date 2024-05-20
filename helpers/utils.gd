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
