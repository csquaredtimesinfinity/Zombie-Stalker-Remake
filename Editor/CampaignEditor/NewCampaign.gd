extends Control

@onready var campaign_name: TextEdit = $CanvasLayer/ColorRect/CampaignNameTextEdit
@onready var author: TextEdit = $CanvasLayer/ColorRect/AuthorTextEdit
@onready var description: TextEdit = $CanvasLayer/ColorRect/DescriptionTextEdit
@onready var file_name_preview: Label = $CanvasLayer/ColorRect/FileNamePreviewLabel

const CAMPAIGN_DIRECTORY := "res://Assets/Campaigns/"

signal campaign_created(data)
signal canceled

func _on_save_pressed() -> void:
	var data = {
		"campaign_name": campaign_name.text,
		"author": author.text,
		"description": description.text
	}
	campaign_created.emit(data)
	_save_campaign()

func _on_cancel_pressed() -> void:
	canceled.emit()

func _build_campaign_data() -> Dictionary:
	return {
		"name": campaign_name.text,
		"author": author.text,
		"description": description.text,
		"levels": []
	}

func _save_campaign() -> void:
	var campaign_data = _build_campaign_data()

	var filename = format_campaign_filename(campaign_data["name"])
	var path = PathManager.CAMPAIGN_PATH + filename

	# ensure folder exists
	DirAccess.make_dir_recursive_absolute(PathManager.CAMPAIGN_PATH)

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open file for saving: " + path)
		return

	file.store_string(JSON.stringify(campaign_data, "\t", false) + "\n")

	print("Saved campaign to: ", path)

func format_campaign_filename(name: String) -> String:
	var cleaned = name.strip_edges().to_lower()

	# replace invalid filename characters with spaces
	for c in ["-", "_", ".", ",", ":", ";", "/", "\\"]:
		cleaned = cleaned.replace(c, " ")

	var words = cleaned.split(" ", false)
	var result = ""

	for w in words:
		if w.is_empty():
			continue
		result += w.substr(0,1).to_upper() + w.substr(1)

	return result + ".json"

func _on_campaign_name_text_edit_text_changed() -> void:
	if campaign_name.text.strip_edges() == "":
		file_name_preview.text = ""
	else:
		file_name_preview.text = format_campaign_filename(campaign_name.text)
