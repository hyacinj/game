extends Node

var bgm_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)

func play_bgm(s: AudioStream) -> void: bgm_player.stream = s; bgm_player.play()
func stop_bgm() -> void: bgm_player.stop()
func play_sfx(s: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = s; p.finished.connect(p.queue_free)
	add_child(p); p.play()
