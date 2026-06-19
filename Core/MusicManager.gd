extends Node
class_name MusicManager

var player: AudioStreamPlayer
static var instance: MusicManager

func _ready() -> void:
	instance = self
	player = AudioStreamPlayer.new()
	add_child(player)
	player.autoplay = false
	player.volume_db = -6.0
	player.bus = "Music"

static func play(stream_path: String, loop := true) -> void:
	if instance == null:
		push_error("MusicManager instance not ready")
		return

	var stream = load(stream_path)
	if stream:
		instance.player.stream = stream
		instance.player.play()
		instance.player.stream_paused = false
		instance.player.stream.loop = loop

static func stop() -> void:
	if instance and instance.player:
		instance.player.stop()
