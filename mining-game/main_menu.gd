class_name MainMenu extends Control

@onready var _start_button:StylizedButton = $VBoxContainer/StartButton
@onready var _settings_button:StylizedButton = $VBoxContainer/SettingsButton
@onready var _quit_button:StylizedButton = $VBoxContainer/QuitButton

signal start_game_requested
signal quit_game_requested

func set_input_available(available:bool) -> void:
	
	if (available):
		_start_button.set_input_allowed(true)
		_settings_button.set_input_allowed(true)
		_quit_button.set_input_allowed(true)
		
		if (Globals.input_type != Globals.InputType.MOUSE):
			_start_button.grab_focus()
	else:
		_start_button.set_input_allowed(false)
		_settings_button.set_input_allowed(false)
		_quit_button.set_input_allowed(false)
		
		var focus_owner:Control = get_viewport().gui_get_focus_owner()
		if (focus_owner != null):
			focus_owner.release_focus()

func _ready() -> void:
	
	set_input_available(false)
	
	_start_button.pressed.connect(func () -> void:
		start_game_requested.emit())
		
	_quit_button.pressed.connect(func () -> void:
		quit_game_requested.emit())
	
	Globals.input_type_changed.connect(_on_globals_input_type_changed)

func _on_globals_input_type_changed(old_type:Globals.InputType) -> void:
	
	# If the mouse is not over an element (no focus) and we switch to keyboard or gamepad input, focus the start button.
	if (old_type == Globals.InputType.MOUSE):
		var focus_owner:Control = get_viewport().gui_get_focus_owner()
		if (focus_owner == null):
			# Must wait so the default navigation doesn't happen right after setting focus on the start button (we overwrite it instead).
			_start_button.grab_focus.call_deferred()
