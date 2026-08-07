@tool
class_name FillTool
extends Tool

## Flood-fill: replaces a contiguous region of one colour with the brush colour.
##
## The whole fill runs on the initial click (begin_stroke); drags are ignored so
## the user can't accidentally re-fill while sweeping the mouse. Uses an
## iterative scanline fill (no recursion) so large images can't blow the call
## stack, and seeds at most one entry per contiguous run instead of four naive
## neighbours per pixel — keeping stack churn ~constant instead of ~4x the fill
## area. Pixel writes still go through ImageDocument.set_pixel so the dirty-rect
## undo tracker records every touched pixel.
##
## Termination safety: the scanline walk consults a per-fill "processed" byte
## mask, NOT the live Image, for its "still in region?" decisions. With mirror
## active begin_stroke runs up to four _fill calls over the SAME Image, and a
## later call would otherwise re-seed rows an earlier call already wrote — an
## unbounded loop that froze Godot. The mask guarantees each pixel is filled and
## seeded at most once across the whole mirror fan-out.

func begin_stroke(ctx: ToolContext, pixel: Vector2i) -> void:
	# Fan the flood fill out to every mirrored copy of the click position. Each
	# seed fills its own region against the colour that region held at click
	# time, so a symmetric image produces symmetric fills even when regions are
	# not contiguous across the mirror axis.
	_fill(ctx, pixel)
	if ctx.mirror_h or ctx.mirror_v:
		var s := ctx.document.get_size()
		var mx := s.x - 1 - pixel.x
		var my := s.y - 1 - pixel.y
		if ctx.mirror_h:
			_fill(ctx, Vector2i(mx, pixel.y))
		if ctx.mirror_v:
			_fill(ctx, Vector2i(pixel.x, my))
		if ctx.mirror_h and ctx.mirror_v:
			_fill(ctx, Vector2i(mx, my))


func continue_stroke(_ctx: ToolContext, _from: Vector2i, _to: Vector2i) -> void:
	pass  # Single-shot: ignore drags.


# Scanline flood fill. Tracks the region's original colour and only overwrites
# pixels matching it, so filled pixels (now the brush colour) are never revisited.
func _fill(ctx: ToolContext, start: Vector2i) -> void:
	if not _in_bounds(ctx, start):
		return
	var img := ctx.document.image
	var target := img.get_pixel(start.x, start.y)
	var fill := ctx.color
	if target.is_equal_approx(fill):
		return
	var size := ctx.document.get_size()
	var w := size.x
	var h := size.y
	# Per-fill "processed" mask, consulted INSTEAD of the live Image for the
	# "is this pixel still part of the region?" decisions. The scanline walk used
	# to read the Image directly, but the walk itself mutates that same Image via
	# set_pixel — and with mirror enabled, begin_stroke fans out up to FOUR _fill
	# calls over the SAME Image. A later call could re-seed rows an earlier call
	# had already filled (now the fill colour, no longer matching target), and a
	# stale seed would then be popped, walked, find nothing to do, yet still be
	# re-pushed from neighbouring runs — an infinite loop that froze the editor.
	# The stable mask breaks the cycle: once a pixel is marked it is never
	# reprocessed or reseeded, by any fill in the mirror fan-out.
	var done := PackedByteArray()
	done.resize(w * h)
	# One stack entry per scanline run to try (not per pixel), so the stack grows
	# with the fill's perimeter rather than ~4x its area.
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var seed: Vector2i = stack.pop_back()
		var y := seed.y
		if y < 0 or y >= h:
			continue
		# A seed whose pixel was already processed carries no work. Without this
		# guard a stale seed walks, fills nothing, but the outer loop had no
		# progress signal — the hang.
		if _is_done(done, seed.x, y, w):
			continue
		# Walk left to the first pixel of this run that still matches target.
		var x := seed.x
		while x >= 0 and _matches(img, x, y, target) and not _is_done(done, x, y, w):
			x -= 1
		x += 1
		var span_up := false
		var span_down := false
		# Fill rightward across the contiguous run, seeding the rows above/below
		# once per run (via the span_up/span_down flip-flops) instead of per pixel.
		while x < w and _matches(img, x, y, target) and not _is_done(done, x, y, w):
			ctx.document.set_pixel(x, y, fill)
			_mark_done(done, x, y, w)
			if y > 0:
				var up := _matches(img, x, y - 1, target) and not _is_done(done, x, y - 1, w)
				if up and not span_up:
					stack.push_back(Vector2i(x, y - 1))
				span_up = up
			if y < h - 1:
				var down := _matches(img, x, y + 1, target) and not _is_done(done, x, y + 1, w)
				if down and not span_down:
					stack.push_back(Vector2i(x, y + 1))
				span_down = down
			x += 1


func _matches(img: Image, x: int, y: int, target: Color) -> bool:
	return img.get_pixel(x, y).is_equal_approx(target)


func _is_done(done: PackedByteArray, x: int, y: int, w: int) -> bool:
	return done[y * w + x] != 0


func _mark_done(done: PackedByteArray, x: int, y: int, w: int) -> void:
	done[y * w + x] = 1
