class_name PauseMenu extends CanvasLayer

@onready var _settings_menu:SettingsMenu = $Control/MarginContainer/SettingsMenu
@onready var _continue_button:StylizedButton = $Control/MarginContainer/SettingsMenu/MarginContainer/VBoxContainer/Buttons/BackButton

signal game_paused_changed(paused:bool)

var _just_opened:bool = false

func _ready() -> void:
	
	# Set initial visibility (should always be false).
	self.visible = get_tree().paused
	
	# Listen for continue button to unpause game.
	_continue_button.pressed.connect(func() -> void:
		toggle_game_paused())

func _process(delta: float) -> void:
	
	if (Input.is_action_just_pressed("ui_cancel") && self.visible):
		if (!_just_opened):
			toggle_game_paused()
			
	_just_opened = false


func toggle_game_paused() -> void:
	
	get_tree().paused = !get_tree().paused
	_settings_menu.set_input_available(get_tree().paused)
	self.visible = get_tree().paused
	
	# Save settings changes when unpaused.
	if (!get_tree().paused):
		Globals.save_game_data()
	# Set flag when paused.
	else:
		_just_opened = true
		
	game_paused_changed.emit(get_tree().paused)
