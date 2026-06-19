class_name LevelUtils

const TILE_SIZE := 16

static func vec2i_to_str(v: Vector2i) -> String:
	return "%d,%d" % [v.x, v.y]

static func str_to_vec2i(s: String) -> Vector2i:
	var parts = s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
	
static func cell_to_world(cell: String) -> Vector2:
	var vec: Vector2i = str_to_vec2i(cell)
	return Vector2(vec.x * TILE_SIZE, vec.y * TILE_SIZE)

static func id_for_entity(screen, cell, type) -> String:
	return "%s%s%s" % [screen, cell, type]
