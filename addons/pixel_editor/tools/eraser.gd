@tool
class_name EraserTool
extends Tool

## Clears pixels to fully transparent. Reuses Tool's stroke interpolation.

func begin_stroke(ctx: ToolContext, pixel: Vector2i) -> void:
	_apply_with_mirror(ctx, pixel)


func _apply_one(ctx: ToolContext, pixel: Vector2i) -> void:
	if not _in_bounds(ctx, pixel):
		return
	ctx.document.set_pixel(pixel.x, pixel.y, Color(0, 0, 0, 0))
