class_name ChaseState
extends ZombieState

func enter():
	print("Entering Chase")
	zombie.stop_moving()

func exit():
	print("Exiting Chase")
	
func physics_update(delta):
	zombie.update_chase(delta)
	
	#zombie.zombie_moving = false
#
	#var movement_velocity := Vector2.ZERO
#
	#if zombie.player:
		#movement_velocity = get_chase_velocity(delta)
