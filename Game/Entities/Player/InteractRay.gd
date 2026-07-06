extends RayCast2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	self.force_raycast_update()
	
	if self.is_colliding():
		print("RAY IS COLLIDING")
		var hit = self.get_collider()
		var object = hit.get_parent()
		if object and object.has_method("interact"):
			print("HIT")
			var player = get_owner() # or your player reference
			object.interact(player)
