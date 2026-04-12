class_name Rock extends StaticBody2D

@export var score_for_breaking:int = 1

# This is handeled by the player when the rock is hit.
@export var camera_trauma_on_break:float = 0.2

func break_rock() -> void:
	
	queue_free()

func handle_hit() -> void:
	
	_request_remove_from_mine_level()

func _request_remove_from_mine_level() -> void:
	
	var parent:Node = get_parent()
	if (parent is MineLevel):
		parent.remove_rock(self)
