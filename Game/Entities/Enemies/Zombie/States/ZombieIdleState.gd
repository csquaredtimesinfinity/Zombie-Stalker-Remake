class_name ZombieIdleState
extends ZombieState

var timer := 0.0

func enter():
	print("Entering Idle")
	zombie.stop_moving()
	timer = 0.0

func exit():
	print("Exiting Chase")
	
func physics_update(delta):
	zombie.velocity = Vector2.ZERO
	
	timer += delta
	
	if timer >= zombie.idle_time:
		zombie.change_state("chase")
