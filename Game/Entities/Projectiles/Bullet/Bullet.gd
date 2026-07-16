extends Area2D

class_name Bullet

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 5.0

var time_alive: float = 0.0

func _ready() -> void:
	connect("area_entered", _on_area_entered)

func _physics_process(delta: float) -> void:
	# Move
	var next_position = position + direction * speed * delta

	if _tile_is_solid(next_position):
		queue_free()
		return
	
	position = next_position
	
	# Lifetime kill
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _tile_is_solid(world_pos: Vector2) -> bool:
	var tilemap: TileMapLayer = get_tree().current_scene.get_node("SubViewport/Level/TileMapLayer") # adjust path if needed
	var cell := tilemap.local_to_map(world_pos)
	var tile_data := tilemap.get_cell_tile_data(cell) # 0 = your main layer

	if tile_data == null:
		return false

	return tile_data.get_collision_polygons_count(0) > 0

func _on_area_entered(area: Area2D) -> void:
	print(area.name)
		
	var zombie = area.get_parent()
	# Hit zombie
	if zombie.is_in_group("enemies"):
		print("hit")
		if zombie.has_method("take_damage"):
			var blood = preload("res://Game/Effects/BloodEffect.tscn").instantiate()
			zombie.get_parent().get_parent().add_child(blood)
			blood.global_position = global_position
			print(str(global_position))
			blood.start()
			zombie.take_damage()
		
		queue_free()

		### Spawn blood effect IF you add one later
		#if area and area.collider.is_in_group("enemies"):
			#area.collider.spawn_blood(area.position)
