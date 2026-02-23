class_name GameManager extends Node

const MINE_LEVEL_SCENE:PackedScene = preload("res://mine_level.tscn")

var current_floor:int = 0

var _mine_level:MineLevel = null

func move_to_next_floor() -> void:
	
	# Free the mine level and wait for it to be freed (end of the frame).
	_mine_level.queue_free()
	await get_tree().process_frame
	
	# Increment our current floor.
	current_floor += 1
	
	# Reinstantiate the mine level.
	_mine_level = MINE_LEVEL_SCENE.instantiate()
	self.add_child(_mine_level)

func _ready() -> void:
	
	# Set the floor to 1.
	current_floor = 1
	
	# Instantiate the mine level.
	_mine_level = MINE_LEVEL_SCENE.instantiate()
	self.add_child(_mine_level)
