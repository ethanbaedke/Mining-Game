class_name HighScoreDisplay extends Control

@onready var HIGH_SCORE_ENTRY_UI:Array[HBoxContainer] = [
	$PanelContainer/MarginContainer/VBoxContainer/Entry1,
	$PanelContainer/MarginContainer/VBoxContainer/Entry2,
	$PanelContainer/MarginContainer/VBoxContainer/Entry3,
	$PanelContainer/MarginContainer/VBoxContainer/Entry4,
	$PanelContainer/MarginContainer/VBoxContainer/Entry5,
	$PanelContainer/MarginContainer/VBoxContainer/Entry6,
	$PanelContainer/MarginContainer/VBoxContainer/Entry7,
	$PanelContainer/MarginContainer/VBoxContainer/Entry8,
	$PanelContainer/MarginContainer/VBoxContainer/Entry9,
	$PanelContainer/MarginContainer/VBoxContainer/Entry10]

# Reference retrieved on ready.
var _game_manager:GameManager = null

func _ready() -> void:
	
	_game_manager = get_parent()
	
	# Fill out the high score ui with all high scores on the game manager.
	var entry_ind:int = 0
	while (entry_ind < _game_manager.high_scores.size()):
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(0) as Label).text = _game_manager.high_scores[entry_ind].name
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(1) as Label).text = str(_game_manager.high_scores[entry_ind].score)
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(2) as Label).text = str(_game_manager.high_scores[entry_ind].floor_number)
		entry_ind += 1
		
	# Fill out the remaining high score ui with blanks.
	while (entry_ind < 10):
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(0) as Label).text = ""
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(1) as Label).text = ""
		(HIGH_SCORE_ENTRY_UI[entry_ind].get_child(2) as Label).text = ""
		entry_ind += 1
