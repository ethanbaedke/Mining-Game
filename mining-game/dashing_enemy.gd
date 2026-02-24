class_name DashingEnemy extends Node2D

func _handle_body_entered(body:Node2D) -> void:
	
	# If this enemy touches the player, kill them.
	if (body is PlayerCharacter):
		body.kill_player()

func _on_head_body_entered(body: Node2D) -> void:
	_handle_body_entered(body)

func _on_body_body_entered(body: Node2D) -> void:
	_handle_body_entered(body)
