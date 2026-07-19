extends Node

class_name SoundLibrary

enum Effect {
	GUN_FIRE,
	AMMO_PICKUP,
	COKE_PICKUP,
	KEY_PICKUP,
	ZOMBIE_HIT,
	BULLET_HITTING_WALL
}

const BASE_SOUND_EFFECTS_PATH = "res://Assets/Audio/SoundEffects/"

static var SOUNDS := {
	Effect.GUN_FIRE: preload(BASE_SOUND_EFFECTS_PATH + "gunshot.wav"),
	Effect.AMMO_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "ammo_pickup.wav"),
	Effect.COKE_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "coke_pickup.mp3"),
	Effect.KEY_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "key_pickup.mp3"),
	Effect.ZOMBIE_HIT: preload(BASE_SOUND_EFFECTS_PATH + "ZombieHit.wav"),
	Effect.BULLET_HITTING_WALL: preload(BASE_SOUND_EFFECTS_PATH + "BulletHittingWall.mp3")
}

static func play_gun_fire_sound() -> void:
	_play(Effect.GUN_FIRE)

static func play_ammo_pickup_sound() -> void:
	_play(Effect.AMMO_PICKUP)

static func play_coke_pickup_sound() -> void:
	_play(Effect.COKE_PICKUP)

static func play_key_pickup_sound() -> void:
	_play(Effect.KEY_PICKUP)

static func play_zombie_hit_sound() -> void:
	_play(Effect.ZOMBIE_HIT)

static func play_bullet_hitting_wall_sound() -> void:
	_play(Effect.BULLET_HITTING_WALL)

static func _play(effect: Effect) -> void:
	if not AudioManager:
		push_warning("AudioManager not found!")
		return
	AudioManager.play(SOUNDS[effect])
