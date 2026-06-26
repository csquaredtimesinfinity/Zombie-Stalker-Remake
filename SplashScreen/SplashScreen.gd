extends Node2D

const GLITCH_STRIPE_HEIGHT := 400

@onready var fade_rect: ColorRect = $/root/SceneTransition/ColorRect

var c1_points: PackedVector2Array
var c2_points: PackedVector2Array
var infinity_points: PackedVector2Array

var c1_progress := 0.0
var c2_progress := 0.0
var x_progress := 0.0
var infinity_progress := 0.0

var center := Vector2.ZERO

var time := 0.0

var can_skip := false
var skipped := false

func _ready():
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center = get_viewport_rect().size / 2.0

	_build_geometry()
	get_tree().create_timer(1.0).timeout.connect(
		func(): can_skip = true)
	
	await _play_animation()
	
	if skipped:
		return

	await get_tree().create_timer(1.8).timeout
	
	if skipped:
		return
	
	await GameManager.change_scene_to_main_menu()

	
func _unhandled_input(event: InputEvent) -> void:
	if not can_skip:
		return
		
	if skipped:
		return
		
	if event.is_pressed():
		_skip_intro()

func _skip_intro() -> void:
	if skipped:
		return
		
	skipped = true
	
	await GameManager.change_scene_to_main_menu()
	

func _get_glitch_strength() -> float:
	
	# early chaos (strong while C’s are forming)
	var early : float = 1.0 - max(c1_progress, c2_progress)

	# mid chaos (drops when X appears)
	var mid := 1.0 - x_progress

	# final stabilization (kills glitch during infinity draw)
	var final := 1.0 - infinity_progress

	# weighted behavior:
	var strength := early * 1.2 + mid * 0.6 + final * 2.5

	return clamp(strength, 0.0, 3.0)

func _build_geometry():

	c1_points = _build_c(center + Vector2(-80, 0), 90)
	c2_points = _build_c(center + Vector2(20, 0), 65)

	infinity_points = _build_infinity(center + Vector2(200, 0), 70, 40)


func _process(delta):
	time += delta
	queue_redraw()

func _jitter(p: Vector2, intensity: float) -> Vector2:
	var t := time * 2.0

	# layered noise (gives "machine struggling to stabilize" feel)
	var n1 := sin(p.x * 0.08 + t) * cos(p.y * 0.06 - t * 1.3)
	var n2 := sin((p.x + p.y) * 0.05 + t * 1.7)

	var n := (n1 + n2 * 0.5)

	# directional instability (bias makes it feel less random)
	var dir := Vector2(1.0, 0.35).normalized()

	return p + dir * n * intensity

func _glitch_color(y: float, base: Color, strength: float) -> Color:
	var t := time * 25.0

	# pseudo-random per scanline
	var n := sin(y * 0.15 + t) * cos(y * 0.07 - t * 0.8)

	# flicker amount
	var flicker := n * strength * 0.25

	# RGB channel drift (slightly desynced channels)
	var r := base.r + flicker
	var g := base.g + flicker * sin(t * 1.3)
	var b := base.b + flicker * cos(t * 1.7)

	return Color(r, g, b, base.a)

func _draw():

	var size := get_viewport_rect().size

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.03, 0.04), true)

	var base_glitch := 0.25
	var startup_glitch : float = (1.0 - max(c1_progress, infinity_progress)) * 1.5

	var glitch_strength : float = clamp(_get_glitch_strength(), 0.0, 0.25)

	for y in range(0, int(size.y), GLITCH_STRIPE_HEIGHT):

		# horizontal offset (your existing glitch idea)
		var n := sin(y * 0.1 + time * 20.0)
		var offset_x := n * glitch_strength * 10.0

		# color flicker per line
		var base_col := _glitch_color(y, Color(1, 1, 1), glitch_strength)

		draw_set_transform(Vector2(offset_x, 0))

		_draw_logo(y, base_col)

		draw_set_transform(Vector2.ZERO)

	# final text stays stable (contrast moment)
	if infinity_progress >= 1.0:
		glitch_strength = _get_glitch_strength()

	if infinity_progress >= 1.0:
		glitch_strength = 0.0
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(-90, 140),
			"C² × ∞",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			32,
			Color.WHITE
		)
	
	if can_skip:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(
				20,
				get_viewport_rect().size.y - 20
			),
			"Press Any Key To Skip",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			16,
			Color(1,1,1,0.5))
		

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

func _draw_logo(offset_y: float = 0.0, color_mod: Color = Color.WHITE):
	var base := Color(0.75, 0.95, 1.0) * color_mod

	_draw_partial(c1_points, c1_progress, base, 4.0)
	_draw_partial(c2_points, c2_progress, base, 4.0)
	_draw_x(base, 4.0)
	_draw_partial(infinity_points, infinity_progress, base, 4.0)

func _build_infinity(pos: Vector2, w: float, h: float) -> PackedVector2Array:

	var pts := PackedVector2Array()

	for deg in range(0, 720, 4):
		var t := deg_to_rad(deg)
		pts.append(pos + Vector2(w * sin(t), h * sin(t) * cos(t)))

	return pts
