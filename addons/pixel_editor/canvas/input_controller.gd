@tool
class_name InputController

## Translates raw Control input events into a tool stroke lifecycle.
##
## Tools are bound per mouse button (left/right "slots") so, e.g., left can paint
## while right erases. Owns the "previous pixel" so drags produce continuous
## lines via Bresenham. Stays independent of which tool is active — it just calls
## into it.
##
## Each slot also carries its own brush colour: the dock binds a colour per
## mouse button via set_color, and the active stroke's colour is resolved from
## the button that started it. Colour-less tools (e.g. Eraser) simply ignore
## ctx.color, so a per-slot colour on an eraser slot has no effect.
##
## Perf: the ToolContext is reused across events (no per-event allocation) and
## the document is flushed once per event (not once per dab).

# Maps a mouse button index -> Tool. Left and right slots are populated by the dock.
var _tools: Dictionary = {}
# Maps a mouse button index -> undo action label (e.g. "Erase").
var _action_names: Dictionary = {}
# Maps a mouse button index -> brush colour. Independent of the bound tool, so a
# slot's colour persists across tool swaps and is only read by colour-aware tools.
var _colors: Dictionary = {}

var _is_drawing: bool = false
# Which mouse button initiated the active stroke (-1 when idle).
var _drawing_button: int = -1
var _last_pixel: Vector2i
var _undo_manager: UndoManager

# Reused across input events to avoid per-event allocation on the hot path.
var _context := Tool.ToolContext.new()


## Binds a tool + its undo label to a mouse button (left/right slot).
func set_tool(button_index: int, tool: Tool, action_name: String) -> void:
	_tools[button_index] = tool
	_action_names[button_index] = action_name


## Binds a brush colour to a mouse button. Each slot gets its own picker, so the
## user can paint with two different colours (or two differently-coloured tools)
## at once. The colour is resolved per stroke from the originating button.
func set_color(button_index: int, color: Color) -> void:
	_colors[button_index] = color


func set_undo_manager(manager: UndoManager) -> void:
	_undo_manager = manager


## Aborts any in-flight stroke. Called on document swap / teardown so a drag
## that started against one document can't end (and commit an undo session)
## against another. Idempotent when no stroke is active.
func reset_stroke() -> void:
	_is_drawing = false
	_drawing_button = -1


func handle_gui_input(event: InputEvent, canvas: PixelCanvas) -> void:
	if canvas.document == null:
		return

	if event is InputEventMouseButton:
		var button: int = event.button_index
		if button == MOUSE_BUTTON_LEFT or button == MOUSE_BUTTON_RIGHT:
			_handle_button(event, canvas)
	elif event is InputEventMouseMotion and _is_drawing:
		_handle_motion(event, canvas)


func _handle_button(event: InputEventMouseButton, canvas: PixelCanvas) -> void:
	var button: int = event.button_index
	var tool: Tool = _tools.get(button)
	if tool == null:
		return
	var ctx := _make_context(canvas, button)
	var hit := canvas.screen_to_pixel(event.position)
	if event.pressed:
		# Only one stroke at a time: ignore presses while another button is held,
		# so simultaneous left/right use can't interleave undo sessions.
		if _is_drawing:
			return
		if hit.valid:
			_is_drawing = true
			_drawing_button = button
			_last_pixel = hit.pixel
			# Read-only tools don't get an undo session (no image change).
			if _undo_manager != null and tool.is_editing():
				_undo_manager.begin_stroke_session(ctx.document)
			tool.begin_stroke(ctx, hit.pixel)
			ctx.document.flush()
	else:
		# Only end the stroke that this button actually started.
		if _is_drawing and _drawing_button == button:
			_is_drawing = false
			_drawing_button = -1
			tool.end_stroke(ctx)
			ctx.document.flush()
			if _undo_manager != null and tool.is_editing():
				_undo_manager.commit_stroke(ctx.document, _action_names.get(button, "Draw"))


func _handle_motion(event: InputEventMouseMotion, canvas: PixelCanvas) -> void:
	var tool: Tool = _tools.get(_drawing_button)
	if tool == null:
		return
	var ctx := _make_context(canvas, _drawing_button)
	var hit := canvas.screen_to_pixel(event.position)
	if not hit.valid:
		return
	tool.continue_stroke(ctx, _last_pixel, hit.pixel)
	_last_pixel = hit.pixel
	ctx.document.flush()


func _make_context(canvas: PixelCanvas, button: int) -> Tool.ToolContext:
	_context.document = canvas.document
	_context.canvas = canvas
	# Resolve this stroke's colour from its originating button. Falls back to
	# black when no colour was bound, so a misconfigured slot still draws.
	_context.color = _colors.get(button, Color.BLACK)
	# Copy the canvas's live mirror flags so every dab of this stroke fans out
	# across the same axes even if the user toggles mid-stroke.
	_context.mirror_h = canvas.mirror_h
	_context.mirror_v = canvas.mirror_v
	return _context
