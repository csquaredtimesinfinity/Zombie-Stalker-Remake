@tool
class_name UndoManager

## Owns the undo/redo stack for image edits.
##
## Uses a dedicated UndoRedo (not EditorUndoRedoManager) so history is scoped
## to the editor's lifetime of this document and predictable across focus
## changes. The snapshot model: before a stroke we copy the image; the undo
## action restores that copy, the redo action restores the post-stroke copy.
##
## History is capped (max_steps) so retained full-image snapshots can't grow
## memory without bound over a long session. Call clear_history() when the
## active document changes — snapshots belong to a specific document.

signal history_changed

const _MaxHistorySteps := 64

var _undo_redo := UndoRedo.new()
var _pre_stroke: Image
# Snapshot of the full frame list, captured before a structural op (add/dup/del).
var _pre_structure: Dictionary


func _init() -> void:
	_undo_redo.set_max_steps(_MaxHistorySteps)


## Called at stroke start: snapshot current image so any edit can be reverted.
## The full copy is retained only until commit_stroke extracts the dirty region;
## history itself stores just the touched pixels. Also turns on per-pixel dirty
## tracking so commit_stroke knows which region to snapshot.
func begin_stroke_session(document: ImageDocument) -> void:
	_pre_stroke = document.image.duplicate()
	document._begin_dirty_tracking()


## Called at stroke end: register a single undoable action for the whole stroke.
## Captures the active frame index so undo restores onto the *original* frame,
## even after the user has navigated to a different one.
##
## Instead of retaining two full-image copies, we snapshot only the bounding rect
## of pixels the stroke touched (tracked by ImageDocument). A 512x512 canvas with
## a 16x16 brush therefore costs ~1 KB/step instead of ~2 MB/step.
func commit_stroke(document: ImageDocument, action_name: String) -> void:
	if _pre_stroke == null:
		return
	var region := document._end_dirty_tracking()
	var idx := document.get_current_index()
	# Nothing was written (e.g. every dab landed out of bounds): drop the action so
	# history isn't polluted with a no-op.
	if region.size.x <= 0 or region.size.y <= 0:
		_pre_stroke = null
		return
	var fmt := document.image.get_format()
	var before_bytes := _pre_stroke.get_region(region).get_data()
	var after_bytes := document.image.get_region(region).get_data()
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(_restore_region.bind(document, idx, region, fmt, after_bytes))
	_undo_redo.add_undo_method(_restore_region.bind(document, idx, region, fmt, before_bytes))
	_undo_redo.commit_action()
	# Drop the transient full copy; only the small regions above are retained.
	_pre_stroke = null
	history_changed.emit()


## Snapshot the whole animation before a structural op (add/dup/del/move).
func begin_structure(document: ImageDocument) -> void:
	_pre_structure = document.snapshot_state()


## Register a structural op as a single undoable full-state restore.
func commit_structure(document: ImageDocument, action_name: String) -> void:
	if _pre_structure.is_empty():
		return
	var before := _pre_structure
	var after := document.snapshot_state()
	_undo_redo.create_action(action_name)
	_undo_redo.add_do_method(_restore_structure.bind(document, after))
	_undo_redo.add_undo_method(_restore_structure.bind(document, before))
	_undo_redo.commit_action()
	# Reassign, don't .clear(): `before` above aliases the SAME Dictionary and is
	# bound into the undo Callable. Clearing in place would empty that bound
	# snapshot, so undo would restore zero frames -> null active texture ->
	# "rp_texture is null" on the next redraw.
	_pre_structure = {}
	history_changed.emit()


func undo() -> void:
	_undo_redo.undo()
	history_changed.emit()


func redo() -> void:
	_undo_redo.redo()
	history_changed.emit()


func can_undo() -> bool:
	return _undo_redo.has_undo()


func can_redo() -> bool:
	return _undo_redo.has_redo()


## Drops all history. Use when switching documents so snapshots from a previous
## image can't be restored onto the current one.
func clear_history() -> void:
	_undo_redo.clear_history()
	_pre_stroke = null
	# Reassign, don't .clear(): a structural snapshot may be bound into a live
	# UndoRedo Callable (see commit_structure). Clearing in place would empty
	# that bound Dictionary so undo would restore zero frames.
	_pre_structure = {}
	history_changed.emit()


## Releases the backing UndoRedo and any retained snapshots. The dock MUST call
## this on _exit_tree (NOTIFICATION_PREDELETE): UndoRedo holds bound Callables
## that reference the document + its frame Images, so without an explicit free
## the whole document graph is retained for the editor's lifetime every time
## the plugin is disabled. After dispose() the manager is inert.
func dispose() -> void:
	_undo_redo.clear_history()
	# free() is safe on Object subclasses; UndoRedo is an Object (not RefCounted).
	if _undo_redo != null:
		_undo_redo.free()
		_undo_redo = null
	_pre_stroke = null
	_pre_structure = {}


## Restore helper bound into UndoRedo entries (per-frame pixel edits).
func _restore(document: ImageDocument, index: int, snapshot: Image) -> void:
	document.restore_frame(index, snapshot)


## Region-based restore bound into UndoRedo entries. Rebuilds a small Image from
## the captured bytes and blits it back over the touched region. `bytes` is a
## PackedByteArray value, so the history copy can't be mutated by live painting.
func _restore_region(
	document: ImageDocument,
	index: int,
	region: Rect2i,
	fmt: int,
	bytes: PackedByteArray
) -> void:
	var src := Image.create_from_data(region.size.x, region.size.y, false, fmt, bytes)
	document.restore_region(index, region, src)


## Restore helper bound into UndoRedo entries (structural frame edits).
func _restore_structure(document: ImageDocument, state: Dictionary) -> void:
	document.restore_state(state)
