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
<<<<<<< HEAD
var zombie_moving = false
=======
>>>>>>> 8d1fed58e16fde2f139eacff12a161731efb5a0c

func _ready() -> void:
	health = max_health
	
	detect_area.connect("body_entered", _on_body_entered)
	detect_area.connect("body_exited", _on_body_exited)
	attack_timer.connect("timeout", _on_attack_timeout)
	
	
func _physics_process(delta: float) -> void:
<<<<<<< HEAD
	zombie_moving = false
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		
		if direction.x < 0 && abs(direction.x) > abs(direction.y):
			_set_zombie_moving(Direction.LEFT)
		elif direction.x > 0  && abs(direction.x) > abs(direction.y):
			_set_zombie_moving(Direction.RIGHT)
		elif direction.y < 0 && abs(direction.x) < abs(direction.y):
			_set_zombie_moving(Direction.UP)
		elif direction.y > 0  && abs(direction.x) < abs(direction.y):
			_set_zombie_moving(Direction.DOWN)
		
=======
	
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
>>>>>>> 8d1fed58e16fde2f139eacff12a161731efb5a0c
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	
<<<<<<< HEAD
func _set_zombie_moving(direction) -> void:
	zombie_direction = direction
	zombie_moving = true
	
func spawn_blood(global_pos: Vector2) -> void:
	var blood: GPUParticles2D = preload(
		"res://Assets/scenes/particle_effects/BloodSplatter.tscn").instantiate()
	blood.global_position = global_pos
	get_tree().current_scene.add_child(blood)
	blood.emitting = true
	
=======
>>>>>>> 8d1fed58e16fde2f139eacff12a161731efb5a0c
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
