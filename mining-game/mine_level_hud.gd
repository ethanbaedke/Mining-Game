class_name MineLevelHud extends CanvasLayer

@onready var _floor_label:Label = $MarginContainer/Control/FloorPanelContainer/FloorLabel
@onready var _score_label:Label = $MarginContainer/Control/PanelContainer/ScoreLabel

# References retrieved on ready.
var _mine_level:MineLevel = null
var _game_manager:GameManager = null

func _ready() -> void:
	
	# Grab a reference to the mine level, which should be this nodes parent.
	_mine_level = get_parent()
	
	# Grab a reference to the game manager, which should be the mine level's parent.
	_game_manager = _mine_level.get_parent()
	
	# Set the floor label to reflect the current floor the player is on.
	_floor_label.text = "Floor: " + str(_game_manager.current_floor)
	
	# Set score (since the UI will reset every new level)
	_update_score_label()
	
	# Listen for score changes.
	_game_manager.current_score_changed.connect(_update_score_label)

func _update_score_label() -> void:
	
	_score_label.text = "Score: " + str(_game_manager.current_score)
