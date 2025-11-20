extends CharacterBody2D

class_name PlayerController

@export var speed: float = 120.0  # movement speed in pixels per second
@export var max_health: int = 100
@export var max_ammo: int = 300
var health = 10 # max_health
var ammo = 50
var keys = 0

@export var bullet_scene: PackedScene = preload("res://Assets/scenes/bullet.tscn")
@export var fire_rate: float = 0.25
var shoot_cooldown: float = 0.25
var muzzle_offsets = {
	Direction.UP: Vector2(0, -8),
	Direction.DOWN: Vector2(0, 8),
	Direction.LEFT: Vector2(-8, -2),
	Direction.RIGHT: Vector2(8, -2)
}

const TILE_SIZE = 16
const SCREEN_TILES = Vector2i(20, 10)
const SCREEN_SIZE = SCREEN_TILES * TILE_SIZE

enum Direction { LEFT, RIGHT, UP, DOWN }
var player_direction = Direction.RIGHT
var player_moving = false
var space_pressed = false
var can_shoot: bool = true

signal health_changed(value)
signal ammo_changed(value)
signal keys_changed(value)
signal screen_transition(direction: Vector2)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("fire"):
		shoot()
		
	handle_input()
	
	# Edge check
	if position.x < TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.LEFT)
	elif position.x >= SCREEN_SIZE.x - TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.RIGHT)
	elif position.y < TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.UP)
	elif position.y >= SCREEN_SIZE.y - TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.DOWN)
		
	position.x = clamp(position.x, TILE_SIZE / 2, SCREEN_SIZE.x - TILE_SIZE / 2)
	position.y = clamp(position.y, TILE_SIZE / 2, SCREEN_SIZE.y - TILE_SIZE / 2)

func handle_input() -> void:
	var input_vector = Vector2.ZERO
	player_moving = false
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		player_direction = Direction.UP
		player_moving = true
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
		player_direction = Direction.DOWN
		player_moving = true
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		player_direction = Direction.LEFT
		player_moving = true
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		player_direction = Direction.RIGHT
		player_moving = true
	
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
			
	move_and_slide()

func shoot() -> void:
	if not can_shoot || ammo <= 0:
		return
	
	ammo -= 1
	ammo_changed.emit(ammo)
		
	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
	
	# Spawn bullet
	var bullet = bullet_scene.instantiate()
	var spawn_offset = muzzle_offsets.get(player_direction, Vector2.ZERO)
	bullet.position = position + spawn_offset
	
	# Play gun fire sound effect
	SoundFX.play_gun_fire_sound()
	
	match player_direction:
		Direction.UP:
			bullet.direction = Vector2.UP
		Direction.DOWN:
			bullet.direction = Vector2.DOWN
		Direction.LEFT:
			bullet.direction = Vector2.LEFT
		Direction.RIGHT:
			bullet.direction = Vector2.RIGHT
			
	# Add bullet to the scene by adding it to the parent node of the player
	get_parent().add_child(bullet)
		
func add_health(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)

func add_ammo(amount: int) -> void:
	ammo = clamp(ammo + amount, 0, max_ammo)
	emit_signal("ammo_changed", ammo)
	
func add_key() -> void:
	keys += 1
	emit_signal("keys_changed", keys)
	
func _on_detect_pickups_area_entered(area: Area2D) -> void:
	var should_pickup = false
	if area.is_in_group("pickups"):
		if area.has_method("apply_pickup"):
			should_pickup = area.apply_pickup(self)
			# remove pickup if player was able to pickup item
			if should_pickup:
				area.queue_free()
