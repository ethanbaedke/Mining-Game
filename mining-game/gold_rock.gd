class_name GoldRock extends StaticBody2D

func break_rock() -> void:
	
	queue_free()

func handle_hit() -> void:
	
	_request_remove_from_mine_level()

func _request_remove_from_mine_level() -> void:
	
	var parent:Node = get_parent()
	if (parent is MineLevel):
		parent.remove_gold_rock(self)
