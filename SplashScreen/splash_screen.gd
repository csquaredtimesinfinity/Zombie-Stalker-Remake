extends Control

func _ready():
	print("splash running")
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2(0, 0), size), Color(0, 0, 0.2))
	draw_circle(Vector2(200, 200), 50, Color.RED)
	draw_string(ThemeDB.fallback_font, Vector2(50, 50), "TEST")
