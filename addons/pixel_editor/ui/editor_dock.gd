@tool
class_name PixelEditorDock
extends Control

## Composition root. Owns toolbar buttons, the canvas, the active document
## and the registry of tools.
##
## Tools are organised into two mouse-button "slots" (left/right). Each slot is
## an OptionButton the user binds to a tool — e.g. Pencil on left-click and
## Eraser on right-click. The slots map directly to InputController bindings.
##
## Explicit preloads (instead of relying on global class_name resolution)
## make the dock resilient to first-enable timing when the addon's classes
## may not yet be registered in the editor's script cache.

const _PencilTool := preload("res://addons/pixel_editor/tools/pencil.gd")
const _EraserTool := preload("res://addons/pixel_editor/tools/eraser.gd")
const _FillTool := preload("res://addons/pixel_editor/tools/fill.gd")
const _InputController := preload("res://addons/pixel_editor/canvas/input_controller.gd")
const _UndoManager := preload("res://addons/pixel_editor/history/undo_manager.gd")
const _ImageDocument := preload("res://addons/pixel_editor/image/image_document.gd")
const _ImageIO := preload("res://addons/pixel_editor/image/image_io.gd")
const _AnimationIO := preload("res://addons/pixel_editor/image/animation_io.gd")
const _TimelinePanel := preload("res://addons/pixel_editor/ui/timeline_panel.gd")
const _DonationDialog := preload("res://addons/pixel_editor/ui/donation_dialog.gd")

@onready var _canvas: PixelCanvas = %PixelCanvas
@onready var _new_button: Button = %NewButton
@onready var _open_button: Button = %OpenButton
@onready var _save_button: Button = %SaveButton
@onready var _donate_button: Button = %DonateButton
@onready var _donation_dialog: _DonationDialog = %DonationDialog
@onready var _open_dialog: FileDialog = %OpenDialog
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _new_size_dialog: AcceptDialog = %NewSizeDialog
@onready var _width_spin: SpinBox = %WidthSpin
@onready var _height_spin: SpinBox = %HeightSpin
@onready var _presets_grid: GridContainer = %PresetsGrid
# Per-slot colour pickers. Each mouse-button slot owns its own colour so the
# user can, e.g., paint with two differently-coloured pencils at once.
# Colour-less tools (Eraser) ignore their slot's colour.
@onready var _left_color: ColorPickerButton = %LeftColorButton
@onready var _right_color: ColorPickerButton = %RightColorButton
@onready var _left_slot: OptionButton = %LeftSlot
@onready var _right_slot: OptionButton = %RightSlot
@onready var _left_label: TextureRect = %LeftLabel
@onready var _right_label: TextureRect = %RightLabel
@onready var _zoom_in_button: Button = %ZoomInButton
@onready var _zoom_out_button: Button = %ZoomOutButton
@onready var _zoom_label: Button = %ZoomLabel
# Zoom level captured when the user clicks the zoom label to preview at 100%.
# Used to restore the previous level on a second click.
var _zoom_preview_saved: float = -1.0
@onready var _fit_button: Button = %FitButton
@onready var _grid_button: Button = %GridButton
@onready var _mirror_button: MenuButton = %MirrorButton
@onready var _undo_button: Button = %UndoButton
@onready var _redo_button: Button = %RedoButton
@onready var _timeline: _TimelinePanel = %TimelinePanel

var _input_controller: InputController
var _undo_manager: UndoManager
# True after our own _ready; gates _exit_tree so a partially-built dock can't
# free things that were never created (e.g. if @onready failed mid-way).
var _initialized: bool = false
# Brush colour per mouse-button slot. Mirrored into the InputController so the
# active stroke's colour is resolved from the button that started it.
var _left_brush_color: Color = Color.BLACK
var _right_brush_color: Color = Color.WHITE

# Latched on the Save button's mouse-down: Shift held => next press is Save As.
# Read in _on_save_pressed (the global Input singleton is unreliable in @tool).
var _save_as_next: bool = false

# Tool registry — adding a new tool here (and to _TOOL_ORDER) is the only
# wiring step. The slot dropdowns are populated from _TOOL_ORDER, with the
# registry key stored as item metadata.
var _tools: Dictionary = {}

