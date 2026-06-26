extends Node

const CAMPAIGN_PATH := "res://Assets/Campaigns/"
const LEVEL_PATH := "res://Assets/Levels/"

const EXT := ".json"

func get_level_path(id: String) -> String:
	return LEVEL_PATH + id + EXT

func get_campaign_path(name: String) -> String:
	return CAMPAIGN_PATH + name + EXT
