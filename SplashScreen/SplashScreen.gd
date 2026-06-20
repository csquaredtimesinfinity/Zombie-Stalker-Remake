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

var time := 0.0

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


func _process(delta):
	time += delta
	queue_redraw()

func _jitter(p: Vector2, intensity: float) -> Vector2:
	var t := time * 6.0

	# layered noise (gives "machine struggling to stabilize" feel)
	var n1 := sin(p.x * 0.08 + t) * cos(p.y * 0.06 - t * 1.3)
	var n2 := sin((p.x + p.y) * 0.05 + t * 1.7)

	var n := (n1 + n2 * 0.5)

	# directional instability (bias makes it feel less random)
	var dir := Vector2(1.0, 0.35).normalized()

	return p + dir * n * intensity

func _draw():

	# background
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.03, 0.03, 0.04), true)
	
	var col := Color(0.75, 0.95, 1.0)
	var w := 4.0
	
	var breathe := 1.0 + sin(time * 100.5) * 0.02
	col *= breathe

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
		
	for y in range(0, int(get_viewport_rect().size.y), 6):
		var alpha := 0.02 + sin(y * 0.1 + time * 5.0) * 0.01
		draw_line(
			Vector2(0, y),
			Vector2(get_viewport_rect().size.x, y),
			Color(1, 1, 1, alpha),
			1.0
		)


func _play_animation():

	var t := create_tween()

	t.tween_property(self, "c1_progress", 1.0, 1.5)
	t.tween_property(self, "c2_progress", 1.0, 1.5)

	t.tween_interval(0.15)

	t.tween_property(self, "x_progress", 1.0, 0.25)

	t.tween_interval(0.15)

	t.tween_property(self, "infinity_progress", 1.0, 1.7)

	await t.finished


func _draw_partial(points: PackedVector2Array, progress: float, col: Color, width: float):

	if points.size() < 2:
		return

	var count := int(points.size() * progress)
	count = maxi(2, count)

	var slice := points.slice(0, count)

	# 🌊 instability fades out as progress increases
	var instability := (1.0 - progress) * 6.0

	var jittered := PackedVector2Array()

	for p in slice:
		jittered.append(_jitter(p, instability))

	draw_polyline(jittered, col, width, true)


func _draw_x(col: Color, width: float):

	if x_progress <= 0.0:
		return

	var instability := (1.0 - x_progress) * 12.0
	instability += sin(time * 20.0) * 2.0 * (1.0 - x_progress)
	
	var a := _jitter(center + Vector2(-25, -25), instability)
	var b := _jitter(center + Vector2(25, 25), instability)

	var c := _jitter(center + Vector2(25, -25), instability)
	var d := _jitter(center + Vector2(-25, 25), instability)

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
