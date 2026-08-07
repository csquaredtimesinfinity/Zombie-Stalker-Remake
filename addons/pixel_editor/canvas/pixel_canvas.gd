@tool
class_name PixelCanvas
extends Control

## View of an ImageDocument. Owns zoom/pan state and mouse->pixel mapping.
## Drawing is delegated to Renderer; input dispatch arrives via InputController.

var input_controller: InputController
# True once the user zooms manually; suppresses auto re-fit on resize.
var _user_zoomed: bool = false

const _MinZoom := 0.25
const _MaxZoom := 64.0
const _ZoomStep := 1.25
const _FitZoomCeil := 16.0  # cap auto-fit so tiny images aren't blown up huge

var document: ImageDocument:
	set(value):
		if document != null and document.changed.is_connected(queue_redraw):
			document.changed.disconnect(queue_redraw)
		document = value
		if document != null:
			document.changed.connect(queue_redraw)
		_user_zoomed = false
		fit_to_window()
		queue_redraw()

# Emitted whenever the zoom level changes (toolbar buttons, wheel, fit, resize).
# The dock listens to keep the on-screen zoom percentage label in sync.
signal zoom_changed

var zoom: float = 1.0:
	set(value):
		var clamped := clampf(value, _MinZoom, _MaxZoom)
		if is_equal_approx(clamped, zoom):
			return
		zoom = clamped
		queue_redraw()
		zoom_changed.emit()

var pan_offset: Vector2 = Vector2.ZERO
var show_grid: bool = true:
	set(value):
		show_grid = value
		queue_redraw()

# Mirror painting: strokes also place dabs at the mirrored positions across
# the enabled axes. Both default off; the dock toggles them via the toolbar.
var mirror_h: bool = false:
	set(value):
		mirror_h = value
		queue_redraw()
var mirror_v: bool = false:
	set(value):
		mirror_v = value
		queue_redraw()


# Onion skinning: show neighbouring frames faded behind the active one.
var onion_skin_enabled: bool = false:
	set(value):
		onion_skin_enabled = value
		queue_redraw()
var onion_skin_depth: int = 1  # how many frames before/after to ghost
const _OnionPrevTint := Color(1.0, 0.45, 0.35, 1.0)  # previous frames -> warm
const _OnionNextTint := Color(0.35, 0.6, 1.0, 1.0)   # next frames -> cool
const _OnionBaseAlpha := 0.4

# Custom cursor indicator. The OS mouse cursor is hidden while over the
# artboard and a crosshair + pixel-cell outline is drawn instead, so the user
# sees exactly where the mouse is and which pixel a click will touch. One
# shared outline colour is used for every tool (current and future).
const _CursorOutlineColor := Color(1.0, 1.0, 1.0, 0.95)  # outline / crosshair
const _CursorCrossColor := Color(0.0, 0.0, 0.0, 0.6)     # dark contrast pass

# Last hovered screen position. The indicator is redrawn from this on every
# queue_redraw; we queue a redraw on motion so the indicator tracks the mouse.
var _cursor_pos: Vector2 = Vector2.ZERO
var _cursor_inside: bool = false


func _ready() -> void:
	# Nearest-neighbour filtering => crisp pixels, no bilinear blur.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Keep drawing inside the canvas rect when zoomed/panned beyond bounds.
	clip_contents = true
	# Re-fit when the panel resizes so the artboard stays nicely framed.
	resized.connect(_on_resized)
	# Cursor hide/show is driven from motion against the actual artboard rect
	# (compute_view_rect), not Control enter/exit, because the Control fills the
	# whole panel while the image only occupies the inner view rect.
	mouse_exited.connect(_on_cursor_left_panel)


func _on_resized() -> void:
	if document == null:
		return
	# Auto re-fit unless the user has zoomed manually; otherwise keep the
	# artboard on screen by re-clamping the existing pan to the new size.
	if _user_zoomed:
		_clamp_pan()
		queue_redraw()
	else:
		fit_to_window()


func _gui_input(event: InputEvent) -> void:
	_handle_navigation(event)
	# Track the pointer for the custom cursor indicator. We record the screen
	# position and redraw even when no stroke is active so the cell highlight
	# follows the mouse across the artboard. The OS cursor is hidden ONLY while
	# the pointer is over the actual artboard rect (the image), not the whole
	# panel — the panel has margins around the image where the normal pointer
	# should stay visible.
	if event is InputEventMouseMotion:
		_cursor_pos = event.position
		_update_cursor_visibility()
		queue_redraw()
	if input_controller != null:
		input_controller.handle_gui_input(event, self)


