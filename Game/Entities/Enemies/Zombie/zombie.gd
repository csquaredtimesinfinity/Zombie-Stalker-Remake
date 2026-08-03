extends CharacterBody2D
class_name Zombie

@export_category("Movement")
@export var move_speed: float = 40.0
@export var detection_radius: float = 100.0

@export_category("Combat")
@export var max_health: int = 100
@export var damage: int = 10

@export_category("Pathfinding")
@export var path_update_interval: float = 0.35
@export var waypoint_reach_distance: float = 3.0

enum Direction { 
	LEFT, 
	RIGHT,
	UP, 
	DOWN 
}

var id: String
var health: int
var player: Node2D

var zombie_direction = Direction.RIGHT
var zombie_moving = false
var dying = false

var path: Array[Vector2i] = []
var path_index := 0
var path_update_timer := 0.0

@onready var anim: AnimationPlayer = $ZombieAnimator/AnimationPlayer
@onready var attack_timer: Timer = $"Timer (for attacks)"
@onready var detect_area: Area2D = $Area2D
@onready var pathfinder = $"../../Navigation"

@export var knockback_strength: float = 160.0
@export var knockback_decay: float = 500.0

var knockback_velocity := Vector2.ZERO
var direction

func _ready():
	health = max_health
	
	# wait to make sure player is in scene first
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	add_to_group("enemies")
	
	anim.animation_finished.connect(_on_animation_finished)
	
func chase_player(player):
	var start_cell = pathfinder.world_to_cell(global_position)
	print(start_cell)
	var end_cell = pathfinder.world_to_cell(player.global_position)
	print(end_cell)
	
	path = pathfinder.find_path(start_cell, end_cell)
	path_index = 1
	print(path)
	
func _physics_process(delta: float) -> void:
	if dying:
		velocity = Vector2.ZERO
		return

	zombie_moving = false

	var movement_velocity := Vector2.ZERO

	if player:
		movement_velocity = get_chase_velocity(delta)

	knockback_velocity = knockback_velocity.move_toward(
		Vector2.ZERO,
		knockback_decay * delta
	)

	velocity = movement_velocity + knockback_velocity

	move_and_slide()
	
func get_chase_velocity(delta: float) -> Vector2:
	path_update_timer -= delta

	if path_update_timer <= 0.0:
		request_path()
		path_update_timer = path_update_interval

	if path.is_empty() or path_index >= path.size():
		return Vector2.ZERO

	var target_cell := path[path_index]
	var target_position : Vector2i = pathfinder.cell_to_world(target_cell)

	if global_position.distance_to(target_position) <= waypoint_reach_distance:
		path_index += 1
		return Vector2.ZERO

	var direction := global_position.direction_to(target_position)

	update_facing(direction)
	zombie_moving = true

	return direction * move_speed

func update_chase(delta: float) -> void:
	path_update_timer -= delta
	
	if path_update_timer <= 0.0:
		request_path()
		path_update_timer = path_update_interval
	
	follow_path()

func request_path() -> void:
	if player == null:
		return
	
	var start_cell: Vector2i = pathfinder.world_to_cell(global_position)
	var end_cell: Vector2i = pathfinder.world_to_cell(player.global_position)
	
	path = pathfinder.find_path(start_cell, end_cell)
	
	if path.size() > 1:
		path_index = 1
	else:
		path_index = 0

func follow_path() -> void:
	if path.is_empty():
		stop_moving()
		return
	
	if path_index >= path.size():
		stop_moving()
		return
	
	var target_cell := path[path_index]
	var target_position: Vector2i = pathfinder.cell_to_world(target_cell)
	
	var distance_to_target := global_position.distance_to(target_position)
	
	if distance_to_target <= waypoint_reach_distance:
		path_index += 1
		
		if path_index >= path.size():
			stop_moving()
			return
			
		target_cell = path[path_index]
		target_position = pathfinder.cell_to_world(target_cell)
		
	var direction := global_position.direction_to(target_position)
	
	velocity = direction * move_speed
	
	update_facing(direction)
	
	zombie_moving = true
	
func stop_moving() -> void:
	velocity = Vector2.ZERO
	zombie_moving = false
	
func update_facing(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		if direction.x < 0.0:
			zombie_direction = Direction.LEFT
		else:
			zombie_direction = Direction.RIGHT
	else:
		if direction.y < 0.0:
			zombie_direction = Direction.UP
		else:
			zombie_direction = Direction.DOWN

func take_damage(amount, hit_position, direction) -> void:
	if dying:
		return
	
	var knockback_direction :Vector2 = direction

	knockback_velocity = knockback_direction * knockback_strength
	
	# Modulate zombie to red
	modulate = Color.RED
	await get_tree().create_timer(0.05).timeout
	modulate = Color.WHITE
	
	# Spawn blood
	EffectsManager.spawn_blood(hit_position)
	await get_tree().create_timer(0.2).timeout
	
	if dying:
		return
		
	EffectsManager.spawn_blood_splatter(hit_position)
	
	health -= amount
	
	if health <= 0:
		die()
	else:
		SoundLibrary.play_zombie_hit_sound()

func die() -> void:
	if dying:
		return
	
	dying = true
	
	stop_moving()
	path.clear()

	anim.play("die")
	WorldState.mark_zombie_killed(id)
	SoundLibrary.play_zombie_kill_sound()
		
func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"die":
		queue_free()

		##navigation_agent.target_position = player.global_position
##
		##print("Reachable: ", navigation_agent.is_target_reachable()," | Finished: ", navigation_agent.is_navigation_finished())
		##navigation_agent.target_position = player.global_position
		#
		#if path.size() < 2:
			#return
		#
		#var target_cell = path[path_index]
		##print(global_position)
		#var target_position = pathfinder.cell_to_world(target_cell)
		##print(target_position)
		#var direction = global_position.direction_to(target_position)
		##print(direction)
		##var next_position = navigation_agent.get_next_path_position()
		##next_position.y -= 1
		##print(str(next_position))
		##var direction = (player.global_position - global_position).normalized()
		##var direction = global_position.direction_to(next_position)
		#velocity = direction * move_speed
		#
		#if global_position.distance_to(target_position) < 0:
			#path_index += 1
			#
			#if path_index > path.size():
				#path.clear()
		#
		#if direction.x < 0 && abs(direction.x) > abs(direction.y):
			#_set_zombie_moving(Direction.LEFT)
		#elif direction.x > 0  && abs(direction.x) > abs(direction.y):
			#_set_zombie_moving(Direction.RIGHT)
		#elif direction.y < 0 && abs(direction.x) < abs(direction.y):
			#_set_zombie_moving(Direction.UP)
		#elif direction.y > 0  && abs(direction.x) < abs(direction.y):
			#_set_zombie_moving(Direction.DOWN)
			#
	#move_and_slide()
#
#
#func _set_zombie_moving(direction) -> void:
	#zombie_direction = direction
	#zombie_moving = true
#
#func _on_body_entered(body: Node):
	#if body.is_in_group("player"):
		#player = body
		#attack_timer.start()
	#
#func _on_body_exited(body: Node):
	#if body == player:
		#player = null
		#attack_timer.stop()
	#
#func _on_attack_timeout():
	#pass
	##if player:
	##	player.take_damage(damage)
		#
#
#
#
	##queue_free()
