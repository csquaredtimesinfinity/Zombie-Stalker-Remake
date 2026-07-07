extends Node2D

var hovered_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	z_index = 100

func _process(_delta):
	var mouse_pos = get_local_mouse_position()
	hovered_cell = Vector2i(
		floor(mouse_pos.x / 64),
		floor(mouse_pos.y / 64)
	)

	queue_redraw()

func _draw():
	if hovered_cell.x >= 0 and hovered_cell.y >= 0:
		draw_rect(
			Rect2(
				hovered_cell * 64,
				Vector2(64, 64)
		),
		Color.WHITE,
		false,
		2.0
	)
