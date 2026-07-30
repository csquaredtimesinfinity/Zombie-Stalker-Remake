class_name StateMachine
extends Node

var current_state : ZombieState

func change_state(new_state: ZombieState):
	if current_state:
		current_state.exit()
		
	current_state = new_state
	current_state.enter()
	
func update(delta):
	if current_state:
		current_state.update(delta)
		
func physics_update(delta):
	if current_state:
		current_state.physics_update(delta)
