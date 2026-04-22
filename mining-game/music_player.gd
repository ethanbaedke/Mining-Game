class_name MusicPlayer extends AudioStreamPlayer

@onready var game_theme:AudioStreamWAV = preload("res://Theme.wav")

@export var _pause_menu:PauseMenu = null

func play_game_theme() -> void:
	
	stream = game_theme
	play()

func play_player_killed() -> void:
	stop()
	
func play_level_cleared() -> void:
	stop()

func _ready() -> void:
	
	# Handle game volume setting.
	volume_linear = Globals.game_data.music_volume
	Globals.music_volume_changed.connect(func (new_value:float) -> void:
		volume_linear = Globals.game_data.music_volume)
		
	# Listen for game pausing/unpausing.
	_pause_menu.game_paused_changed.connect(_on_pause_menu_game_paused_changed)

func _on_pause_menu_game_paused_changed(paused:bool) -> void:
	
	stream_paused = paused
