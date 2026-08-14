extends Area2D

var id: String

func interact(player: PlayerController) -> void:
	if player.has_keys() && not WorldState.is_door_unlocked(id):
		SoundLibrary.player_opening_door_sfx()
		WorldState.unlock_door(id)
		player.remove_key()
		queue_free()
