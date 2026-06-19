extends Node2D

func _ready():
	print("NODE2D SPLASH RUNNING")
	queue_redraw()

func _draw():
	draw_rect(Rect2(-500, -500, 2000, 2000), Color(0, 0, 0.2), true)
	draw_circle(Vector2(0, 0), 50, Color.RED)
	draw_string(ThemeDB.fallback_font, Vector2(50, 50), "HELLO", HORIZONTAL_ALIGNMENT_LEFT)
