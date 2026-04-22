class_name MusicPlayer extends AudioStreamPlayer

@onready var game_theme:AudioStreamWAV = preload("res://Theme.wav")

func play_game_theme() -> void:
	
	stream = game_theme
	play()

func _ready() -> void:
	
	volume_linear = Globals.game_data.music_volume
	Globals.music_volume_changed.connect(func (new_value:float) -> void:
		volume_linear = Globals.game_data.music_volume)
