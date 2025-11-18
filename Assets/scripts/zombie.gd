extends CharacterBody2D
class_name Zombie

@export var move_speed: float = 40.0
@export var max_health: int = 100
@export var damage: int = 10
@export var detection_radius: float = 100.0

var health: int
var player: Node2D = null

@onready var anim: AnimationPlayer = $ZombieAnimator/AnimationPlayer
@onready var attack_timer: Timer = $"Timer (for attacks)"
@onready var detect_area: Area2D = $Area2D

enum Direction { LEFT, RIGHT, UP, DOWN }
var zombie_direction = Direction.RIGHT

func _ready() -> void:
	health = max_health
	
	detect_area.connect("body_entered", _on_body_entered)
	detect_area.connect("body_exited", _on_body_exited)
	attack_timer.connect("timeout", _on_attack_timeout)
	
	
func _physics_process(delta: float) -> void:
	
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		if direction.y < 0:
			zombie_direction = Direction.UP
		elif direction.y > 0:
			zombie_direction = Direction.DOWN
		elif direction.x < 0:
			zombie_direction = Direction.LEFT
		elif direction.x > 0:
			zombie_direction = Direction.RIGHT
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		player = body
		attack_timer.start()
	
func _on_body_exited(body: Node):
	if body == player:
		player = null
		attack_timer.stop()
	
func _on_attack_timeout():
	return
	if player:
		player.take_damage(damage)
		
func take_damage(amount: int) -> void:
	health -= damage
	if health <= 0:
		die()
	else:
		anim.play("hit")

func die() -> void:
	anim.play("die")
	queue_free()
