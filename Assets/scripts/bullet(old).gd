extends Area2D

class_name Bullet

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 1.0

var time_alive: float = 0.0

func _ready() -> void:
	connect("area_entered", _on_area_entered)

func _physics_process(delta: float) -> void:
	# Move
	position += direction * speed * delta

	# Lifetime kill
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Hit zombie
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(1)

		## Spawn blood effect IF you add one later
		if area and area.collider.is_in_group("enemies"):
			area.collider.spawn_blood(area.position)

		queue_free()

	# Hit wall (tiles that should block bullets)
	if area.is_in_group("bullet_block"):
		queue_free()
