@tool
class_name TimelinePanel
extends PanelContainer

## Bottom-of-dock animation timeline.
##
## Owns: frame navigation, playback (play/loop/fps), structural frame ops
## (add/duplicate/delete), the scrollable thumbnail filmstrip, and onion-skin
## toggling. It only OBSERVES the document: all mutations go through the
## ImageDocument API so undo + the canvas stay consistent.

const _FrameThumb := preload("res://addons/pixel_editor/ui/frame_thumb.gd")
const _ThumbSize := 32

var _canvas: PixelCanvas
var _undo_manager: UndoManager
var _document: ImageDocument

@onready var _prev_btn: Button = %PrevFrameButton
@onready var _play_btn: Button = %PlayButton
@onready var _next_btn: Button = %NextFrameButton
@onready var _fps_spin: SpinBox = %FPSSpin
@onready var _loop_btn: Button = %LoopButton
@onready var _onion_btn: Button = %OnionButton
@onready var _add_btn: Button = %AddFrameButton
@onready var _dup_btn: Button = %DuplicateFrameButton
@onready var _del_btn: Button = %DeleteFrameButton
@onready var _frame_label: Label = %FrameLabel
@onready var _scroll: ScrollContainer = %FilmstripScroll
@onready var _filmstrip: HBoxContainer = %Filmstrip

var _thumbs: Array = []  # Array[FrameThumb]
var _playing: bool = false
var _accum: float = 0.0

# Coalesces thumbnail updates. document `changed` fires once per motion event
# during a stroke (flush() runs after every dab), but rebuilding a thumbnail
# duplicates the whole frame image, resizes it and uploads a fresh GPU texture.
# Doing that per-event is a severe paint-time bottleneck (dozens of full-image
# copies + GPU uploads per second), so we only stamp the dirty index here and
# let _process() perform at most ONE rebuild per rendered frame.
var _thumb_dirty_index := -1


func _ready() -> void:
	_prev_btn.pressed.connect(_on_prev)
	_play_btn.toggled.connect(_on_play_toggled)
	_next_btn.pressed.connect(_on_next)
	_fps_spin.value_changed.connect(_on_fps_changed)
	_wire_fps_focus_release()
	_add_btn.pressed.connect(_on_add_frame)
	_dup_btn.pressed.connect(_on_duplicate_frame)
	_del_btn.pressed.connect(_on_delete_frame)
	_onion_btn.toggled.connect(_on_onion_toggled)
	_apply_icons()
	# Mirror the scene's initial onion state into the canvas.
	_on_onion_toggled(_onion_btn.button_pressed)


## Wires the FPS field so its keyboard focus is returned to the editor on
## interaction instead of clinging forever (see _input below).
func _wire_fps_focus_release() -> void:
	var fps_edit := _fps_spin.get_line_edit()
	if fps_edit == null:
		return
	# Enter/Return after typing commits the value (the SpinBox already does so
	# internally); here it also yields the caret back to the editor.
	fps_edit.text_submitted.connect(_on_fps_edit_submitted)


## Godot funnels a SpinBox's keyboard focus into its inner LineEdit and, due to
## a long-standing quirk, keeps it — so the caret keeps blinking over the canvas
## long after the field is used, no matter where you click (the canvas and most
## toolbar controls are focus_mode = FOCUS_NONE, so they never steal it back).
## Release it on any mouse press. A click landing on the SpinBox itself is
## harmless: the SpinBox/LineEdit re-grab focus during their own _gui_input,
## which runs after _input, so normal editing is unaffected.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if not is_instance_valid(_fps_spin):
		return
	var fps_edit := _fps_spin.get_line_edit()
	if fps_edit == null or not fps_edit.has_focus():
		return
	fps_edit.release_focus()


func _on_fps_edit_submitted(_text: String) -> void:
	if not is_instance_valid(_fps_spin):
		return
	var fps_edit := _fps_spin.get_line_edit()
	if fps_edit != null and fps_edit.has_focus():
		fps_edit.release_focus()


## Called once by the dock after its own _ready() (children init bottom-up, so
## our @onready refs are valid by then).
func bind(canvas: PixelCanvas, undo_manager: UndoManager) -> void:
	_canvas = canvas
	_undo_manager = undo_manager


