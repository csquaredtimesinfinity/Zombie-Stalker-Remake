extends CharacterBody2D

class_name PlayerController

@export var speed: float = 120.0  # movement speed in pixels per second
@export var max_health: int = 100

const TILE_SIZE = 16
const SCREEN_TILES = Vector2i(20, 10)
const SCREEN_SIZE = SCREEN_TILES * TILE_SIZE

enum Direction { LEFT, RIGHT, UP, DOWN }
var player_direction = Direction.RIGHT
var space_pressed = false

signal screen_transition(direction: Vector2)

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	if Input.is_key_pressed(KEY_SPACE) && !space_pressed:
		AudioManager.play("res://Assets/sound_effects/balloon_pop.wav")
		space_pressed = true
	else:
		space_pressed = false
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		player_direction = Direction.UP
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
		player_direction = Direction.DOWN
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		player_direction = Direction.LEFT
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		player_direction = Direction.RIGHT
	
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	
	
			
	move_and_slide()
	
	# Edge check
	if position.x < TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.LEFT)
	elif position.x >= SCREEN_SIZE.x - TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.RIGHT)
	elif position.y < TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.UP)
	elif position.y >= SCREEN_SIZE.y - TILE_SIZE / 2:
		emit_signal("screen_transition", Vector2.DOWN)
	
