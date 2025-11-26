extends Area2D

var id: String

func _on_area_entered(area: Area2D) -> void:
	var player : PlayerController = area.get_owner()
	if player.has_keys():
		player.remove_key()
		
		queue_free()
