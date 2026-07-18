extends Node

var num_players = 30
var bus = "master"

var available = [] # The available players.
var queue = [] # The queue of sounds to play.

var music_player : AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
	music_player.volume_db = -6.0
	
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var player = AudioStreamPlayer.new()
		add_child(player)
		available.append(player)
		player.finished.connect(_on_stream_finished.bind(player))
		player.bus = bus
		
func _process(delta) -> void:
	# Play a queued sound if any players are available.
	if not queue.is_empty() and not available.is_empty():
		var player = available.pop_front()
		player.stream = queue.pop_front()
		player.play()
		

func _on_stream_finished(stream) -> void:
	# When finished playing a stream, make the player available again.
	available.append(stream)
	
func play(stream: AudioStream) -> void:
	queue.append(stream)
	
func play_music(path: String) -> void:
	var stream = load(path)
	
	if stream:
		music_player.stream = stream
		music_player.play()

func stop_music() -> void:
	music_player.stop()
		
	
