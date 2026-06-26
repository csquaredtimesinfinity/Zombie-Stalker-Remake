extends CanvasLayer

signal tile_selected(tile_id: int)
signal entity_selected(entity_id: int)
signal move_screen(direction: Vector2i)
signal save_level

@onready var tile_selector: OptionButton = $%TileSelector
@onready var entity_selector: OptionButton = $%EntitySelector
@onready var current_screen_label: Label = $%CurrentScreenCoords
@onready var left_button: Button = $%LeftButton
@onready var right_button: Button = $%RightButton
@onready var up_button: Button = $%UpButton
@onready var down_button: Button = $%DownButton
@onready var save_button: Button = $%SaveLevel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var categories = {}
	# Initialize TileSelector dropdown control
	tile_selector.clear()
	# group everything by category
	for type in TileDatabase.DATA:
		var entity = TileDatabase.DATA[type]
		var category = entity.get("category", "uncategorized")
		
		if not categories.has(category):
			categories[category] = []
			
		categories[category].append({"type": type, "data": entity})
	
	# build UI
	for category in categories.keys():
		tile_selector.add_separator(category.capitalize())
		
		for entry in categories[category]:
			tile_selector.add_icon_item(entry.data.icon, entry.data.name, entry.type)
	
	# Initialize PickupSelector dropdown control
	entity_selector.clear()
	entity_selector.add_item("Empty", EntityDatabase.EntityType.EMPTY)
	
	categories = {}
	
	# group everything by category
	for type in EntityDatabase.DATA:
		var entity = EntityDatabase.DATA[type]
		var category = entity.get("category", "uncategorized")
		
		if not categories.has(category):
			categories[category] = []
			
		categories[category].append({"type": type, "data": entity})
	
	# build UI
	for category in categories.keys():
		entity_selector.add_separator(category.capitalize())
		
		for entry in categories[category]:
			entity_selector.add_icon_item(entry.data.icon, entry.data.name, entry.type)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_screen_button_states(current: Vector2i, map_screens: Vector2i) -> void:
	left_button.disabled = current.x <= 0
	right_button.disabled = current.x >= map_screens.x - 1
	up_button.disabled = current.y <= 0
	down_button.disabled = current.y >= map_screens.y - 1
	current_screen_label.text = "%d, %d" % [current.x, current.y]
	

func _on_tile_selector_item_selected(index: int) -> void:
	var tile_id = tile_selector.get_item_id(index)
	emit_signal("tile_selected", tile_id)


func _on_entity_selector_item_selected(index: int) -> void:
	var entity_id = entity_selector.get_item_id(index)
	emit_signal("entity_selected", entity_id)


func _on_left_button_pressed() -> void:
	emit_signal("move_screen", Vector2i(-1, 0))


func _on_right_button_pressed() -> void:
	emit_signal("move_screen", Vector2i(1, 0))


func _on_up_button_pressed() -> void:
	emit_signal("move_screen", Vector2i(0, -1))


func _on_down_button_pressed() -> void:
	emit_signal("move_screen", Vector2i(0, 1))


func _on_save_level_pressed() -> void:
	emit_signal("save_level")
