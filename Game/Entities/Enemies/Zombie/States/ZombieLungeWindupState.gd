class_name ZombieLungeWindupState
extends ZombieState

var pulse_time := 0.0

func enter():
	print("%s: Entering Lunge Windup" % zombie.id)
	
	zombie.stop_moving()
	
	zombie.lunge_timer = zombie.lunge_windup_time + randf_range(0.0, 0.25)
	pulse_time = 0.0
	
	if zombie.player:
		var direction := zombie.global_position.direction_to(
			zombie.player.global_position
		)
		
		zombie.update_facing(direction)
	
func exit():
	print("%s: Exiting Lunge Windup" % zombie.id)
	
	zombie.modulate = Color.WHITE

func physics_update(delta):
	zombie.lunge_timer -= delta
	pulse_time += delta
	
	var progress := 1.0 - (zombie.lunge_timer / zombie.lunge_windup_time)
	var pulse_speed: float = lerp(8.0, 30.0, progress)
	
	# Pulse between white and red
	var pulse := (sin(pulse_time * pulse_speed) + 1.0) / 2.0
	zombie.modulate = Color.WHITE.lerp(Color.GOLDENROD, pulse)
	
	if zombie.lunge_timer <= 0.0:
		zombie.change_state("lunge")
