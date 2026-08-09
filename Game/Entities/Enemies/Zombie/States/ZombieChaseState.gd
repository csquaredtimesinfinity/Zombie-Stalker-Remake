class_name ZombieChaseState
extends ZombieState

func enter():
	print("%s: Entering Chase" % zombie.id)
	zombie.stop_moving()

func exit():
	print("Exiting Chase")
	
func physics_update(delta):
	if zombie.can_lunge():
		zombie.change_state("windup")
		return
		
	zombie.update_chase(delta)
	
