@tool
class_name Tool

## Base class for all editing tools.
##
## Subclasses override begin/end stroke and _apply. Stroke interpolation runs
## Bresenham inline (no per-event Array allocation) and applies each point.

class ToolContext:
	var document: ImageDocument
	var canvas: PixelCanvas
	var color: Color
	# Mirror axes active for the current stroke. Tools consult these via
	# Tool._apply_with_mirror so a single dab fans out to every mirrored copy.
	var mirror_h: bool = false
	var mirror_v: bool = false


# Whether this tool mutates the image and therefore needs an undo session.
# A read-only tool would override to false so clicks don't pollute history
# with empty actions.
func is_editing() -> bool:
	return true


# Virtuals — default no-ops so optional hooks stay optional.
func begin_stroke(_ctx: ToolContext, _pixel: Vector2i) -> void:
	pass


func continue_stroke(ctx: ToolContext, from: Vector2i, to: Vector2i) -> void:
	# Bresenham line, applied point-by-point without allocating an Array.
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		_apply_with_mirror(ctx, Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func end_stroke(_ctx: ToolContext) -> void:
	pass


# Per-pixel application — overridden by concrete tools.
func _apply(_ctx: ToolContext, _pixel: Vector2i) -> void:
	pass


# Shared bounds guard so concrete tools don't each reimplement it.
func _in_bounds(ctx: ToolContext, pixel: Vector2i) -> bool:
	var s := ctx.document.get_size()
	return pixel.x >= 0 and pixel.y >= 0 and pixel.x < s.x and pixel.y < s.y


# Applies a single dab to the original pixel and every mirrored copy selected by
# the active mirror axes. Delegates the actual pixel write back to the concrete
# tool via _apply_one, so pencil/eraser/fill all share one fan-out path.
#
# Mirror math: across a W-wide image the horizontal reflection of x is W-1-x
# (same for vertical, h-1-y). With both axes on we get the original, the
# horizontal flip, the vertical flip and the point reflection — up to 4 dabs.
func _apply_with_mirror(ctx: ToolContext, pixel: Vector2i) -> void:
	if not ctx.mirror_h and not ctx.mirror_v:
		_apply_one(ctx, pixel)
		return
	var s := ctx.document.get_size()
	var mx := s.x - 1 - pixel.x
	var my := s.y - 1 - pixel.y
	_apply_one(ctx, pixel)
	if ctx.mirror_h:
		_apply_one(ctx, Vector2i(mx, pixel.y))
	if ctx.mirror_v:
		_apply_one(ctx, Vector2i(pixel.x, my))
	if ctx.mirror_h and ctx.mirror_v:
		_apply_one(ctx, Vector2i(mx, my))


# Concrete tools override THIS instead of _apply when they want mirroring.
# _apply is kept as the legacy no-op hook for tools that don't opt in.
func _apply_one(_ctx: ToolContext, _pixel: Vector2i) -> void:
	pass
