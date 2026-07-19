extends CharacterBody2D
class_name Zombie

@export var move_speed: float = 40.0
@export var max_health: int = 100
@export var damage: int = 10
@export var detection_radius: float = 100.0

var id: String
var health: int
var player: Node2D = null

@onready var anim: AnimationPlayer = $ZombieAnimator/AnimationPlayer
@onready var attack_timer: Timer = $"Timer (for attacks)"
@onready var detect_area: Area2D = $Area2D
@onready var health_label: Label = $Label

enum Direction { LEFT, RIGHT, UP, DOWN }
var zombie_direction = Direction.RIGHT
var zombie_moving = false
var dying = false

func _ready() -> void:
	health = max_health
	#health_label.text = "Health: " + str(health)
	detect_area.connect("body_entered", _on_body_entered)
	detect_area.connect("body_exited", _on_body_exited)
	attack_timer.connect("timeout", _on_attack_timeout)
	
	add_to_group("enemies")
	
	
func _physics_process(delta: float) -> void:
	if dying:
		await anim.animation_finished
		queue_free()
		return
	
	zombie_moving = false
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed * randf()
		
		if direction.x < 0 && abs(direction.x) > abs(direction.y):
			_set_zombie_moving(Direction.LEFT)
		elif direction.x > 0  && abs(direction.x) > abs(direction.y):
			_set_zombie_moving(Direction.RIGHT)
		elif direction.y < 0 && abs(direction.x) < abs(direction.y):
			_set_zombie_moving(Direction.UP)
		elif direction.y > 0  && abs(direction.x) < abs(direction.y):
			_set_zombie_moving(Direction.DOWN)
			
	move_and_slide()
		
func _set_zombie_moving(direction) -> void:
	zombie_direction = direction
	zombie_moving = true

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		player = body
		attack_timer.start()
	
func _on_body_exited(body: Node):
	if body == player:
		player = null
		attack_timer.stop()
	
func _on_attack_timeout():
	pass
	#if player:
	#	player.take_damage(damage)
		
func take_damage(amount, hit_position) -> void:
	if dying:
		return
	
	# Modulate zombie to red
	modulate = Color.RED
	await get_tree().create_timer(0.05).timeout
	modulate = Color.WHITE
	
	# Spawn blood
	EffectsManager.spawn_blood(hit_position)
	await get_tree().create_timer(0.2).timeout
	EffectsManager.spawn_blood_splatter(hit_position)
	
	SoundLibrary.play_zombie_hit_sound()
	
	health -= amount
	if health <= 0:
		die()
	else:
		pass #anim.play("hit")
	#health_label.text = "Health: " + str(health)

func die() -> void:
	dying = true
	zombie_moving = false
	anim.play("die")
	WorldState.mark_zombie_killed(id)
	#queue_free()
