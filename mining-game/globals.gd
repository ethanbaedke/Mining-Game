extends Node

enum InputType
{
	MOUSE,
	KEYBOARD,
	GAMEPAD,
}

signal input_type_changed(old_type:InputType)

var input_type:InputType = InputType.GAMEPAD

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
	
	_update_cursor_state()

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
