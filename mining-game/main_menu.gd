class_name MainMenu extends Control

@onready var _start_button:StylizedButton = $VBoxContainer/StartButton
@onready var _settings_button:StylizedButton = $VBoxContainer/SettingsButton
@onready var _quit_button:StylizedButton = $VBoxContainer/QuitButton

signal start_game_requested
signal quit_game_requested

func set_input_available(available:bool) -> void:
	
	if (available):
		_start_button.grab_focus()
	else:
		get_viewport().gui_get_focus_owner().release_focus()

func _ready() -> void:
	
	_start_button.pressed.connect(func () -> void:
		start_game_requested.emit())
		
	_quit_button.pressed.connect(func () -> void:
		quit_game_requested.emit())
