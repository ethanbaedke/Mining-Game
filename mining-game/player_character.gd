class_name PlayerCharacter extends CharacterBody2D

@onready var _animated_sprite_2d:AnimatedSprite2D = $AnimatedSprite2D

const PI_OVER_FOUR:float = PI * 0.25
const THREE_PI_OVER_FOUR:float = (PI * 3.0) * 0.25
const FIVE_PI_OVER_FOUR:float = (PI * 5.0) * 0.25
const SEVEN_PI_OVER_FOUR:float = (PI * 7.0) * 0.25

const MOVE_SPEED:int = 40

enum FacingDirection { LEFT, RIGHT, UP, DOWN }
var _face_dir:FacingDirection = FacingDirection.DOWN

# Used to track whether the animated sprite 2d is currently playing an idle animation
var _in_idle_anim:bool = true

func _physics_process(delta: float) -> void:
	
	_set_velocity()
	_update_facing_direction()
	_update_animation()

	move_and_slide()

# Set the velocity of the player using their input
func _set_velocity() -> void:
	
	# Inputs are only -1, 0, or 1. No partial movement (through joysticks).
	var input:Vector2 = Vector2.ZERO
	input.x = sign(Input.get_axis("move_left", "move_right"))
	input.y = sign(Input.get_axis("move_up", "move_down"))
	
	# Normalize input to ensure diagonal movement is the same speed as lateral movement
	self.velocity = input.normalized() * MOVE_SPEED

# Updates the direction the character is facing based on the players velocity
func _update_facing_direction() -> void:
	
	# The player is not moving, so our direction cannot change
	if (velocity.is_zero_approx()):
		return
	
	# This puts our angle in the range (0, 2*PI), starting at PI on the unit circle, going counter-clockwise
	var angle:float = self.velocity.angle() + PI
	
	# Slightly widen our left and right margins to force diagonal movement to be displayed horizontally
	const WIDEN_MODIFIER:float = 0.0000001 # This value was derived through testing
	const LEFT_MARGIN_START:float = SEVEN_PI_OVER_FOUR - WIDEN_MODIFIER
	const DOWN_MARGIN_START:float = FIVE_PI_OVER_FOUR + WIDEN_MODIFIER
	const RIGHT_MARGIN_START:float = THREE_PI_OVER_FOUR - WIDEN_MODIFIER
	const UP_MARGIN_START:float = PI_OVER_FOUR + WIDEN_MODIFIER
	
	# Our angle calculation above makes it easy for us to check which direction we should face
	if (angle > LEFT_MARGIN_START):
		_face_dir = FacingDirection.LEFT
	elif (angle > DOWN_MARGIN_START):
		_face_dir = FacingDirection.DOWN
	elif (angle > RIGHT_MARGIN_START):
		_face_dir = FacingDirection.RIGHT
	elif (angle > UP_MARGIN_START):
		_face_dir = FacingDirection.UP
	else:
		_face_dir = FacingDirection.LEFT

# Updates the animation playing for the character
func _update_animation() -> void:
	
		# The player is not moving, use an idle animation
		if (velocity.is_zero_approx()):
			match _face_dir:
				FacingDirection.LEFT:
					_animated_sprite_2d.play("idle_left")
				FacingDirection.RIGHT:
					_animated_sprite_2d.play("idle_right")
				FacingDirection.UP:
					_animated_sprite_2d.play("idle_up")
				FacingDirection.DOWN:
					_animated_sprite_2d.play("idle_down")
		# The player is moving, use a running animation
		else:
			match _face_dir:
				FacingDirection.LEFT:
					_animated_sprite_2d.play("run_left")
				FacingDirection.RIGHT:
					_animated_sprite_2d.play("run_right")
				FacingDirection.UP:
					_animated_sprite_2d.play("run_up")
				FacingDirection.DOWN:
					_animated_sprite_2d.play("run_down")
