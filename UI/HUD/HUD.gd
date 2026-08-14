extends CanvasLayer

@onready var root_control: Control = $Control

@onready var health_label = $Control/HealthLabel
@onready var ammo_label = $Control/AmmoLabel
@onready var keys_label = $Control/KeyLabel

func update_health(value: int) -> void:
	health_label.text = "Health: %d" % value

func update_ammo(value: int) -> void:
	ammo_label.text = "Ammo: %d" % value

func update_keys(value: int) -> void:
	keys_label.text = "Key(s): %d" % value
