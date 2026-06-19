extends Control

signal new_campaign_pressed
signal open_campaign_pressed

func _on_new_campaign_button_pressed() -> void:
	new_campaign_pressed.emit()

func _on_open_campaign_button_pressed() -> void:
	open_campaign_pressed.emit()
