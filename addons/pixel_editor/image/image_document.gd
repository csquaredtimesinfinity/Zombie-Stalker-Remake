@tool
class_name ImageDocument

## Frame-based editable image. Holds 1..N frames of identical dimensions.
##
## `image` and `texture` always ALIAS the active frame, so the canvas, renderer,
## input controller and undo pipeline operate on the visible frame with zero
## special-casing — switching frames just re-points the aliases.
##
## Writes during a stroke are buffered in the active frame's `image` and flushed
## to the GPU at most once per input event (see flush()) instead of once per
## pixel — a hard requirement for smooth 512x512 painting.

signal changed           # active-frame pixels flushed OR active frame switched
signal frame_changed     # active frame index changed
signal structure_changed # frames added / removed / reordered

const DEFAULT_FRAME_DURATION := 0.1  # seconds; overridden by the timeline FPS

## Lightweight frame: editable Image + its live GPU mirror + display duration.
class Frame:
	var image: Image
	var texture: ImageTexture
	var duration: float = DEFAULT_FRAME_DURATION


# Untyped on purpose: Array[InnerClass] can mis-resolve across @tool reloads.
var frames: Array = []   # Array[Frame]
var file_path: String = ""
var fps: float = 12.0

var _current: int = 0
var _dirty: bool = false
# Bounding rect of every pixel written while _track_dirty is on. Grown by
# set_pixel and consumed by UndoManager.commit_stroke so undo can snapshot ONLY
# the touched region instead of a full-image copy (history memory then scales
# with stroke footprint, not canvas size).
var _track_dirty: bool = false
var _dirty_rect: Rect2i = Rect2i()

# Active-frame aliases, kept in sync by _refresh_active().
var image: Image
var texture: ImageTexture


func _init(img: Image = null) -> void:
	if img != null:
		# Pixel-art sources are viewed upscaled, never minified => no mipmaps.
		if img.has_mipmaps():
			img.clear_mipmaps()
		add_frame_with_image(img, 0)


func get_size() -> Vector2i:
	var f := _active()
	if f != null:
		return Vector2i(f.image.get_width(), f.image.get_height())
	return Vector2i.ZERO


func get_frame_count() -> int:
	return frames.size()


func get_current_index() -> int:
	return _current


func _active() -> Frame:
	if frames.is_empty():
		return null
	return frames[clampi(_current, 0, frames.size() - 1)]


# ------------------------------------------------------------------ structure

