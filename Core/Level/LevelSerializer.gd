class_name LevelSerializer

static func load_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Level not found: %s" % path)
		return {}
		
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON: %s" % path)
		return {}
		
	return data

static func save_level(path: String, level_data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(level_data, "\t"))
		file.close()
