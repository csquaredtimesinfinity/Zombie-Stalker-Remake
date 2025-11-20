extends Area2D

class_name Bullet

@export var speed: float = 400.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 1.0

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
	# Hit zombie
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(1)

		## Spawn blood effect IF you add one later
		if area and area.collider.is_in_group("enemies"):
			area.collider.spawn_blood(area.position)
