class_name GameManager extends Node

const MINE_LEVEL_SCENE:PackedScene = preload("res://mine_level.tscn")

var current_floor:int = 0

var _mine_level:MineLevel = null

func _ready() -> void:
	
	# Set the floor to 1.
	current_floor = 1
	
	# Instantiate the mine level.
	_instantiate_mine_level()

func _instantiate_mine_level() -> void:
	
	_mine_level = MINE_LEVEL_SCENE.instantiate()
	_mine_level.level_cleared.connect(_on_mine_level_level_cleared)
	_mine_level.player_killed.connect(_on_mine_level_player_killed)
	self.add_child(_mine_level)

func _free_mine_level() -> void:
	
	# Free the mine level and wait for it to be freed (end of the frame).
	_mine_level.queue_free()
	await get_tree().process_frame

func _on_mine_level_level_cleared() -> void:
	
	# Increment our current floor.
	current_floor += 1
	
	await _free_mine_level()
	_instantiate_mine_level()

func _on_mine_level_player_killed() -> void:
	
	await _free_mine_level()
	_instantiate_mine_level()
