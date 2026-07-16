extends Node2D

@onready var particles = $GPUParticles2D

# Called when the node enters the scene tree for the first time.
func start():
	particles.restart()
	particles.emitting = true
	await get_tree().create_timer(particles.lifetime).timeout
	queue_free()
