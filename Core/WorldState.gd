extends Node

# Track pickups and doors unlocked
var collected_pickups: Dictionary = {}
var doors_unlocked: Dictionary = {}

func is_pickup_collected(id: String) -> bool:
	return collected_pickups.has(id)
	
func mark_pickup_collected(id: String) -> void:
	print("pickup collected: %s" % id)
	collected_pickups[id] = true
	
func clear_collected_pickups() -> void:
	collected_pickups.clear()
	
func is_door_unlocked(id: String) -> bool:
	return doors_unlocked.has(id)

func unlock_door(id: String) -> void:
	doors_unlocked[id] = true

func clear_doors_unlocked() -> void:
	doors_unlocked.clear()
