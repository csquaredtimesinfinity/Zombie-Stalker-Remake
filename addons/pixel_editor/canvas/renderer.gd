@tool
class_name Renderer

## Stateless canvas painter. Decoupled from PixelCanvas so the draw pipeline
## can be reused (e.g. preview overlays) and unit-tested in isolation.
##
## The checkerboard is baked once into a tiny tiling texture; the grid is culled
## to the visible region — both keep per-frame draw-call counts low.

const _CheckerColors := [Color(0.78, 0.78, 0.78, 1.0), Color(0.62, 0.62, 0.62, 1.0)]
const _CheckerTileSize := 12
const _GridColor := Color(0.0, 0.0, 0.0, 0.35)
const _OutlineColor := Color(0.1, 0.1, 0.1, 1.0)
# Mirror axis guidelines: drawn halfway across each enabled axis. Bright cyan so
# they read over both the checkerboard and dark art.
const _MirrorColor := Color(0.35, 0.8, 1.0, 0.9)
const _MirrorWidth := 2.0
const _MirrorDash := 6.0  # dash length; 0 = solid

# Generated once and reused for the life of the editor session.
static var _checker_tex: ImageTexture


## Draws the full scene: checkerboard, image, optional pixel grid, outline.
## `view` is the on-screen rect where the image is drawn (already includes
## zoom/pan). `visible_rect` is the control's clip rect, used to cull the grid.
## `show_grid` only draws when zoom makes grid readable.
## `onion_ghosts` are neighbouring-frame textures drawn faded BEHIND the active
## frame (each entry: { "texture": Texture2D, "modulate": Color }) for onion
## skinning. Kept as a plain Array so the no-animation case passes nothing.
## `mirror_h`/`mirror_v` draw a dashed guideline on each enabled mirror axis so
## the user can see where mirrored dabs will land while painting.
static func draw(
	canvas: CanvasItem,
	document: ImageDocument,
	view: Rect2,
	show_grid: bool,
	zoom: float,
	visible_rect: Rect2,
	onion_ghosts: Array = [],
	mirror_h: bool = false,
	mirror_v: bool = false
) -> void:
	_draw_checkerboard(canvas, view)
	if document == null:
		return
	# Ghosts first so the active frame always paints on top.
	for ghost in onion_ghosts:
		canvas.draw_texture_rect(ghost["texture"], view, false, ghost["modulate"])
	# Guard against a transiently-null active texture (mid document swap, or a
	# corrupt undo restoring zero frames) so it can't raise "rp_texture is null".
	if document.texture != null:
		canvas.draw_texture_rect(document.texture, view, false)
	if show_grid and zoom >= 8.0:
		_draw_grid(canvas, view, document.get_size(), visible_rect)
	if mirror_h or mirror_v:
		_draw_mirror(canvas, view, document.get_size(), mirror_h, mirror_v)
	_draw_outline(canvas, view)


static func _draw_checkerboard(canvas: CanvasItem, view: Rect2) -> void:
	# One tiled blit instead of hundreds of per-cell draw_rect() calls.
	canvas.draw_texture_rect(_get_checker_texture(), view, true)


static func _get_checker_texture() -> ImageTexture:
	if _checker_tex == null:
		var t := _CheckerTileSize
		var img := Image.create(t * 2, t * 2, false, Image.FORMAT_RGBA8)
		img.fill(_CheckerColors[0])
		img.fill_rect(Rect2i(t, 0, t, t), _CheckerColors[1])
		img.fill_rect(Rect2i(0, t, t, t), _CheckerColors[1])
		_checker_tex = ImageTexture.create_from_image(img)
	return _checker_tex


static func _draw_grid(canvas: CanvasItem, view: Rect2, image_size: Vector2i, visible_rect: Rect2) -> void:
	var step := view.size / Vector2(image_size)
	# Only draw columns/rows that intersect the visible clip rect.
	var col0 := maxf(0.0, (visible_rect.position.x - view.position.x) / step.x)
	var col1 := minf(float(image_size.x), (visible_rect.end.x - view.position.x) / step.x)
	var ci0 := maxi(int(floor(col0)), 0)
	var ci1 := mini(ceili(col1), image_size.x)
	for x in range(ci0, ci1 + 1):
		var px := view.position.x + x * step.x
		canvas.draw_line(Vector2(px, view.position.y), Vector2(px, view.end.y), _GridColor)

	var row0 := maxf(0.0, (visible_rect.position.y - view.position.y) / step.y)
	var row1 := minf(float(image_size.y), (visible_rect.end.y - view.position.y) / step.y)
	var ri0 := maxi(int(floor(row0)), 0)
	var ri1 := mini(ceili(row1), image_size.y)
	for y in range(ri0, ri1 + 1):
		var py := view.position.y + y * step.y
		canvas.draw_line(Vector2(view.position.x, py), Vector2(view.end.x, py), _GridColor)


# Mirror axis guidelines. We use the view's half-width/half-height in screen
# space — zoom-correct and visually consistent for any image size.
static func _draw_mirror(canvas: CanvasItem, view: Rect2, image_size: Vector2i, mirror_h: bool, mirror_v: bool) -> void:
	if mirror_h:
		var mid_x := view.position.x + view.size.x * 0.5
		_draw_dashed_line(canvas, Vector2(mid_x, view.position.y), Vector2(mid_x, view.end.y))
	if mirror_v:
		var mid_y := view.position.y + view.size.y * 0.5
		_draw_dashed_line(canvas, Vector2(view.position.x, mid_y), Vector2(view.end.x, mid_y))


# Dashed line helper. Uniform dashes/gaps of _MirrorDash length so the axis
# reads as a guide, not a drawn pixel.
static func _draw_dashed_line(canvas: CanvasItem, from: Vector2, to: Vector2) -> void:
	var vec := to - from
	var length := vec.length()
	if length <= 0.0:
		return
	if _MirrorDash <= 0.0:
		canvas.draw_line(from, to, _MirrorColor, _MirrorWidth)
		return
	var dir := vec / length
	var step := _MirrorDash * 2.0
	var travelled := 0.0
	while travelled < length:
		var a := from + dir * travelled
		var b := from + dir * minf(travelled + _MirrorDash, length)
		canvas.draw_line(a, b, _MirrorColor, _MirrorWidth)
		travelled += step


static func _draw_outline(canvas: CanvasItem, view: Rect2) -> void:
	canvas.draw_rect(view, _OutlineColor, false, 1.0)