# Display order of tools in the slot dropdowns.
const _TOOL_ORDER := ["pencil", "eraser", "fill"]

# Most common pixel-art canvas sizes, surfaced as one-click presets in the New
# Image dialog. Add or reorder here; the buttons rebuild on _ready.
const _SIZE_PRESETS := [8, 16, 32, 64, 128, 256]

# EditorIcons candidates per tool (first available wins). Lets each slot render
# as an icon instead of text; falls back to text when none resolve.
const _ToolIcons := {
	"pencil": ["Edit"],
	"eraser": ["Eraser"],
	"fill": ["Bucket", "Paint"],
}

# Bundled SVG glyphs
const _PLUGIN_ICONS := {
	"MouseLeft": "res://addons/pixel_editor/ui/icons/mouse_button_left.svg",
	"MouseRight": "res://addons/pixel_editor/ui/icons/mouse_button_right.svg",
}


func _ready() -> void:
	_input_controller = _InputController.new()
	_undo_manager = _UndoManager.new()

	_tools["pencil"] = _PencilTool.new()
	_tools["eraser"] = _EraserTool.new()
	_tools["fill"] = _FillTool.new()

	_input_controller.set_undo_manager(_undo_manager)
	_canvas.input_controller = _input_controller

	# Each slot's colour is independent: bind both pickers and seed the
	# InputController so the first stroke has the right colour per button.
	_left_color.color_changed.connect(_on_left_color_changed)
	_right_color.color_changed.connect(_on_right_color_changed)
	_input_controller.set_color(MOUSE_BUTTON_LEFT, _left_brush_color)
	_input_controller.set_color(MOUSE_BUTTON_RIGHT, _right_brush_color)

	_new_button.pressed.connect(_on_new_pressed)
	_open_button.pressed.connect(_open_dialog.popup_centered)
	_open_dialog.file_selected.connect(_on_open_file)
	_new_size_dialog.confirmed.connect(_on_new_confirmed)
	_build_size_presets()

	# Each slot dropdown selects which tool its mouse button uses.
	_populate_slot(_left_slot)
	_populate_slot(_right_slot)
	_left_slot.item_selected.connect(_on_slot_changed)
	_right_slot.item_selected.connect(_on_slot_changed)

	# Defaults: left mouse paints (pencil), right mouse erases (eraser).
	_select_tool_in_slot(_left_slot, "pencil")
	_select_tool_in_slot(_right_slot, "eraser")
	_apply_slots()

	_zoom_in_button.pressed.connect(_canvas.zoom_in)
	_zoom_out_button.pressed.connect(_canvas.zoom_out)
	_fit_button.pressed.connect(_canvas.fit_to_window)
	# Clicking the zoom label toggles between 100% and the previous zoom level,
	# a quick "actual pixels" preview.
	_zoom_label.pressed.connect(_on_zoom_label_pressed)
	# Keep the zoom-percentage label in sync with the canvas's zoom property,
	# whether it changes via the toolbar buttons, the mouse wheel, or Fit.
	_canvas.zoom_changed.connect(_update_zoom_label)
	_update_zoom_label()
	_grid_button.toggled.connect(_on_grid_toggled)
	_build_mirror_menu()

	_save_button.pressed.connect(_on_save_pressed)
	_save_button.gui_input.connect(_on_save_gui_input)
	_donate_button.pressed.connect(_donation_dialog.popup_centered)
	_save_dialog.file_selected.connect(_on_save_as)
	_save_dialog.filters = PackedStringArray(["*.png ; Pixel Animation"])

	_undo_button.pressed.connect(_undo_manager.undo)
	_redo_button.pressed.connect(_undo_manager.redo)
	_undo_manager.history_changed.connect(_update_undo_buttons)
	_update_undo_buttons()
	_apply_editor_icons()

	# Compact square swatches: _flatten_control empties the normal stylebox so the
	# colour fills the whole rect, and SHRINK_CENTER stops the HFlowContainer from
	# stretching the swatch to the toolbar line height — keeping it a small cube.
	_left_color.custom_minimum_size = Vector2(20, 20)
	_left_color.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_right_color.custom_minimum_size = Vector2(20, 20)
	_right_color.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_flatten_control(_left_color)
	_flatten_control(_right_color)
	_flatten_control(_left_slot)
	_flatten_control(_right_slot)

	# Hand the canvas + undo manager to the timeline before any document is set,
	# so its document binding (called from _set_document) has its dependencies.
	_timeline.bind(_canvas, _undo_manager)

	# Start with a ready-to-draw default artboard so the user can paint
	# immediately without pressing New.
	var default_img := _ImageIO.create_blank(16, 16)
	_set_document(_ImageDocument.new(default_img))
	_initialized = true


