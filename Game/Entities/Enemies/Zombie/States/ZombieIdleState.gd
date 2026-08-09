class_name ZombieIdleState
extends ZombieState

func enter():
	zombie.stop_moving()

func exit():
	print("Exiting Chase")
	
func physics_update(delta):
	zombie.velocity = Vector2.ZERO
