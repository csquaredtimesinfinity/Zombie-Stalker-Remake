extends Node2D

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"

var c1_points: PackedVector2Array
var c2_points: PackedVector2Array
var infinity_points: PackedVector2Array

var c1_progress := 0.0
var c2_progress := 0.0
var x_progress := 0.0
var infinity_progress := 0.0

var center := Vector2.ZERO


func _ready():
	center = get_viewport_rect().size / 2.0

	_build_geometry()

	await _play_animation()

	await get_tree().create_timer(0.8).timeout

	GameManager.change_scene_to_main_menu()


func _build_geometry():

	c1_points = _build_c(center + Vector2(-80, 0), 90)
	c2_points = _build_c(center + Vector2(20, 0), 65)

	infinity_points = _build_infinity(center + Vector2(200, 0), 70, 40)


func _process(_delta):
	queue_redraw()


func _draw():

	# background
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.03, 0.03, 0.04), true)

	var col := Color(0.75, 0.95, 1.0)
	var w := 4.0

	_draw_partial(c1_points, c1_progress, col, w)
	_draw_partial(c2_points, c2_progress, col, w)
	_draw_x(col, w)
	_draw_partial(infinity_points, infinity_progress, col, w)

	if infinity_progress >= 1.0:
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-90, 140),
			"C² × ∞",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			32,
			Color.WHITE
		)


func _play_animation():

	var t := create_tween()

	t.tween_property(self, "c1_progress", 1.0, 3.0)
	t.tween_property(self, "c2_progress", 1.0, 3.9)

	t.tween_interval(0.15)

	t.tween_property(self, "x_progress", 1.0, 0.25)

	t.tween_interval(0.15)

	t.tween_property(self, "infinity_progress", 1.0, 3.3)

	await t.finished


func _draw_partial(points: PackedVector2Array, progress: float, col: Color, width: float):

	if points.size() < 2:
		return

	var count := int(points.size() * progress)
	count = maxi(2, count)

	var slice := points.slice(0, count)

	draw_polyline(slice, col, width, true)


func _draw_x(col: Color, width: float):

	if x_progress <= 0.0:
		return

	var a := center + Vector2(-25, -25)
	var b := center + Vector2(25, 25)

	var c := center + Vector2(25, -25)
	var d := center + Vector2(-25, 25)

	draw_line(a, a.lerp(b, x_progress), col, width)
	draw_line(c, c.lerp(d, x_progress), col, width)


func _build_c(pos: Vector2, radius: float) -> PackedVector2Array:

	var pts := PackedVector2Array()

	for deg in range(40, 320, 3):
		var r := deg_to_rad(deg)
		pts.append(pos + Vector2(cos(r) * radius, sin(r) * radius))

	return pts


func _build_infinity(pos: Vector2, w: float, h: float) -> PackedVector2Array:

	var pts := PackedVector2Array()

	for deg in range(0, 720, 4):
		var t := deg_to_rad(deg)
		pts.append(pos + Vector2(w * sin(t), h * sin(t) * cos(t)))

	return pts
