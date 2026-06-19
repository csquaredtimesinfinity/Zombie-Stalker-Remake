extends Node

@onready var screen_container = $ScreenContainer
@onready var campaign_data = $CampaignData

var start_screen = preload("res://Editor/CampaignEditor/CampaignEditorsStart.tscn")
var create_scene = preload("res://Editor/CampaignEditor/NewCampaign.tscn")

var current_screen: Node

func _ready() -> void:
	switch_screen(start_screen)

func switch_screen(scene: PackedScene):
	if current_screen:
		current_screen.queue_free()
	
	current_screen = scene.instantiate()
	screen_container.add_child(current_screen)
	connect_signals(current_screen)
	
func connect_signals(screen: Node):
	if screen.has_signal("new_campaign_pressed"):
		screen.new_campaign_pressed.connect(_on_new_campaign)
	
	if screen.has_signal("campaign_created"):
		screen.campaign_created.connect(_on_campaign_created)
		
	if screen.has_signal("canceled"):
		screen.canceled.connect(_on_canceled)
		
func _on_new_campaign():
	switch_screen(create_scene)

func _on_campaign_created():
	pass
	
func _on_canceled():
	switch_screen(start_screen)
