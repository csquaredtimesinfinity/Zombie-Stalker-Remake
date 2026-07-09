extends TextureRect

var crt_effect_enabled = true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_crt_effect"):
		crt_effect_enabled = !crt_effect_enabled
		_update_crt_effect()

func _update_crt_effect() -> void:
	use_parent_material = !crt_effect_enabled
