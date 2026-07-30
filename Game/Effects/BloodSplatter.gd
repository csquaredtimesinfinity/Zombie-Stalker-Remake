extends Node2D

@export var lifetime := 10.0
@export var fade_time := 2.0

@export var scale_min := 0.9
@export var scale_max := 1.5

@export var modulate_alpha_min := 0.6
@export var modulate_alpha_max := 0.9

func _ready():
	rotation = randf_range(0, TAU)

	var scale_amount = randf_range(scale_min, scale_max)
	scale = Vector2.ONE * scale_amount

	modulate.a = randf_range(modulate_alpha_min, modulate_alpha_max)

	await get_tree().create_timer(lifetime).timeout

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)

	await tween.finished

	queue_free()
