class_name MineLevelHud extends CanvasLayer

@onready var _floor_label:Label = $FloorLabel

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