## Tears down everything _ready wired up. Godot does NOT auto-disconnect signals
## held by RefCounted/Object members (UndoManager, InputController) when this
## Control is freed, and the backing UndoRedo retains bound Callables that
## reference the document + its frame Images — so without explicit cleanup the
## whole document graph leaks every time the plugin is disabled. Also cancels
## the async SpriteFrames retry loop so its deferred callback can't fire on a
## freed dock (a hard crash).
func _exit_tree() -> void:
	if not _initialized:
		return
	_initialized = false
	# Restore the OS cursor in case the pointer was over the artboard (and thus
	# hidden) when the plugin was disabled — otherwise the editor is left with
	# no visible cursor.
	DisplayServer.cursor_set_custom_image(null, DisplayServer.CURSOR_ARROW)
	# Cancel the pending SpriteFrames retry chain first: it uses call_deferred-
	# style timers whose timeout would otherwise invoke _step_spriteframes on a
	# freed instance.
	_sf_timer_active = false
	_sf_pending.clear()
	# Drop the document so the canvas + timeline stop listening to it before we
	# release the undo history (whose bound Callables reference the document).
	_set_document(null)
	if _undo_manager != null:
		_undo_manager.dispose()
		_undo_manager = null
	_input_controller = null


## Centralised document swap: resets undo history (a fresh image has no past)
## so stale snapshots from a previous document can't be restored onto this one.
func _set_document(doc: ImageDocument) -> void:
	# A document swap mid-stroke would leave the InputController thinking a drag
	# is in progress against the outgoing frame; the next click's release would
	# then commit/end on the NEW frame with the OLD button's tool -> a stray,
	# un-undoable dab. Reset stroke state atomically with the swap.
	if _input_controller != null:
		_input_controller.reset_stroke()
	if _undo_manager != null:
		_undo_manager.clear_history()
	if _canvas != null:
		_canvas.document = doc
	if _timeline != null:
		_timeline.bind_document(doc)


## Styles a button to look like a flat editor toolbar icon button.
func _style_as_flat_icon(button: Button) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	# Fixed small square so the toolbar is tidy and icon-aligned.
	button.custom_minimum_size = Vector2(28, 28)


## Strips the resting background + focus ring from a Button-derived control so
## only its content shows (the colour swatch for ColorPickerButton, the tool icon
## for each OptionButton slot). `flat = true` alone is ignored for these types by
## some editor themes, so the normal/focus styleboxes are emptied explicitly;
## hover/pressed are left to the theme so the control still highlights on
## interaction, exactly like the flat toolbar icon buttons.
func _flatten_control(ctrl: Control) -> void:
	ctrl.flat = true
	var empty := StyleBoxEmpty.new()
	ctrl.add_theme_stylebox_override("normal", empty)
	ctrl.add_theme_stylebox_override("focus", empty)


