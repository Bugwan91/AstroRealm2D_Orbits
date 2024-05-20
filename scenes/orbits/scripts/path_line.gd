extends Line2D

@export var max_points := 1024
@export var draw_delta := 0.2
@export var base_width := 1.0

var _total_delta := 0.0

var _points: Array[Vector2] = []
var _camera: Camera2D

func _ready():
	_camera = get_viewport().get_camera_2d()

func _process(delta):
	_total_delta += delta
	if _total_delta > draw_delta:
		_total_delta = 0.0
		_update_line()
	points = _points
	add_point(FloatingOrigin.origin)
	width = base_width / _camera.zoom.x

func _update_line():
	_points.append(FloatingOrigin.origin)
	if _points.size() > max_points:
		_points.remove_at(0)
