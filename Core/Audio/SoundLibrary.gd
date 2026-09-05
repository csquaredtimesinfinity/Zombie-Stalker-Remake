extends Node

class_name SoundLibrary

enum Effect {
	GUN_FIRE,
	AMMO_PICKUP,
	COKE_PICKUP,
	KEY_PICKUP,
	ZOMBIE_HIT,
	BULLET_HITTING_WALL,
	ZOMBIE_KILL,
	ZOMBIE_MOAN,
	OPENING_DOOR,
	ZOMBIE_BULLET_IMPACT
}

const BASE_SOUND_EFFECTS_PATH = "res://Assets/Audio/SoundEffects/"

static var SOUNDS := {
	Effect.GUN_FIRE: preload(BASE_SOUND_EFFECTS_PATH + "gunshot.wav"),
	Effect.AMMO_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "AmmoPickup.wav"),
	Effect.COKE_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "CokePickup.mp3"),
	Effect.KEY_PICKUP: preload(BASE_SOUND_EFFECTS_PATH + "KeyPickup.mp3"),
	Effect.ZOMBIE_HIT: preload(BASE_SOUND_EFFECTS_PATH + "ZombieKill.wav"),
	Effect.BULLET_HITTING_WALL: preload(BASE_SOUND_EFFECTS_PATH + "BulletHittingWall.mp3"),
	Effect.ZOMBIE_KILL: preload(BASE_SOUND_EFFECTS_PATH + "ZombieHit.wav"),
	Effect.ZOMBIE_MOAN: preload(BASE_SOUND_EFFECTS_PATH + "ZombieMoan.wav"),
	Effect.OPENING_DOOR: preload(BASE_SOUND_EFFECTS_PATH + "UnlockingDoor.mp3"),
	Effect.ZOMBIE_BULLET_IMPACT: preload(BASE_SOUND_EFFECTS_PATH + "hit.wav")
}

static func play_gun_fire_sfx() -> void:
	_play(Effect.GUN_FIRE)

static func play_ammo_pickup_sfx() -> void:
	_play(Effect.AMMO_PICKUP)

static func play_coke_pickup_sfx() -> void:
	_play(Effect.COKE_PICKUP)

static func play_key_pickup_sfx() -> void:
	_play(Effect.KEY_PICKUP)

static func play_zombie_hit_sfx() -> void:
	_play(Effect.ZOMBIE_HIT)
	_play(Effect.ZOMBIE_BULLET_IMPACT)

static func play_bullet_hitting_wall_sfx() -> void:
	_play(Effect.BULLET_HITTING_WALL)
	
static func play_zombie_kill_sfx() -> void:
	_play(Effect.ZOMBIE_KILL)

static func play_zombie_moan_sfx() -> void:
	_play(Effect.ZOMBIE_MOAN)

static func player_opening_door_sfx() -> void:
	_play(Effect.OPENING_DOOR)

static func _play(effect: Effect) -> void:
	if not AudioManager:
		push_warning("AudioManager not found!")
		return
	AudioManager.play(SOUNDS[effect])
