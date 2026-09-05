extends Node

const BLOOD = preload("res://Game/Effects/BloodEffect.tscn")
const BLOOD_SPLATTER = preload("res://Game/Effects/BloodSplatter.tscn")

var effects_layer: Node

func set_effects_layer(layer):
	effects_layer = layer
	
func spawn_blood(hit_position, color=Color.RED):
	var blood: Node2D = BLOOD.instantiate()
	
	if effects_layer:
		effects_layer.add_child(blood)
	else:
		var scene_root = get_tree().root
		scene_root.add_child(blood)
	
	# Set color of particles
	var particles: GPUParticles2D = blood.get_node("GPUParticles2D")
	var particle_material := particles.process_material as ParticleProcessMaterial
	particle_material.color = color
	
	# Set position
	blood.global_position = hit_position
	
	blood.start()

func spawn_blood_splatter(hit_position, color = Color.RED):
	var blood_splatter: Node2D = BLOOD_SPLATTER.instantiate()
	
	if effects_layer:
		effects_layer.add_child(blood_splatter)
	else:
		var scene_root = get_tree().root
		scene_root.add_child(blood_splatter)
	blood_splatter.modulate = color
	blood_splatter.global_position = Vector2i(hit_position.x, hit_position.y+8)

func spawn_blood_effect(hit_position: Vector2i, splatter_timer: float = 0.5, color = Color.from_rgba8(180,0,0)):
	color.a = randf_range(0.7, 1.0)
# Spawn blood
	spawn_blood(hit_position, color)
	
	var timer := Timer.new()
	effects_layer.add_child(timer)
	
	timer.wait_time = splatter_timer
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(effects_layer):
			spawn_blood_splatter(hit_position, color)
		timer.queue_free()
	)
	
	timer.start()
