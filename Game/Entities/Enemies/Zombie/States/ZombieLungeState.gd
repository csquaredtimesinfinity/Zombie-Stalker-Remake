class_name ZombieLungeState
extends ZombieState

func enter():
	print("%s: Entering Lunge" % zombie.id)
	
	zombie.lunge_timer = zombie.lunge_duration
	
	if zombie.player:
		zombie.lunge_direction = zombie.global_position.direction_to(
			zombie.player.global_position
		)
		
		zombie.update_facing(zombie.lunge_direction)

func exit():
	print("%s: Exiting Lunge" % zombie.id)
	
	zombie.lunge_cooldown_timer = zombie.lunge_cooldown
	zombie.stop_moving()
	
func physics_update(delta):
	zombie.lunge_timer -= delta
	
	zombie.velocity = zombie.lunge_direction * zombie.lunge_speed
	zombie.zombie_moving = true
	
	if zombie.lunge_timer <= 0.0:
		zombie.change_state("chase")
	