## Inserts a frame built from `img`. `at_index` is clamped; out-of-range/-1 means
## "after the current frame". The new frame becomes active. Returns its index.
func add_frame_with_image(img: Image, at_index: int = -1) -> int:
	# Normalise the source: no mipmaps (pixel art is only ever viewed upscaled) and
	# a single RGBA8 format so the eraser's alpha, flood-fill and the byte-level
	# region undo all behave consistently no matter how the Image was produced.
	if img.has_mipmaps():
		img.clear_mipmaps()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	# Frames must share one dimension: the spritesheet export, onion skinning and
	# region undo all assume a uniform grid. A mismatched source (only reachable
	# via direct API use — the UI always creates same-size frames) is normalised
	# onto a canvas of the canonical size instead of silently corrupting the sheet.
	if not frames.is_empty():
		var canonical := Vector2i(frames[0].image.get_width(), frames[0].image.get_height())
		if Vector2i(img.get_width(), img.get_height()) != canonical:
			push_warning("PixelEditor: frame size %dx%d differs from %dx%d; resizing to fit" % [img.get_width(), img.get_height(), canonical.x, canonical.y])
			var canvas := Image.create(canonical.x, canonical.y, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(img, Rect2i(Vector2i.ZERO, Vector2i(img.get_width(), img.get_height())), Vector2i.ZERO)
			img = canvas
	var f := Frame.new()
	f.image = img
	f.texture = ImageTexture.create_from_image(img)
	var idx: int
	if at_index < 0 or at_index > frames.size():
		idx = clampi(_current + 1, 0, frames.size())
	else:
		idx = at_index
	frames.insert(idx, f)
	_current = idx
	_refresh_active()
	structure_changed.emit()
	frame_changed.emit()
	changed.emit()
	return idx


## Appends a transparent frame (same size as the active one) after it.
func add_blank_frame() -> int:
	var s := get_size()
	if s == Vector2i.ZERO:
		s = Vector2i(16, 16)
	var img := Image.create(s.x, s.y, false, Image.FORMAT_RGBA8)
	return add_frame_with_image(img, _current + 1)


## Duplicates the active frame (deep copy) and inserts it right after.
func duplicate_frame() -> int:
	var f := _active()
	if f == null:
		return _current
	return add_frame_with_image(f.image.duplicate(), _current + 1)


## Removes the active frame (keeps at least one). Selects the neighbour.
func delete_frame() -> void:
	if frames.size() <= 1:
		return
	frames.remove_at(_current)
	_current = clampi(_current, 0, frames.size() - 1)
	_refresh_active()
	structure_changed.emit()
	frame_changed.emit()
	changed.emit()


## Reorders a frame from -> to and makes it active.
func move_frame(from: int, to: int) -> void:
	if from < 0 or from >= frames.size():
		return
	if to < 0 or to >= frames.size() or from == to:
		return
	var f: Frame = frames[from]
	frames.remove_at(from)
	frames.insert(to, f)
	_current = to
	_refresh_active()
	structure_changed.emit()
	frame_changed.emit()
	changed.emit()


## Selects the active frame, flushing any pending writes on the outgoing frame.
func select_frame(index: int) -> void:
	if frames.is_empty():
		return
	var new_idx := clampi(index, 0, frames.size() - 1)
	if new_idx == _current and image != null:
		return
	if _dirty:
		flush()
	_current = new_idx
	_refresh_active()
	frame_changed.emit()
	changed.emit()


func _refresh_active() -> void:
	var f := _active()
	if f == null:
		image = null
		texture = null
		return
	image = f.image
	texture = f.texture
	_dirty = false


# ------------------------------------------------------------- pixel editing

## Buffers a single pixel write on the ACTIVE frame. Call flush() once the batch
## for the current event is complete.
func set_pixel(x: int, y: int, color: Color) -> void:
	image.set_pixel(x, y, color)
	_dirty = true
	if _track_dirty:
		_grow_dirty_rect(x, y)


## Starts recording the bounding rect of subsequent set_pixel writes. Paired
## with _end_dirty_tracking(); called by UndoManager at stroke begin.
func _begin_dirty_tracking() -> void:
	_track_dirty = true
	_dirty_rect = Rect2i()


## Stops recording and returns the accumulated bounding rect (empty if nothing
## was written). Called by UndoManager at stroke commit.
func _end_dirty_tracking() -> Rect2i:
	_track_dirty = false
	return _dirty_rect


func _grow_dirty_rect(x: int, y: int) -> void:
	if _dirty_rect.size == Vector2i.ZERO:
		_dirty_rect = Rect2i(x, y, 1, 1)
		return
	var x0 := mini(_dirty_rect.position.x, x)
	var y0 := mini(_dirty_rect.position.y, y)
	var x1 := maxi(_dirty_rect.position.x + _dirty_rect.size.x - 1, x)
	var y1 := maxi(_dirty_rect.position.y + _dirty_rect.size.y - 1, y)
	_dirty_rect = Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Pushes buffered writes to the GPU texture and notifies listeners. Cheap when
## nothing changed; coalesces with queue_redraw per frame.
func flush() -> void:
	if not _dirty:
		return
	texture.update(image)
	_dirty = false
	changed.emit()


## Forces a GPU update + notify regardless of the dirty flag (e.g. external edits).
func notify_changed() -> void:
	_dirty = true
	flush()


## Bulk replace the ACTIVE frame's image (undo/restore). Recreates the frame's
## texture when the replacement has different dimensions.
func replace_with(new_image: Image) -> void:
	var f := _active()
	if f == null:
		return
	# Duplicate so the live frame never aliases the caller's Image. Undo snapshots
	# are bound into history and must stay immutable even while the user keeps
	# painting on the restored frame (see restore_frame / restore_state).
	var prev_size := f.image.get_size()
	var owned := new_image.duplicate()
	f.image = owned
	if owned.get_size() != prev_size:
		f.texture = ImageTexture.create_from_image(owned)
	else:
		f.texture.update(owned)
	image = f.image
	texture = f.texture
	_dirty = false
	changed.emit()


## Undo helper: select `index`, then restore that exact frame from `snapshot`.
## Capturing the index is what keeps per-frame pixel undo correct even after the
## user has navigated to another frame.
func restore_frame(index: int, snapshot: Image) -> void:
	select_frame(index)
	replace_with(snapshot)


## Region-based undo restore: select `index`, then overwrite (not blend) the
## touched `region` with `src`, which must be exactly region.size. `src` is built
## from raw bytes by the caller and consumed here, so nothing stored in history
## is aliased into the live frame. Pairs with UndoManager._restore_region.
func restore_region(index: int, region: Rect2i, src: Image) -> void:
	select_frame(index)
	var f := _active()
	if f == null:
		return
	f.image.blit_rect(src, Rect2i(Vector2i.ZERO, region.size), region.position)
	image = f.image
	texture = f.texture
	texture.update(f.image)
	_dirty = false
	changed.emit()


# ---------------------------------------------------------- structural undo

## Deep snapshot of the whole animation (images duplicated so later edits can't
## mutate a stored snapshot). Used by structural (add/dup/delete) undo.
func snapshot_state() -> Dictionary:
	var imgs: Array = []
	var durs: Array = []
	for f in frames:
		imgs.append(f.image.duplicate())
		durs.append(f.duration)
	return {"images": imgs, "durations": durs, "index": _current, "fps": fps}


## Rebuilds every frame from a snapshot_state(). Used by structural undo/redo.
func restore_state(state: Dictionary) -> void:
	frames.clear()
	var imgs: Array = state.get("images", [])
	var durs: Array = state.get("durations", [])
	for i in imgs.size():
		var f := Frame.new()
		# Duplicate each snapshot image so later live edits can't mutate the copies
		# retained by structural undo history.
		var owned: Image = imgs[i].duplicate()
		f.image = owned
		f.texture = ImageTexture.create_from_image(owned)
		f.duration = float(durs[i]) if i < durs.size() else DEFAULT_FRAME_DURATION
		frames.append(f)
	_current = clampi(int(state.get("index", 0)), 0, maxi(0, frames.size() - 1))
	fps = float(state.get("fps", fps))
	_refresh_active()
	structure_changed.emit()
	frame_changed.emit()
	changed.emit()