## (Re)binds the active document. The dock calls this on every document swap.
func bind_document(doc: ImageDocument) -> void:
	if _document != null:
		_document.changed.disconnect(_on_doc_changed)
		_document.frame_changed.disconnect(_on_frame_changed)
		_document.structure_changed.disconnect(_on_structure_changed)
	_document = doc
	stop_playback()
	if _document != null:
		_document.changed.connect(_on_doc_changed)
		_document.frame_changed.connect(_on_frame_changed)
		_document.structure_changed.connect(_on_structure_changed)
		_fps_spin.set_value_no_signal(_document.fps)
		_canvas.onion_skin_enabled = _onion_btn.button_pressed
	_rebuild_thumbs()
	_update_frame_label()
	_update_selection()


# ------------------------------------------------------------------ playback

func _process(delta: float) -> void:
	# Flush any coalesced thumbnail update before the playback early-out, so the
	# filmstrip still refreshes live while editing. One rebuild per rendered
	# frame max, no matter how many `changed` signals arrived since last frame.
	if _thumb_dirty_index >= 0:
		var idx := _thumb_dirty_index
		_thumb_dirty_index = -1
		_regen_thumb(idx)
	if not _playing or _document == null:
		return
	var count := _document.get_frame_count()
	if count < 2:
		stop_playback()
		return
	_accum += delta
	# Seconds each frame is held. Clamped so a stray 0 fps can't freeze the loop.
	var frame_time := 1.0 / maxf(_document.fps, 1.0)
	# Guard bounds the catch-up loop (e.g. after a long frame hitch).
	var guard := 0
	while _accum >= frame_time and guard < count:
		_accum -= frame_time
		guard += 1
		var next_idx := _document.get_current_index() + 1
		if next_idx >= count:
			if _loop_btn.button_pressed:
				next_idx = 0
			else:
				stop_playback()
				return
		_document.select_frame(next_idx)


func _on_play_toggled(pressed: bool) -> void:
	if pressed:
		start_playback()
	else:
		stop_playback()


func start_playback() -> void:
	if _document == null or _document.get_frame_count() < 2:
		_play_btn.set_pressed_no_signal(false)
		return
	_playing = true
	_accum = 0.0
	_update_play_icon()


func stop_playback() -> void:
	_playing = false
	_play_btn.set_pressed_no_signal(false)
	_update_play_icon()


func _update_play_icon() -> void:
	var theme := EditorInterface.get_editor_theme()
	var icon_name := "Play" if not _playing else "Pause"
	if theme.has_icon(icon_name, "EditorIcons"):
		_play_btn.icon = theme.get_icon(icon_name, "EditorIcons")
		_play_btn.text = ""
	else:
		_play_btn.icon = null
		_play_btn.text = icon_name


# --------------------------------------------------------------- navigation

func _on_prev() -> void:
	if _document != null:
		_document.select_frame(_document.get_current_index() - 1)


func _on_next() -> void:
	if _document != null:
		_document.select_frame(_document.get_current_index() + 1)


func _on_fps_changed(value: float) -> void:
	if _document != null:
		_document.fps = value


func _on_onion_toggled(pressed: bool) -> void:
	if _canvas != null:
		_canvas.onion_skin_enabled = pressed


# ------------------------------------------------------------- frame ops

func _on_add_frame() -> void:
	if _document == null or _undo_manager == null:
		return
	_undo_manager.begin_structure(_document)
	_document.add_blank_frame()
	_undo_manager.commit_structure(_document, "Add Frame")
	# structure_changed rebuilds thumbs; just ensure the new one is visible.
	call_deferred("_ensure_current_visible")


func _on_duplicate_frame() -> void:
	if _document == null or _undo_manager == null:
		return
	_undo_manager.begin_structure(_document)
	_document.duplicate_frame()
	_undo_manager.commit_structure(_document, "Duplicate Frame")
	call_deferred("_ensure_current_visible")


func _on_delete_frame() -> void:
	if _document == null or _undo_manager == null:
		return
	if _document.get_frame_count() <= 1:
		return  # never delete the last frame
	_undo_manager.begin_structure(_document)
	_document.delete_frame()
	_undo_manager.commit_structure(_document, "Delete Frame")


# ------------------------------------------------------------ filmstrip sync

