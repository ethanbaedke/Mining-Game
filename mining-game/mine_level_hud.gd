class_name MineLevelHud extends CanvasLayer

@onready var _floor_label:Label = $MarginContainer/Control/HBoxContainer/FloorPanelContainer/FloorLabel
@onready var _score_label:Label = $MarginContainer/Control/PanelContainer/ScoreLabel
@onready var _lives_container:Container = $MarginContainer/Control/HBoxContainer/PanelContainer/MarginContainer/LivesContainer

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
	
	# Set the lives to reflect the current number of lives the player has left.
	_update_lives_container()
	
	# Set score (since the UI will reset every new level)
	_update_score_label()
	
	# Listen for score changes.
	_game_manager.current_score_changed.connect(_update_score_label)

func _update_score_label() -> void:
	
	_score_label.text = "Score: " + str(_game_manager.current_score)
	
func _update_lives_container() -> void:
	
	var i:int = 0
	
	# Make lives visible for lives we have left.
	while (i < _lives_container.get_child_count() && i < _game_manager.lives_remaining):
		(_lives_container.get_child(i) as TextureRect).modulate = Color.WHITE
		i += 1
		
	# Make any following lives invisible.
	while (i < _lives_container.get_child_count()):
		(_lives_container.get_child(i) as TextureRect).modulate = Color.TRANSPARENT
		i += 1
