extends Area2D

@export var speed: float = 40.0
var direction: Vector2

func _ready() -> void:
	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("body_entered", Callable(self, "_on_body_entered"))
	
func _physics_process(delta):
	position += direction * speed * delta
	if $RayCast2D.is_colliding():
		queue_free()
	
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(1)
	queue_free()

func _on_area_entered(area):
	queue_free() # destroy bullet
