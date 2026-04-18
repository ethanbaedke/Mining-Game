class_name HelpScene extends Control

@onready var _continue_label:Label = $ContinueLabel

const CONTINUE_LABEL_FADE_IN_TIME:float = 1.5
const CONTINUE_LABEL_WAIT_TIME:float = 2.0

signal skipped

var _skip_available:bool = false
var _continue_label_fade_in_ready:bool = false
var _continue_label_alpha_timer:float = 0.0

func make_skip_available() -> void:
	_skip_available = true
	await get_tree().create_timer(CONTINUE_LABEL_WAIT_TIME).timeout
	_continue_label_fade_in_ready = true

func _ready() -> void:
	_continue_label.modulate.a = 0.0

func _process(delta: float) -> void:
	
	if (!_skip_available):
		return
	
	if (Input.is_action_just_pressed("use_pickaxe") || Input.is_action_just_pressed("place_bomb")):
		skipped.emit()
	
	if (!_continue_label_fade_in_ready):
		return
	
	_continue_label_alpha_timer += delta
	if (_continue_label_alpha_timer < CONTINUE_LABEL_FADE_IN_TIME):
		_continue_label.modulate.a = lerp(0.0, 1.0, _continue_label_alpha_timer / CONTINUE_LABEL_FADE_IN_TIME)
	else:
		_continue_label.modulate.a = lerp(0.25, 1.0, (cos((_continue_label_alpha_timer - CONTINUE_LABEL_FADE_IN_TIME) * 3.0) * 0.5) + 0.5)
