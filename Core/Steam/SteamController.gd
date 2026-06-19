extends Node


func _init() -> void:
	var response : Dictionary = Steam.steamInitEx(480)
	print(response)
	
	var username : String = Steam.getPersonaName()
	print(username)
	
	var steam_id : int = Steam.getSteamID()
	print(steam_id)
	
	# do we own this game on Steam?
	var is_owned : bool = Steam.isSubscribed()
	
	# are we logged into Steam?
	var is_online : bool = Steam.loggedOn()
	
	# returns the game's launch options
	var launch_cmd_line : String = Steam.getLaunchCommandLine()
	
	# is the game running on a Steam Deck?
	var is_on_steam_deck : bool = Steam.isSteamRunningOnSteamDeck()
	
	# is the game running in VR?
	var is_in_vr : bool = Steam.isSteamRunningInVR()
	
	# is the player VAC banned?
	var is_vac_banned : bool = Steam.isVACBanned()
	
	# language of the game - e.g. "english", "french"
	var game_language : String = Steam.getCurrentGameLanguage()
	
	
