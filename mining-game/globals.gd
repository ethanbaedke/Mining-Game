extends Node

enum InputType
{
	MOUSE,
	KEYBOARD,
	GAMEPAD,
}

# Settings signals.
signal music_volume_changed(new_value:float)
signal sound_effect_volume_changed(new_value:float)

signal input_type_changed(old_type:InputType)

var input_type:InputType = InputType.GAMEPAD

var game_data:SaveData = null

func save_game_data() -> void:
	
	ResourceSaver.save(game_data, "user://save_data.res")
	print("Data saved to " + OS.get_user_data_dir())

func set_music_volume(value:float) -> void:
	game_data.music_volume = clampf(value, 0.0, 1.0)
	music_volume_changed.emit(game_data.music_volume)
	
func set_sound_effect_volume(value:float) -> void:
	game_data.sound_effect_volume = clampf(value, 0.0, 1.0)
	sound_effect_volume_changed.emit(game_data.sound_effect_volume)

func switch_input_type(type:InputType) -> void:
	
	if (input_type == type):
		return
	
	match type:
		InputType.MOUSE:
			print("Switching input to mouse.")
		InputType.KEYBOARD:
			print("Switching input to keyboard.")
		InputType.GAMEPAD:
			print("Switching input to gamepad.")
	
	var old_type:InputType = input_type
	input_type = type
	input_type_changed.emit(old_type)
	
	_update_cursor_state()

func _ready() -> void:
	
	# Ensure a pause game doesn't affect this object.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_load_game_data()
	
	_update_cursor_state()

func _load_game_data() -> void:
	
	# Load save data.
	if (ResourceLoader.exists("user://save_data.res")):
		game_data = ResourceLoader.load("user://save_data.res")
		
		# If we couldn't load it, let it set to defaults.
		if (game_data == null):
			game_data = SaveData.new()

func _input(event: InputEvent) -> void:
	
	if (event is InputEventMouseMotion):
		switch_input_type(InputType.MOUSE)
	elif (event is InputEventKey):
		switch_input_type(InputType.KEYBOARD)
	elif (event is InputEventJoypadMotion):
		if (abs(event.axis_value) > 0.1):
			switch_input_type(InputType.GAMEPAD)
	elif (event is InputEventJoypadButton):
		switch_input_type(InputType.GAMEPAD)

func _update_cursor_state() -> void:
	
	match input_type:
		InputType.MOUSE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		InputType.KEYBOARD:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		InputType.GAMEPAD:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
