class_name ScoreIncrementEffect extends Control

@onready var _label:Label = $Label
@onready var _anim_player:AnimationPlayer = $AnimationPlayer

var _score:int = 0
var _color:Color = Color.WHITE

func setup(score:int, color:Color) -> void:
	_score = score
	_color = color
	
func _ready() -> void:
	_label.text = "+" + str(_score)
	_label.modulate = _color
	await _anim_player.animation_finished
	self.queue_free()
