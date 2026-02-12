class_name PlayerCharacter extends CharacterBody2D

@onready var _sprite_2d:Sprite2D = $Sprite2D

const PI_OVER_FOUR:float = PI * 0.25
const THREE_PI_OVER_FOUR:float = (PI * 3.0) * 0.25
const FIVE_PI_OVER_FOUR:float = (PI * 5.0) * 0.25
const SEVEN_PI_OVER_FOUR:float = (PI * 7.0) * 0.25

const MOVE_SPEED:int = 40

func _physics_process(delta: float) -> void:
	
	# Inputs are only -1, 0, or 1. No partial movement (through joysticks).
	var input:Vector2 = Vector2.ZERO
	input.x = sign(Input.get_axis("move_left", "move_right"))
	input.y = sign(Input.get_axis("move_up", "move_down"))
	
	# Normalize input to ensure diagonal movement is the same speed as lateral movement
	self.velocity = input.normalized() * MOVE_SPEED

	_update_sprite_direction()

	move_and_slide()

# Updates the direction the sprite is facing based on the players velocity
func _update_sprite_direction() -> void:
	
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
	var atlas_texture:AtlasTexture = _sprite_2d.texture
	if (angle > LEFT_MARGIN_START):
		atlas_texture.region.position.x = 32.0
	elif (angle > DOWN_MARGIN_START):
		atlas_texture.region.position.x = 0.0
	elif (angle > RIGHT_MARGIN_START):
		atlas_texture.region.position.x = 16.0
	elif (angle > UP_MARGIN_START):
		atlas_texture.region.position.x = 48.0
	else:
		atlas_texture.region.position.x = 32.0
