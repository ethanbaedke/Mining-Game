class_name MainMenu extends Control

@onready var _start_button:StylizedButton = $VBoxContainer/StartButton
@onready var _settings_button:StylizedButton = $VBoxContainer/SettingsButton
@onready var _settings_menu:SettingsMenu = $SettingsMenu
@onready var _settings_back_button:StylizedButton = $SettingsMenu/MarginContainer/VBoxContainer/Buttons/BackButton
@onready var _quit_button:StylizedButton = $VBoxContainer/QuitButton

signal start_game_requested
signal quit_game_requested

var _on_settings_menu:bool = false

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
	
	# The game manager will set input available once it's ready. We start with it off here.
	set_input_available(false)
	_settings_menu.set_input_available(false)
	
	_start_button.pressed.connect(func () -> void:
		start_game_requested.emit())
	
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_settings_back_button.pressed.connect(_on_settings_back_button_pressed)
		
	_quit_button.pressed.connect(func () -> void:
		quit_game_requested.emit())
	
	Globals.input_type_changed.connect(_on_globals_input_type_changed)

func _process(delta: float) -> void:
	
	if (_on_settings_menu):
		self.position.y = lerp(0.0, -270.0, 1.0)
	else:
		self.position.y = lerp(-270.0, 0.0, 1.0)

func _on_globals_input_type_changed(old_type:Globals.InputType) -> void:
	
	# If the mouse is not over an element (no focus) and we switch to keyboard or gamepad input, focus the start button.
	if (old_type == Globals.InputType.MOUSE):
		var focus_owner:Control = get_viewport().gui_get_focus_owner()
		if (focus_owner == null):
			# Must wait so the default navigation doesn't happen right after setting focus on the start button (we overwrite it instead).
			_start_button.grab_focus.call_deferred()

func _on_settings_button_pressed() -> void:
	
	self.set_input_available(false)
	_on_settings_menu = true
	_settings_menu.set_input_available(true)

func _on_settings_back_button_pressed() -> void:
	
	Globals.save_game_data()
	
	_settings_menu.set_input_available(false)
	_on_settings_menu = false
	self.set_input_available(true)
