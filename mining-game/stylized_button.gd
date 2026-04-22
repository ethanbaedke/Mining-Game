class_name StylizedButton extends PanelContainer

const MAX_SCALE_MODIFIER:float = 1.2
const SCALE_SPEED:float = 2.0

signal pressed

func set_input_allowed(allowed:bool) -> void:
	
	if (allowed):
		focus_mode = Control.FOCUS_ALL
	else:
		focus_mode = Control.FOCUS_NONE
	
	# Fixes edge case where mouse is over button on load but movement doesn't happen so it doesn't focus. Now updating focus as soon as input becomes available.
	if (Globals.input_type == Globals.InputType.MOUSE):
		_update_mouse_focus()

func _process(delta: float) -> void:
	
	# Handle scaling.
	if (has_focus()):
		var new_scale:float = min(scale.x + (SCALE_SPEED * delta), MAX_SCALE_MODIFIER)
		scale = Vector2(new_scale, new_scale)
	else:
		var new_scale:float = max(scale.x - (SCALE_SPEED * delta), 1.0)
		scale = Vector2(new_scale, new_scale)
	
	if (has_focus() && Input.is_action_just_pressed("ui_accept")):
		pressed.emit()

func _input(event: InputEvent) -> void:
	
	if (Globals.input_type != Globals.InputType.MOUSE):
		return
	
	if (event is InputEventMouseMotion):
		_update_mouse_focus()
	elif (event is InputEventMouseButton):
		if (event.button_index == 1 && self.has_focus()):
			pressed.emit()

func _update_mouse_focus() -> void:
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	if (self.get_global_rect().has_point(mouse_pos) && focus_mode == FOCUS_ALL):
		self.grab_focus()
	elif (self.has_focus()):
		self.release_focus()
