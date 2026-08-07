@tool
class_name FrameThumb
extends TextureRect

## A single filmstrip cell: a clickable thumbnail, its frame number, and a
## selection ring. Drawn in one _draw() pass (no per-frame child widgets) so a
## long timeline stays cheap to render.

signal pressed

var frame_index: int = 0:
	set(value):
		frame_index = value
		queue_redraw()

var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()


func _ready() -> void:
	# Crisp pixel-art thumbnails, never filtered.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		pressed.emit()
		accept_event()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if texture != null:
		draw_texture_rect(texture, r, false)
	else:
		draw_rect(r, Color(0.18, 0.18, 0.18, 1.0), true)

	# Selection ring vs idle border — the only per-cell state we render.
	# draw_rect() centres the outline on the rect's edges, so a rect that
	# starts at (0,0) pushes the top/left half of the line outside the control
	# (it then gets clipped and renders faint/missing). Inset by half the line
	# width so the whole outline stays inside the thumbnail on every side.
	var border_color := Color(0.0, 0.0, 0.0, 0.5)
	var border_width := 1.0
	if selected:
		border_color = Color(0.35, 0.62, 1.0, 1.0)
		border_width = 2.0
	var half := border_width * 0.5
	var border := Rect2(half, half, size.x - border_width, size.y - border_width)
	draw_rect(border, border_color, false, border_width)

	# Frame number with a readable backing, bottom-left.
	var num := str(frame_index + 1)
	var font := get_theme_default_font()
	var fs := maxi(int(get_theme_default_font_size()), 11)
	var text_w := font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bg := Rect2(2, size.y - fs - 5, text_w + 6, fs + 4)
	draw_rect(bg, Color(0.0, 0.0, 0.0, 0.6), true)
	draw_string(font, Vector2(5, size.y - 5), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
