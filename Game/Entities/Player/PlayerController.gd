extends CharacterBody2D

class_name PlayerController

@export var speed2: float = 90.0  # movement speed in pixels per second
@export var max_health: int = 100
@export var max_ammo: int = 300

@onready var interact_ray := $InteractRay
@onready var hitbox: Area2D = $HitBox

var health = max_health # max_health
var ammo = 100
var keys = 0

const BULLET_SCENE: PackedScene = preload("res://Game/Entities/Projectiles/Bullet/Bullet.tscn")
#@export var fire_rate: float = 0.75
var shoot_cooldown: float = 0.10
var muzzle_offsets = {
	Direction.UP: Vector2(0, -8),
	Direction.DOWN: Vector2(0, 8),
	Direction.LEFT: Vector2(-8, 0),
	Direction.RIGHT: Vector2(8, 0)
}

var facing = {
	Direction.UP: Vector2.UP,
	Direction.DOWN: Vector2.DOWN,
	Direction.LEFT: Vector2.LEFT,
	Direction.RIGHT: Vector2.RIGHT
}

const INTERACT_RAY_LENGTH = 9

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
signal player_died

func _ready() -> void:
	interact_ray.target_position = facing[player_direction] * INTERACT_RAY_LENGTH
	
	add_to_group("player")
	hitbox.add_to_group("player_hitbox")

func _draw():
	if interact_ray.enabled:
		pass# draw_line(Vector2.ZERO, interact_ray.target_position, Color.RED, 2)

func _physics_process(delta: float) -> void:
	# update ray cast to point in direction that the player is facing
	interact_ray.target_position = facing[player_direction] * INTERACT_RAY_LENGTH
	queue_redraw()
	
	handle_input()
	
	# Edge check
	if position.x < TILE_SIZE / 2 - 8:
		emit_signal("screen_transition", Vector2.LEFT)
	elif position.x >= SCREEN_SIZE.x - TILE_SIZE / 2 + 8:
		emit_signal("screen_transition", Vector2.RIGHT)
	elif position.y < TILE_SIZE / 2 - 8:
		emit_signal("screen_transition", Vector2.UP)
	elif position.y >= SCREEN_SIZE.y - TILE_SIZE / 2 + 8:
		emit_signal("screen_transition", Vector2.DOWN)
		
	position.x = clamp(position.x, TILE_SIZE / 2 - 8, SCREEN_SIZE.x - TILE_SIZE / 2 + 8)
	position.y = clamp(position.y, TILE_SIZE / 2 - 8, SCREEN_SIZE.y - TILE_SIZE / 2 + 8)

func handle_input() -> void:
	var input_vector = Vector2.ZERO
	player_moving = false
	
	if Input.is_action_pressed("fire"):
		shoot()

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
	velocity = input_vector * speed2
	
	move_and_slide()

func shoot() -> void:
	if not can_shoot || ammo <= 0:
		return
	
	# update ammo count
	ammo -= 1
	ammo_changed.emit(ammo)
		
	can_shoot = false
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true
	
	# Spawn bullet
	var bullet = BULLET_SCENE.instantiate()
	var spawn_offset = muzzle_offsets.get(player_direction, Vector2.ZERO)
	bullet.position = position + spawn_offset
	
	# Play gun fire sound effect
	SoundLibrary.play_gun_fire_sfx()
	
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
	
func remove_key() -> void:
	keys -= 1
	emit_signal("keys_changed", keys)
	
func has_keys() -> bool:
	return keys > 0
	
func _on_detect_pickups_area_entered(pickup: Area2D) -> void:
	var should_pickup = false
	if pickup.has_method("apply_pickup"):
		print("has apply_pickup method: " + pickup.name)
		should_pickup = pickup.apply_pickup(self)
		# remove pickup if player was able to pickup item
		if should_pickup:
			pickup.queue_free()

func take_damage(damage: int) -> void:
	health -= damage
	
	if health <= 0:
		player_died.emit()
		return
		
	# Modulate red when taking damage
	modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	modulate = Color.WHITE
	
	# spawn blood effect
	EffectsManager.spawn_blood_effect(position)
	
	# emit signal that health has changed so HUD will be updated
	emit_signal("health_changed", health)
	
