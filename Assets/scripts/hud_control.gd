extends Control

func _ready() -> void:
	# Fix HUD to bottom of screen
	anchor_left = 0
	anchor_right = 1
	anchor_top = 1
	anchor_bottom = 1
	
	# Define height (40px) and zero horizontal padding
	offset_left = 0
	offset_right = 0
	offset_top = -40
	offset_bottom = 0
	
	size = Vector2(320, 40)
	#modulate = Color(0.1, 0.1, 0.1, 1) # solid dark gray background
