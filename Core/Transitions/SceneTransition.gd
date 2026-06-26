extends CanvasLayer

@onready var fade_rect = $ColorRect

var tween: Tween

var is_transitioning := false

func _ready():
	fade_rect.color.a = 0.0

func fade_out(duration := 0.5) -> void:

	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_property(
		fade_rect,
		"color:a",
		1.0,
		duration
	)

	await tween.finished


func fade_in(duration := 0.5) -> void:

	if tween:
		tween.kill()

	tween = create_tween()

	tween.tween_property(
		fade_rect,
		"color:a",
		0.0,
		duration
	)

	await tween.finished


func change_scene(scene: Variant, duration := 0.4) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	
	print("begin screen transition")
	await fade_out(duration)

	call_deferred("_do_scene_change", scene, duration)


func _do_scene_change(scene: Variant, duration: float) -> void:
	if scene is String:
		get_tree().change_scene_to_file(scene)
	elif scene is PackedScene:
		print("changing scene to: " + str(scene))
		get_tree().change_scene_to_packed(scene)

	await get_tree().process_frame

	await fade_in(duration)
	print("end screen transition")
	
	is_transitioning = false
