extends Control

@onready var campaign_name: TextEdit = $CanvasLayer/ColorRect/CampaignNameTextEdit
@onready var author: TextEdit = $CanvasLayer/ColorRect/AuthorTextEdit
@onready var description: TextEdit = $CanvasLayer/ColorRect/DescriptionTextEdit

signal campaign_created(data)
signal canceled

func _on_save_pressed() -> void:
	var data = {
		"campaign_name": campaign_name.text,
		"author": author.text,
		"description": description.text
	}
	campaign_created.emit(data)

func _on_cancel_pressed() -> void:
	canceled.emit()
