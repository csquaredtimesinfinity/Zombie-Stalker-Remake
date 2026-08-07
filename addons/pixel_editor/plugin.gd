@tool
extends EditorPlugin

## Entry point for the Pixel Editor plugin.
## Responsibilities are intentionally tiny: register the dock scene and
## hand lifetime management to the dock itself.

const _DockPath := "res://addons/pixel_editor/ui/editor_dock.tscn"

var _dock: Control


func _enter_tree() -> void:
	var scene: PackedScene = load(_DockPath)
	_dock = scene.instantiate()
	# The dock tab title is derived from the node name.
	_dock.name = "PixelEditor"
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