## Replaces button text with Godot's built-in editor icons so the toolbar
## looks native. Falls back to text if an icon name is missing.
## Maps each toolbar button to {icon, tooltip}. icon is an EditorIcons key;
## tooltip is the human-readable action shown on hover.
func _apply_editor_icons() -> void:
	var theme := EditorInterface.get_editor_theme()
	var mapping := {
		_new_button: {"icon": "New", "tip": "New image"},
		_open_button: {"icon": "Load", "tip": "Open file"},
		_save_button: {"icon": "Save", "tip": "Save file\nShift-click: Save As…"},
		_zoom_in_button: {"icon": "ZoomMore", "tip": "Zoom In"},
		_zoom_out_button: {"icon": "ZoomLess", "tip": "Zoom Out"},
		_fit_button: {"icon": "CenterView", "tip": "Fit"},
		_grid_button: {"icon": "Grid", "tip": "Toggle Grid"},
		_undo_button: {"icon": "UndoRedo", "tip": "Undo"},
		_redo_button: {"icon": "Redo", "tip": "Redo"},
		# Heart icon only (no text) so the donate action reads as a quiet
		# flat glyph matching the rest of the toolbar.
		_donate_button: {"icon": "Heart", "tip": "Donate — support this plugin"},
	}
	for button in mapping:
		var spec: Dictionary = mapping[button]
		var icon_name: String = spec["icon"]
		_style_as_flat_icon(button)
		button.tooltip_text = spec["tip"]
		if theme.has_icon(icon_name, "EditorIcons"):
			button.icon = theme.get_icon(icon_name, "EditorIcons")
			button.text = ""
		else:
			# Fallback: show the tooltip text if the icon is unavailable.
			button.text = spec["tip"]

	# Mouse-button glyphs next to each slot dropdown use our own bundled SVGs
	# instead of bare "L"/"R" letters (the editor has no such icons in 4.7).
	# Size the glyph by the editor interface scale so it tracks the toolbar the
	# same way the built-in editor icons do; _load_scaled_icon re-decodes the SVG
	# at HiDPI resolution so it stays crisp and full-size on retina displays.
	var icon_size := Vector2(16, 16) * EditorInterface.get_editor_scale()
	_left_label.custom_minimum_size = icon_size
	_right_label.custom_minimum_size = icon_size
	_left_label.texture = _load_scaled_icon(_PLUGIN_ICONS.MouseLeft)
	_right_label.texture = _load_scaled_icon(_PLUGIN_ICONS.MouseRight)


## Decodes a bundled SVG glyph at a resolution matched to the current editor
## interface scale and the window's HiDPI backing factor. A plain load() bakes
## the SVG at its fixed 16px native size, so on a 2x retina display the glyph
## only carries half the pixels its rect needs and renders half-size / blurry.
## Scaling the SVG at decode time keeps it crisp and at the intended size on
## high-DPI screens. The editor scale (perceptual size) and the backing factor
## (pixel density) are orthogonal, so we multiply both without double-counting.
func _load_scaled_icon(path: String) -> ImageTexture:
	var ed_scale := EditorInterface.get_editor_scale()
	var win := get_window()
	var hidpi := win.content_scale_factor if win != null else 1.0
	var scale_factor := maxf(ed_scale, 1.0) * maxf(hidpi, 1.0)
	var buf := FileAccess.get_file_as_bytes(path)
	var img := Image.new()
	var err := img.load_svg_from_buffer(buf, scale_factor)
	if err != OK:
		push_warning("PixelEditor: could not load icon %s (%d)" % [path, err])
		return ImageTexture.new()
	return ImageTexture.create_from_image(img)


func _update_undo_buttons() -> void:
	_undo_button.disabled = not _undo_manager.can_undo()
	_redo_button.disabled = not _undo_manager.can_redo()


func _on_grid_toggled(pressed: bool) -> void:
	_canvas.show_grid = pressed


## Refreshes the zoom-percentage readout between the zoom buttons. Rounded so
## the label stays stable instead of flickering on every fractional wheel step.
func _update_zoom_label() -> void:
	_zoom_label.text = "%d%%" % int(round(_canvas.zoom * 100.0))
	# If the user zooms by some other means while previewing at 100%,
	# drop the saved level so the next click goes to 100% fresh.
	if _zoom_preview_saved > 0.0 and not is_equal_approx(_canvas.zoom, 1.0) \
			and not is_equal_approx(_canvas.zoom, _zoom_preview_saved):
		_zoom_preview_saved = -1.0


## Toggle between 100% and the previous zoom level. First click on a non-100%
## view snaps to 100% (saving the current level); a second click restores it.
func _on_zoom_label_pressed() -> void:
	if is_equal_approx(_canvas.zoom, 1.0) and _zoom_preview_saved > 0.0:
		# Restore the level saved before the 100% preview.
		_canvas.zoom = _zoom_preview_saved
		_zoom_preview_saved = -1.0
	elif not is_equal_approx(_canvas.zoom, 1.0):
		_zoom_preview_saved = _canvas.zoom
		_canvas.zoom = 1.0
	else:
		# Already at 100% with nothing saved: nothing to toggle.
		_zoom_preview_saved = -1.0
	# Keep the canvas anchored to its centre when jumping, matching the
	# behaviour of the zoom-in/out toolbar buttons.
	_canvas.queue_redraw()


