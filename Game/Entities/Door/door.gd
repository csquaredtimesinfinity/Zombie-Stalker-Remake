extends Area2D

var id: String

func interact(player: PlayerController) -> void:
	print("INTERACT")
	if player.has_keys() && not WorldState.is_door_unlocked(id):
		WorldState.unlock_door(id)
		player.remove_key()
		queue_free()

#func _on_area_entered(area: Area2D) -> void:
	#print(area.name)
	#var player : PlayerController = area.get_owner()
	#if player.has_keys() && not WorldState.is_door_unlocked(id):
		#WorldState.unlock_door(id)
		#player.remove_key()
		#queue_free()
