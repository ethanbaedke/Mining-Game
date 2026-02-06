class_name PlayerCharacter extends CharacterBody2D

const MOVE_SPEED:int = 30

func _physics_process(delta: float) -> void:
	
	# Inputs are only -1, 0, or 1. No partial movement (through joysticks).
	var input:Vector2 = Vector2.ZERO
	input.x = sign(Input.get_axis("move_left", "move_right"))
	input.y = sign(Input.get_axis("move_up", "move_down"))
	
	# Normalize input to ensure diagonal movement is the same speed as lateral movement
	self.velocity = input.normalized() * MOVE_SPEED

	move_and_slide()