# Index of the two independent mirror toggles inside the popup menu. Kept as
# constants so reordering the menu only needs one edit.
const _MIRROR_H_IDX := 0
const _MIRROR_V_IDX := 1


## Builds the Mirror dropdown as two independent check items (Horizontal /
## Vertical) so the user can pick any combination: none, H, V, or both.
## Default state is unchecked => mirroring disabled, per requirements.
func _build_mirror_menu() -> void:
	var popup := _mirror_button.get_popup()
	popup.clear()
	# Check items start unchecked, so mirroring is disabled by default.
	popup.add_check_item("Horizontal Mirror", _MIRROR_H_IDX)
	popup.add_check_item("Vertical Mirror", _MIRROR_V_IDX)
	popup.index_pressed.connect(_on_mirror_toggled)
	# Resolve an icon independently of _apply_editor_icons because that path
	# hides the text — but MenuButton needs to keep showing its dropdown glyph.
	# We resolve "Mirror" (Godot 4.7+) and fall back to keeping the text label.
	var theme := EditorInterface.get_editor_theme()
	if theme.has_icon("KeepAspect", "EditorIcons"):
		_mirror_button.icon = theme.get_icon("KeepAspect", "EditorIcons")
		_mirror_button.text = ""
	else:
		_mirror_button.text = "Mirror"
	_update_mirror_button()


## Toggles the picked axis on its menu item and pushes the resulting state to
## the canvas (and into the ToolContext via the canvas property).
func _on_mirror_toggled(index: int) -> void:
	var popup := _mirror_button.get_popup()
	var now := not popup.is_item_checked(index)
	popup.set_item_checked(index, now)
	if index == _MIRROR_H_IDX:
		_canvas.mirror_h = now
	elif index == _MIRROR_V_IDX:
		_canvas.mirror_v = now
	_update_mirror_button()


## Reflects whether either mirror axis is active on the button: pressed look +
## tooltip text. Called whenever a menu item flips, so the toolbar always shows
## the current state at a glance.
func _update_mirror_button() -> void:
	# Match the other toolbar buttons: default theme font colour (Godot grey)
	# when inactive, primary editor colour when active. MenuButton doesn't
	# latch, so modulate carries the state.
	var theme := EditorInterface.get_editor_theme()
	var inactive := theme.get_color("font_color", "Button")
	var active := theme.get_color("accent_color", "Editor")
	_mirror_button.modulate = active if (_canvas.mirror_h or _canvas.mirror_v) else inactive
	var parts: Array = []
	if _canvas.mirror_h:
		parts.append("H")
	if _canvas.mirror_v:
		parts.append("V")
	var state := "None" if parts.is_empty() else " ".join(parts)
	_mirror_button.tooltip_text = "Mirror painting (%s)\nHorizontal / Vertical mirroring" % state


func _on_left_color_changed(color: Color) -> void:
	_left_brush_color = color
	_input_controller.set_color(MOUSE_BUTTON_LEFT, color)


func _on_right_color_changed(color: Color) -> void:
	_right_brush_color = color
	_input_controller.set_color(MOUSE_BUTTON_RIGHT, color)


## Fills a slot dropdown with every tool in _TOOL_ORDER, storing the registry
## key as each item's metadata so selection survives reordering.
func _populate_slot(slot: OptionButton) -> void:
	slot.clear()
	for tname in _TOOL_ORDER:
		slot.add_item(tname.capitalize())
		var i := slot.item_count - 1
		slot.set_item_metadata(i, tname)
		# Prefer an icon: hide the text so the slot (and its popup) is icon-only.
		# Keep the text as a fallback when no icon resolves.
		var icon := _get_tool_icon(tname)
		if icon != null:
			slot.set_item_icon(i, icon)
			slot.set_item_text(i, "")
			slot.set_item_tooltip(i, tname.capitalize())