## Active-frame pixels changed -> mark that thumbnail dirty only. The actual
## rebuild (image dup + resize + GPU upload) is coalesced in _process() so a
## fast stroke can't trigger dozens of full-image copies per second. Skipped
## during playback: switching frames there doesn't change any pixels.
func _on_doc_changed() -> void:
	if _document == null or _playing:
		return
	_thumb_dirty_index = _document.get_current_index()


func _on_frame_changed() -> void:
	_update_selection()
	_update_frame_label()
	_ensure_current_visible()


## Frames added/removed/reordered -> rebuild the whole strip.
func _on_structure_changed() -> void:
	_rebuild_thumbs()
	_update_frame_label()
	_update_selection()


func _rebuild_thumbs() -> void:
	for thumb in _thumbs:
		if is_instance_valid(thumb):
			thumb.queue_free()
	_thumbs.clear()
	if _document == null:
		return
	for i in _document.get_frame_count():
		var thumb := _FrameThumb.new()
		thumb.frame_index = i
		thumb.custom_minimum_size = Vector2(_ThumbSize, _ThumbSize)
		thumb.texture = _make_thumbnail(_document.frames[i].image)
		thumb.pressed.connect(_on_thumb_pressed.bind(i))
		_filmstrip.add_child(thumb)
		_thumbs.append(thumb)


func _regen_thumb(index: int) -> void:
	if index < 0 or index >= _thumbs.size():
		return
	var thumb = _thumbs[index]
	if not is_instance_valid(thumb) or _document == null:
		return
	thumb.texture = _make_thumbnail(_document.frames[index].image)


func _on_thumb_pressed(index: int) -> void:
	if _document != null:
		_document.select_frame(index)


func _update_selection() -> void:
	var cur := _document.get_current_index() if _document != null else -1
	for i in _thumbs.size():
		if is_instance_valid(_thumbs[i]):
			_thumbs[i].selected = (i == cur)


func _update_frame_label() -> void:
	if _document == null:
		_frame_label.text = "— / —"
	else:
		_frame_label.text = "%d / %d" % [
			_document.get_current_index() + 1,
			_document.get_frame_count(),
		]


func _ensure_current_visible() -> void:
	if _document == null:
		return
	var idx := _document.get_current_index()
	if idx < 0 or idx >= _thumbs.size():
		return
	if is_instance_valid(_thumbs[idx]):
		_scroll.ensure_control_visible(_thumbs[idx])


## Scales a frame image down to a thumbnail, nearest-filtered, aspect-preserving.
func _make_thumbnail(img: Image) -> ImageTexture:
	var w := img.get_width()
	var h := img.get_height()
	var scale := float(_ThumbSize) / maxf(w, h)
	var tw := maxi(1, roundi(w * scale))
	var th := maxi(1, roundi(h * scale))
	var small := img.duplicate()
	small.resize(tw, th, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(small)


# ------------------------------------------------------------------- styling

## Replaces button text with editor theme icons where available, styling each as
## a flat toolbar button. Text remains as a fallback for any icon that's absent.
func _apply_icons() -> void:
	var theme := EditorInterface.get_editor_theme()
	# button -> { candidates, tooltip }
	var mapping := {
		_prev_btn: {"icons": ["PlayStartBackwards"], "tip": "Previous frame"},
		_next_btn: {"icons": ["PlayStart"], "tip": "Next frame"},
		_add_btn: {"icons": ["Add"], "tip": "Add frame"},
		_dup_btn: {"icons": ["Duplicate"], "tip": "Duplicate frame"},
		_del_btn: {"icons": ["Remove"], "tip": "Delete frame"},
		_loop_btn: {"icons": ["Loop"], "tip": "Loop playback"},
		_onion_btn: {"icons": ["Onion"], "tip": "Toggle onion skin"},
	}
	for button in mapping:
		var spec: Dictionary = mapping[button]
		_style_flat(button)
		button.tooltip_text = spec["tip"]
		for icon_name in spec["icons"]:
			if theme.has_icon(icon_name, "EditorIcons"):
				button.icon = theme.get_icon(icon_name, "EditorIcons")
				button.text = ""
				break
	# Play button swaps icons dynamically (Play/Pause), but is styled flat
	# and given a tooltip like the rest of the toolbar.
	_style_flat(_play_btn)
	_play_btn.tooltip_text = "Play/Pause"
	_update_play_icon()


func _style_flat(button: Button) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(28, 28)
