class_name PlayerCharacter extends CharacterBody2D

@onready var _animated_sprite_2d:AnimatedSprite2D = $AnimatedSprite2D

const PI_OVER_FOUR:float = PI * 0.25
const THREE_PI_OVER_FOUR:float = (PI * 3.0) * 0.25
const FIVE_PI_OVER_FOUR:float = (PI * 5.0) * 0.25
const SEVEN_PI_OVER_FOUR:float = (PI * 7.0) * 0.25

const MOVE_SPEED:int = 40

enum FacingDirection { LEFT, RIGHT, UP, DOWN }
var _face_dir:FacingDirection = FacingDirection.DOWN

var _using_pickaxe:bool = false
var _pickaxe_swing_anim_frame:int = 0
# How long the player holds the pickaxe above their head before swinging it
var _pickaxe_load_time:float = 0.25
# How long the player holds the pickaxe down after swinging it
var _pickaxe_thrust_time:float = 0.25
var _pickaxe_anim_time:float = 0.0

func _physics_process(delta: float) -> void:
	
	_set_velocity()
	_update_facing_direction()
	
	if (Input.is_action_just_pressed("use_pickaxe")):
		_try_use_pickaxe()
	
	if (_using_pickaxe):
		_handle_pickaxe_swing()
	
	_update_animation()

	move_and_slide()

# Makes the player swing their pickaxe if they're allowed to at the time this function is called
func _try_use_pickaxe() -> void:
	
	# Cannot use our pickaxe if we're already using it
	if (_using_pickaxe):
		return
	
	# Success
	_using_pickaxe = true

func _handle_pickaxe_swing() -> void:
	
	pass

# Set the velocity of the player using their input
func _set_velocity() -> void:
	
	# The player cannot move if swinging their pickaxe
	if (_using_pickaxe):
		self.velocity = Vector2.ZERO
		return
	
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
	
	# Slightly widen our top and bottom margins to force diagonal movement to be displayed vertically
	const WIDEN_MODIFIER:float = 0.0000001 # This value was derived through testing
	const LEFT_MARGIN_START:float = SEVEN_PI_OVER_FOUR + WIDEN_MODIFIER
	const DOWN_MARGIN_START:float = FIVE_PI_OVER_FOUR - WIDEN_MODIFIER
	const RIGHT_MARGIN_START:float = THREE_PI_OVER_FOUR + WIDEN_MODIFIER
	const UP_MARGIN_START:float = PI_OVER_FOUR - WIDEN_MODIFIER
	
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
	
		# The player is using their pickaxe
		if (_using_pickaxe):
			match _face_dir:
				FacingDirection.LEFT:
					_animated_sprite_2d.play("swing_pickaxe_left")
					_animated_sprite_2d.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.RIGHT:
					_animated_sprite_2d.play("swing_pickaxe_right")
					_animated_sprite_2d.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.UP:
					_animated_sprite_2d.play("swing_pickaxe_up")
					_animated_sprite_2d.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.DOWN:
					_animated_sprite_2d.play("swing_pickaxe_down")
					_animated_sprite_2d.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)

		# The player is not moving, use an idle animation
		elif (velocity.is_zero_approx()):
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
