class_name StylizedButton extends PanelContainer

const MAX_SCALE_MODIFIER:float = 1.2
const SCALE_SPEED:float = 2.0

signal pressed

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