## Toggles the OS cursor based on whether the pointer is over the artboard rect.
## Hide + show our indicator while on the image; restore the default pointer in
## the panel margins. Idempotent: only touches DisplayServer on a real change.
func _update_cursor_visibility() -> void:
	if document == null:
		_set_cursor_inside(false)
		return
	var over := compute_view_rect().has_point(_cursor_pos)
	_set_cursor_inside(over)


func _set_cursor_inside(inside: bool) -> void:
	if inside == _cursor_inside:
		return
	_cursor_inside = inside
	if inside:
		DisplayServer.cursor_set_custom_image(_get_blank_cursor(), DisplayServer.CURSOR_ARROW)
	else:
		# Restore the platform default cursor when leaving the artboard.
		DisplayServer.cursor_set_custom_image(null, DisplayServer.CURSOR_ARROW)
	queue_redraw()


## Called when the pointer leaves the Control entirely (the whole panel). Makes
## sure the OS cursor is restored even if the artboard-hover state wasn't
## updated by a final motion event.
func _on_cursor_left_panel() -> void:
	_set_cursor_inside(false)


## View navigation. Kept separate from tool dispatch because pan/zoom are
## view concerns, not editing concerns.
func _handle_navigation(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_wheel(event)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pan_offset += event.relative
			_clamp_pan()
			queue_redraw()


func _handle_wheel(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		zoom_at(event.position, _ZoomStep)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		zoom_at(event.position, 1.0 / _ZoomStep)


## Zoom while keeping `focus` (screen coords) over the same pixel.
##
## When the cursor isn't over the artboard we zoom toward the panel centre
## instead — otherwise an anchor out in empty space flings the image off-screen
## and it becomes invisible. The resulting pan is clamped so the artboard can
## never leave the viewport entirely.
func zoom_at(anchor: Vector2, factor: float) -> void:
	if document == null:
		return
	var prev := compute_view_rect()
	# Only anchor to the cursor while it's actually over the artboard.
	var focus := anchor if prev.has_point(anchor) else size * 0.5
	var new_zoom := clampf(zoom * factor, _MinZoom, _MaxZoom)
	if is_equal_approx(new_zoom, zoom):
		return
	# Focus pixel in screen space relative to view origin before zoom.
	var rel := focus - prev.position
	var ratio := rel / prev.size
	_user_zoomed = true
	zoom = new_zoom
	var next := compute_view_rect()
	pan_offset += focus - next.position - ratio * next.size
	_clamp_pan()
	queue_redraw()


## Bounds `pan_offset` so the artboard always overlaps the viewport. The image
## may be pushed flush to any edge (so every part is reachable when zoomed in)
## but can never disappear entirely. No-op without a document.
func _clamp_pan() -> void:
	if document == null:
		return
	var img := Vector2(document.get_size()) * zoom
	# Half the slack between panel and scaled image, per axis. abs() keeps the
	# bound symmetric and valid whether the image is smaller or larger than
	# the panel.
	var limit := (size - img).abs() * 0.5
	pan_offset.x = clampf(pan_offset.x, -limit.x, limit.x)
	pan_offset.y = clampf(pan_offset.y, -limit.y, limit.y)


func _draw() -> void:
	Renderer.draw(
		self,
		document,
		compute_view_rect(),
		show_grid,
		zoom,
		Rect2(Vector2.ZERO, size),
		_build_onion_ghosts(),
		mirror_h,
		mirror_v
	)
	_draw_cursor()


# Cached 1x1 fully-transparent texture used as the hidden cursor image.
static var _blank_cursor: ImageTexture


static func _get_blank_cursor() -> ImageTexture:
	if _blank_cursor == null:
		var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		_blank_cursor = ImageTexture.create_from_image(img)
	return _blank_cursor


const _CursorCrossLen := 6.0  # half-length of each crosshair arm, in px
const _CursorCrossGap := 2.0  # gap around the exact mouse point


## Draws the cursor indicator. Two parts:
##  - A crosshair at the precise floating mouse position, so the cursor tracks
##    the mouse smoothly with no "magnetic" snap feel.
##  - A thin outline on the target pixel cell (shows exactly which pixel a click
##    will touch).
## Both use the single shared _CursorOutlineColor so every tool (current and
## future) reads identically. Nothing is drawn when the pointer is outside the
## artboard or no document is loaded.
func _draw_cursor() -> void:
	if not _cursor_inside or document == null:
		return
	var view := compute_view_rect()
	if not view.has_point(_cursor_pos):
		return
	# Crosshair at the EXACT mouse position (smooth tracking, no cell snap).
	_draw_crosshair(_cursor_pos)
	# Thin outline on the target pixel cell (shows the pixel a click will paint).
	var step := view.size / Vector2(document.get_size())
	var cell := Rect2(
		Vector2(
			view.position.x + floor((_cursor_pos.x - view.position.x) / step.x) * step.x,
			view.position.y + floor((_cursor_pos.y - view.position.y) / step.y) * step.y
		),
		step
	)
	# Outer dark then inner colour outline for contrast over light/dark art.
	draw_rect(cell.grow(1.0), _CursorCrossColor, false, 1.0)
	draw_rect(cell, _CursorOutlineColor, false, 1.0)


## Draws a plus-shaped crosshair centred on `pos`. A small gap around the centre
## keeps the exact mouse point visible, and a dark pass under the colour pass
## gives contrast on any artwork.
func _draw_crosshair(pos: Vector2) -> void:
	var arms := [
		# Left, right, up, down arms (from gap edge to arm end).
		Vector2(pos.x - _CursorCrossGap - _CursorCrossLen, pos.y),
		Vector2(pos.x + _CursorCrossGap + _CursorCrossLen, pos.y),
		Vector2(pos.x, pos.y - _CursorCrossGap - _CursorCrossLen),
		Vector2(pos.x, pos.y + _CursorCrossGap + _CursorCrossLen),
	]
	# Dark outline pass for contrast, then the colour pass.
	for a in arms:
		draw_line(pos.direction_to(a) * _CursorCrossGap + pos, a, _CursorCrossColor, 1.0)
	for i in range(0, arms.size(), 2):
		draw_line(arms[i], arms[i + 1], _CursorOutlineColor, 1.0)


## Collects faded neighbouring-frame textures for onion skinning. Returns [] when
## disabled or the document has a single frame, so the renderer's hot path is
## untouched for still images.
func _build_onion_ghosts() -> Array:
	if not onion_skin_enabled or document == null or document.get_frame_count() < 2:
		return []
	var cur := document.get_current_index()
	var ghosts: Array = []
	for d in range(1, onion_skin_depth + 1):
		# Alpha falls off with distance so nearer frames read more strongly.
		var alpha := _OnionBaseAlpha / float(d)
		if cur - d >= 0:
			ghosts.append({
				"texture": document.frames[cur - d].texture,
				"modulate": _OnionPrevTint * Color(1, 1, 1, alpha),
			})
		if cur + d < document.get_frame_count():
			ghosts.append({
				"texture": document.frames[cur + d].texture,
				"modulate": _OnionNextTint * Color(1, 1, 1, alpha),
			})
	return ghosts


## Returns the on-screen rect where the image is rendered.
func compute_view_rect() -> Rect2:
	if document == null:
		return Rect2(Vector2.ZERO, size)
	var img_size := Vector2(document.get_size())
	var scaled := img_size * zoom
	return Rect2(pan_offset + (size - scaled) * 0.5, scaled)


# Result of screen_to_pixel. Reused across calls for zero allocation; callers
# must consume it synchronously before invoking screen_to_pixel again.
class PixelHit:
	var pixel: Vector2i
	var valid: bool


var _hit := PixelHit.new()


## Converts a screen position to image pixel coordinates. `valid` false if out
## of bounds or no document is loaded. Returns a reused PixelHit (see class).
func screen_to_pixel(screen_pos: Vector2) -> PixelHit:
	_hit.valid = false
	if document == null:
		return _hit
	var view := compute_view_rect()
	if not view.has_point(screen_pos):
		return _hit
	var local := (screen_pos - view.position) / view.size
	var px := Vector2i(floori(local.x * document.get_size().x), floori(local.y * document.get_size().y))
	_hit.pixel = px
	_hit.valid = true
	return _hit


func fit_to_window() -> void:
	if document == null:
		return
	var img_size := Vector2(document.get_size())
	if img_size == Vector2.ZERO or size == Vector2.ZERO:
		return
	# Use ~85% of the smaller axis so the artboard sits comfortably, capped.
	var fit := minf(size.x / img_size.x, size.y / img_size.y) * 0.85
	fit = minf(fit, _FitZoomCeil)
	_user_zoomed = false  # re-enable auto re-fit on resize
	zoom = fit
	pan_offset = Vector2.ZERO


func zoom_in() -> void:
	# Toolbar buttons have no cursor position, so zoom toward the panel centre.
	zoom_at(size * 0.5, _ZoomStep)


func zoom_out() -> void:
	zoom_at(size * 0.5, 1.0 / _ZoomStep)