## Resolves a tool's icon from the editor theme, trying candidates in order.
func _get_tool_icon(tname: String) -> Texture2D:
	if not _ToolIcons.has(tname):
		return null
	var theme := EditorInterface.get_editor_theme()
	for icon_name in _ToolIcons[tname]:
		if theme.has_icon(icon_name, "EditorIcons"):
			return theme.get_icon(icon_name, "EditorIcons")
	return null


## Selects the item whose metadata matches `tname` (no-op if not present).
func _select_tool_in_slot(slot: OptionButton, tname: String) -> void:
	for i in slot.item_count:
		if slot.get_item_metadata(i) == tname:
			slot.select(i)
			return


## Pushes the currently selected tools into the input controller, binding each
## slot's tool to its mouse button. Called whenever a dropdown changes.
func _apply_slots() -> void:
	var left_name: String = _left_slot.get_selected_metadata()
	var right_name: String = _right_slot.get_selected_metadata()
	_input_controller.set_tool(MOUSE_BUTTON_LEFT, _tools[left_name], left_name.capitalize())
	_input_controller.set_tool(MOUSE_BUTTON_RIGHT, _tools[right_name], right_name.capitalize())


func _on_slot_changed(_index: int) -> void:
	_apply_slots()


func _on_new_pressed() -> void:
	_new_size_dialog.popup_centered(Vector2i(320, 240))


func _on_new_confirmed() -> void:
	var img := _ImageIO.create_blank(int(_width_spin.value), int(_height_spin.value))
	_set_document(_ImageDocument.new(img))


## Builds one button per entry in _SIZE_PRESETS into the New Image dialog.
## Each preset is a square power-of-two; adding a size here is the only change
## needed — the buttons rebuild on _ready.
func _build_size_presets() -> void:
	for child in _presets_grid.get_children():
		child.free()
	for size in _SIZE_PRESETS:
		var btn := Button.new()
		btn.text = "%d×%d" % [size, size]
		btn.tooltip_text = "Create a %d×%d image" % [size, size]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var px: int = size
		btn.pressed.connect(_apply_preset.bind(px, px))
		_presets_grid.add_child(btn)


## One-click path through the New Image dialog: writes the chosen dimensions
## into the spin boxes and immediately creates the blank image, so the user
## starts drawing without a second confirm.
func _apply_preset(width: int, height: int) -> void:
	_width_spin.value = width
	_height_spin.value = height
	_on_new_confirmed()
	_new_size_dialog.hide()


func _on_open_file(path: String) -> void:
	# Prefer the animation sidecar when present; otherwise load a single image.
	var doc := _AnimationIO.try_load_animation(path)
	if doc == null:
		var img := _ImageIO.load_png(path)
		if img == null:
			return
		doc = _ImageDocument.new(img)
		doc.file_path = path
	_set_document(doc)


func _on_save_pressed() -> void:
	var doc := _canvas.document
	# Latched at mouse-down by _on_save_gui_input. Reset first so a stale flag
	# can never carry over (e.g. if doc ended up null below).
	var want_save_as := _save_as_next
	_save_as_next = false
	if doc == null:
		return
	# Shift + click always forces Save As (pick a new name / location), even for
	# an already-saved document.
	if want_save_as:
		_show_save_dialog(doc.file_path)
		return
	# In-place save only when the file still exists on disk. If the user deleted
	# the file or its folder after opening, writing in place fails with
	# ERR_FILE_NOT_FOUND (12) — so fall back to Save As instead of erroring out.
	if doc.file_path.is_empty() or not FileAccess.file_exists(doc.file_path):
		_show_save_dialog(doc.file_path)
	else:
		_write_document(doc, doc.file_path)


## Captures whether Shift is held on the Save button's mouse-down so a plain
## click becomes Save As. The modifier is read from the event itself because the
## Input singleton is unreliable inside a @tool editor script.
func _on_save_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_save_as_next = event.shift_pressed


## Pops the Save dialog. `existing_path` (may be empty) pre-fills the name and,
## when its folder still exists, the location — so a deleted-file recovery or a
## plain Save As keeps the user's previous choice.
func _show_save_dialog(existing_path: String) -> void:
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	var dir := ProjectSettings.globalize_path("res://")
	var file_name := "sprite.png"
	if not existing_path.is_empty():
		file_name = existing_path.get_file()
		if file_name.is_empty():
			file_name = "sprite.png"
		var prev_dir := existing_path.get_base_dir()
		if not prev_dir.is_empty() and DirAccess.dir_exists_absolute(prev_dir):
			dir = prev_dir
	_save_dialog.current_dir = dir
	_save_dialog.current_file = file_name
	_save_dialog.popup_centered(Vector2i(700, 500))


