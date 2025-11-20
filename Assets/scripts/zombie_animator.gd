extends Node2D

@export var zombie : Zombie
@export var animation_player : AnimationPlayer
@export var sprite : Sprite2D

func _process(delta: float) -> void:
	if zombie.zombie_moving:
		match zombie.zombie_direction:
			zombie.Direction.LEFT:
				animation_player.play("move_left")
			zombie.Direction.RIGHT:
				animation_player.play("move_right")
			zombie.Direction.DOWN:
				animation_player.play("move_down")
			zombie.Direction.UP:
				animation_player.play("move_up")
	else:
		animation_player.stop()
