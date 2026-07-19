extends Node2D

@export var lifetime := 2.0
@export var fade_time := 15.0

func _ready():
	rotation = randf_range(0, TAU)

	var scale_amount = randf_range(0.8, 1.3)
	scale = Vector2.ONE * scale_amount

	modulate.a = randf_range(0.75, 1.0)

	await get_tree().create_timer(lifetime).timeout

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)

	await tween.finished

	queue_free()
