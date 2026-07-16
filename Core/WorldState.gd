extends Node

# Track pickups and doors unlocked
var collected_pickups: Dictionary = {}
var doors_unlocked: Dictionary = {}
var zombies_killed: Dictionary = {}

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

func clear_zombies_killed() -> void:
	zombies_killed.clear()
	
func mark_zombie_killed(id: String) -> void:
	zombies_killed[id] = true

func is_zombie_killed(id: String) -> bool:
	return zombies_killed.has(id)
	
func reset_world() -> void:
	clear_collected_pickups()
	clear_doors_unlocked()
	clear_zombies_killed()
	
