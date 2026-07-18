extends Node

const BLOOD = preload("res://Game/Effects/BloodEffect.tscn")
const BLOOD_SPLATTER = preload("res://Game/Effects/BloodSplatter.tscn")

var effects_layer: Node

func set_effects_layer(layer):
	effects_layer = layer
	
func spawn_blood(hit_position):
	var blood = BLOOD.instantiate()
	
	if effects_layer:
		print("Adding blood to effects layer: %s" % str(effects_layer))
		effects_layer.add_child(blood)
	else:
		var scene_root = get_tree().root
		print("Adding blood to current scene root: %s" % str(scene_root))
		scene_root.add_child(blood)
	
	blood.global_position = hit_position
	blood.start()

func spawn_blood_splatter(hit_position):
	var blood_splatter = BLOOD_SPLATTER.instantiate()
	
	if effects_layer:
		effects_layer.add_child(blood_splatter)
	else:
		var scene_root = get_tree().root
		scene_root.add_child(blood_splatter)
	
	blood_splatter.global_position = Vector2i(hit_position.x, hit_position.y+8)
