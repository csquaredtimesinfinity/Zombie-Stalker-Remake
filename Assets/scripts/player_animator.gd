extends Node2D

@export var player_controller : PlayerController
@export var animation_player : AnimationPlayer
@export var sprite : Sprite2D

func _process(delta: float) -> void:
	if abs(player_controller.velocity.x) > 0 || abs(player_controller.velocity.y) > 0:
		if player_controller.player_direction == player_controller.Direction.LEFT:
			animation_player.play("move_left")
		if player_controller.player_direction == player_controller.Direction.RIGHT:
			animation_player.play("move_right")
		if player_controller.player_direction == player_controller.Direction.DOWN:
			animation_player.play("move_down")
		if player_controller.player_direction == player_controller.Direction.UP:
			animation_player.play("move_up")
	else:
		animation_player.stop()
