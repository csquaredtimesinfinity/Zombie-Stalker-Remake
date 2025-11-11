extends Node

class_name SoundFX

static func play_gun_fire_sound() -> void:
	_play("res://Assets/sound_effects/gunshot.wav")

static func play_ammo_pickup_sound() -> void:
	_play("res://Assets/sound_effects/ammo_pickup.wav")

static func play_coke_pickup_sound() -> void:
	_play("res://Assets/sound_effects/coke_pickup.mp3")

static func play_key_pickup_sound() -> void:
	_play("res://Assets/sound_effects/key_pickup.mp3")

static func _play(path: String) -> void:
	if not AudioManager:
		push_warning("AudioManager not found!")
		return
	AudioManager.play(path)