## First save / Save As: resolve the on-disk path for the document, then write.
## A static (single-frame) image goes straight to the chosen path; a multi-frame
## animation is bundled into a per-sprite folder.
##   static:   "res://sprites/hero.png" -> res://sprites/hero.png
##   animated: "res://sprites/hero.png" -> res://sprites/hero/{hero.png, ...}
func _on_save_as(chosen_path: String) -> void:
	var doc := _canvas.document
	if doc == null:
		return
	var path := _resolve_save_path(chosen_path, doc.get_frame_count())
	if path.is_empty():
		return
	if _write_document(doc, path) == OK:
		doc.file_path = path


## Canonicalises the chosen name to `.png` and, for an animation, makes the
## per-sprite folder. Returns "" if the folder can't be created. A static image
## keeps the user's exact path (no folder, no sidecar, no .frames.tres).
func _resolve_save_path(chosen_path: String, frame_count: int) -> String:
	var file_name := chosen_path.get_file()
	if file_name.is_empty():
		file_name = "sprite.png"
	elif file_name.get_extension().to_lower() != "png":
		file_name += ".png"
	chosen_path = chosen_path.get_base_dir().path_join(file_name)
	if frame_count <= 1:
		return chosen_path
	var base_name := file_name.get_basename()
	var folder := chosen_path.get_base_dir().path_join(base_name)
	var err := DirAccess.make_dir_recursive_absolute(folder)
	if err != OK:
		push_error("PixelEditor: could not create sprite folder (%d) %s" % [err, folder])
		return ""
	return folder.path_join(base_name + ".png")


## Writes the document to `path`, branching on frame count:
##   - single frame (static): a plain PNG (re-imported so scenes refresh).
##   - multiple frames: spritesheet + sidecar, then the async .frames.tres.
func _write_document(doc: ImageDocument, path: String) -> Error:
	if doc.get_frame_count() <= 1:
		var serr := _AnimationIO.save_static(doc, path)
		if serr != OK:
			push_error("PixelEditor: image save failed (%d) to %s" % [serr, path])
		return serr
	var aerr := _AnimationIO.save_animation(doc, path)
	if aerr != OK:
		push_error("PixelEditor: animation save failed (%d) to %s" % [aerr, path])
		return aerr
	_schedule_spriteframes(path)
	return aerr


# The spritesheet import triggered by save is asynchronous. Calling
# reimport_files() then immediately load()ing races the import, and a second
# reimport recurses — so we poll load() a few times until the texture lands.
const _SpriteFramesMaxRetries := 12
var _sf_pending: Dictionary = {}
var _sf_timer_active: bool = false


func _schedule_spriteframes(sheet_path: String) -> void:
	var doc := _canvas.document
	if doc == null:
		return
	var durs: Array = []
	for f in doc.frames:
		durs.append(f.duration)
	var s := doc.get_size()
	_sf_pending = {
		"sheet_path": sheet_path,
		"fw": maxi(s.x, 1),
		"fh": maxi(s.y, 1),
		"durations": durs,
		"fps": doc.fps,
		"retries": 0,
	}
	if not _sf_timer_active:
		_sf_timer_active = true
		get_tree().create_timer(0.1).timeout.connect(_step_spriteframes)


func _step_spriteframes() -> void:
	if _sf_pending.is_empty():
		_sf_timer_active = false
		return
	var p: Dictionary = _sf_pending
	var ok := _AnimationIO.generate_spriteframes(
		p["sheet_path"], p["fw"], p["fh"], p["durations"], p["fps"]
	)
	if ok or int(p["retries"]) >= _SpriteFramesMaxRetries:
		if not ok:
			push_warning("PixelEditor: SpriteFrames export skipped (import lagged)")
		_sf_pending.clear()
		_sf_timer_active = false
		return
	_sf_pending["retries"] = int(p["retries"]) + 1
	get_tree().create_timer(0.1).timeout.connect(_step_spriteframes)
