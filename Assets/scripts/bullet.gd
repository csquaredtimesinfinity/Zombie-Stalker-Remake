extends CharacterBody2D

@export var speed: float = 400.0
var direction: Vector2

func _ready() -> void:
	velocity = direction * speed
	print(velocity)
	
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	
	if collision || \
			position.x < 0 || position.x > 320 || \
			position.y < 0 || position.y > 160:
		queue_free()  # destroy bullet on hit
