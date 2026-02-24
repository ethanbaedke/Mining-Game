class_name PlayerCharacter extends CharacterBody2D

@onready var _player_sprite:AnimatedSprite2D = $PlayerSprite
@onready var _pickaxe_sprite:AnimatedSprite2D = $PickaxeSprite

@onready var _pickaxe_down_hitbox_shape:CollisionShape2D = $PickaxeDownHitbox/CollisionShape2D
@onready var _pickaxe_up_hitbox_shape:CollisionShape2D = $PickaxeUpHitbox/CollisionShape2D
@onready var _pickaxe_left_hitbox_shape:CollisionShape2D = $PickaxeLeftHitbox/CollisionShape2D
@onready var _pickaxe_right_hitbox_shape:CollisionShape2D = $PickaxeRightHitbox/CollisionShape2D

const PI_OVER_FOUR:float = PI * 0.25
const THREE_PI_OVER_FOUR:float = (PI * 3.0) * 0.25
const FIVE_PI_OVER_FOUR:float = (PI * 5.0) * 0.25
const SEVEN_PI_OVER_FOUR:float = (PI * 7.0) * 0.25

const PICKAXE_UP_F1_POS:Vector2 = Vector2(0.0, -15.0)
const PICKAXE_UP_F2_POS:Vector2 = Vector2(0.0, -4.0)
const PICKAXE_DOWN_F1_POS:Vector2 = Vector2(0.0, -12.0)
const PICKAXE_DOWN_F2_POS:Vector2 = Vector2(0.0, -1.0)
const PICKAXE_LEFT_F1_POS:Vector2 = Vector2(0.0, -12.0)
const PICKAXE_LEFT_F2_POS:Vector2 = Vector2(-9.0, -1.0)
const PICKAXE_RIGHT_F1_POS:Vector2 = Vector2(0.0, -12.0)
const PICKAXE_RIGHT_F2_POS:Vector2 = Vector2(9.0, -1.0)

const MOVE_SPEED:int = 40

signal player_killed

enum FacingDirection { LEFT, RIGHT, UP, DOWN }
var _face_dir:FacingDirection = FacingDirection.DOWN

var _using_pickaxe:bool = false
var _pickaxe_swing_anim_frame:int = 0
# How long the player holds the pickaxe above their head before swinging it.
var _pickaxe_load_time:float = 0.15
# How long the player holds the pickaxe down after swinging it.
var _pickaxe_thrust_time:float = 0.25
var _pickaxe_anim_time:float = 0.0

func kill_player() -> void:
	player_killed.emit()

func _physics_process(delta:float) -> void:
	
	_set_velocity()
	_update_facing_direction()
	
	if (Input.is_action_just_pressed("use_pickaxe")):
		_try_use_pickaxe()
	
	if (_using_pickaxe):
		_handle_pickaxe_swing(delta)
	
	_update_animation()

	move_and_slide()

# Makes the player swing their pickaxe if they're allowed to at the time this function is called.
func _try_use_pickaxe() -> void:
	
	# Cannot use our pickaxe if we're already using it
	if (_using_pickaxe):
		return
	
	# Success
	_using_pickaxe = true
	_pickaxe_swing_anim_frame = 0
	_pickaxe_anim_time = 0.0
	_pickaxe_sprite.set_visible(true)
	_update_pickaxe_position()
	
	# If swinging the pickaxe up, it should render behind the player sprite.
	# This will happen if they're on the same z_index since the pickaxe sprite sits higher in the scene tree than the player sprite.
	# We have to do it this way so the pickaxe doesn't render under the terrain (with a lower z_index).
	if _face_dir == FacingDirection.UP:
		_pickaxe_sprite.z_index = 0
	# In all other cases it should render in front. We set the z_index to 1.
	# It will always render in front of the terrain, but that is okay in this case. It looks fine.
	else:
		_pickaxe_sprite.z_index = 1

func _handle_pickaxe_swing(delta:float) -> void:
		
	# We're on the first frame of our animation.
	if _pickaxe_swing_anim_frame == 0:
		# It's time to move to the second frame.
		if _pickaxe_anim_time > _pickaxe_load_time:
			_pickaxe_swing_anim_frame = 1
			_update_pickaxe_position()
			# The second frame is where our hitbox should become active.
			_enable_pickaxe_hitbox()
	
	# We're on the second frame of our animation.
	else:
		# It's time to be finished with the animation.
		if _pickaxe_anim_time > _pickaxe_load_time + _pickaxe_thrust_time:
			_using_pickaxe = false
			_pickaxe_sprite.set_visible(false)
			# If the hitbox didn't hit anything, it will still be active at the end of the animation. Disable it.
			_disable_pickaxe_hitbox()
	
	# Increment our animation timer.
	_pickaxe_anim_time += delta

# When the pickaxe sprite animates it's swing, it needs to physically move to be in the player's hands.
# This function updates the pickaxe sprite position to fit it into the players hands.
func _update_pickaxe_position() -> void:
	
	match _face_dir:
		FacingDirection.LEFT:
			if (_pickaxe_swing_anim_frame == 0):
				_pickaxe_sprite.position = PICKAXE_LEFT_F1_POS
			else:
				_pickaxe_sprite.position = PICKAXE_LEFT_F2_POS
		FacingDirection.RIGHT:
			if (_pickaxe_swing_anim_frame == 0):
				_pickaxe_sprite.position = PICKAXE_RIGHT_F1_POS
			else:
				_pickaxe_sprite.position = PICKAXE_RIGHT_F2_POS
		FacingDirection.UP:
			if (_pickaxe_swing_anim_frame == 0):
				_pickaxe_sprite.position = PICKAXE_UP_F1_POS
			else:
				_pickaxe_sprite.position = PICKAXE_UP_F2_POS
		FacingDirection.DOWN:
			if (_pickaxe_swing_anim_frame == 0):
				_pickaxe_sprite.position = PICKAXE_DOWN_F1_POS
			else:
				_pickaxe_sprite.position = PICKAXE_DOWN_F2_POS

# Enables the pickaxe hitbox in the direction the player is currently facing
func _enable_pickaxe_hitbox() -> void:
	
	# Must use call_deferred on set_disable since the disabled state of collision shapes can't be changed while queries are being flushed.
	match _face_dir:
		FacingDirection.LEFT:
			_pickaxe_left_hitbox_shape.set_disabled.call_deferred(false)
		FacingDirection.RIGHT:
			_pickaxe_right_hitbox_shape.set_disabled.call_deferred(false)
		FacingDirection.UP:
			_pickaxe_up_hitbox_shape.set_disabled.call_deferred(false)
		FacingDirection.DOWN:
			_pickaxe_down_hitbox_shape.set_disabled.call_deferred(false)
	
# Disables the pickaxe hitbox in the direction the player is currently facing
func _disable_pickaxe_hitbox() -> void:
	
	# Must use call_deferred on set_disable since the disabled state of collision shapes can't be changed while queries are being flushed.
	match _face_dir:
		FacingDirection.LEFT:
			_pickaxe_left_hitbox_shape.set_disabled.call_deferred(true)
		FacingDirection.RIGHT:
			_pickaxe_right_hitbox_shape.set_disabled.call_deferred(true)
		FacingDirection.UP:
			_pickaxe_up_hitbox_shape.set_disabled.call_deferred(true)
		FacingDirection.DOWN:
			_pickaxe_down_hitbox_shape.set_disabled.call_deferred(true)

# Set the velocity of the player using their input.
func _set_velocity() -> void:
	
	# The player cannot move if swinging their pickaxe.
	if (_using_pickaxe):
		self.velocity = Vector2.ZERO
		return
	
	# Inputs are only -1, 0, or 1. No partial movement (through joysticks).
	var input:Vector2 = Vector2.ZERO
	input.x = sign(Input.get_axis("move_left", "move_right"))
	input.y = sign(Input.get_axis("move_up", "move_down"))
	
	# Normalize input to ensure diagonal movement is the same speed as lateral movement.
	self.velocity = input.normalized() * MOVE_SPEED

# Updates the direction the character is facing based on the players velocity.
func _update_facing_direction() -> void:
	
	# The player is not moving, so our direction cannot change.
	if (velocity.is_zero_approx()):
		return
	
	# This puts our angle in the range (0, 2*PI), starting at PI on the unit circle, going counter-clockwise.
	var angle:float = self.velocity.angle() + PI
	
	# Slightly widen our top and bottom margins to force diagonal movement to be displayed vertically.
	const WIDEN_MODIFIER:float = 0.0000001 # This value was derived through testing.
	const LEFT_MARGIN_START:float = SEVEN_PI_OVER_FOUR + WIDEN_MODIFIER
	const DOWN_MARGIN_START:float = FIVE_PI_OVER_FOUR - WIDEN_MODIFIER
	const RIGHT_MARGIN_START:float = THREE_PI_OVER_FOUR + WIDEN_MODIFIER
	const UP_MARGIN_START:float = PI_OVER_FOUR - WIDEN_MODIFIER
	
	# Our angle calculation above makes it easy for us to check which direction we should face.
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

# Updates the animation playing for the character, and the pickaxe if it's being used.
func _update_animation() -> void:
	
		# The player is using their pickaxe.
		if (_using_pickaxe):
			match _face_dir:
				FacingDirection.LEFT:
					_player_sprite.play("swing_pickaxe_left")
					_player_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
					_pickaxe_sprite.play("swing_left")
					_pickaxe_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.RIGHT:
					_player_sprite.play("swing_pickaxe_right")
					_player_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
					_pickaxe_sprite.play("swing_right")
					_pickaxe_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.UP:
					_player_sprite.play("swing_pickaxe_up")
					_player_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
					_pickaxe_sprite.play("swing_up")
					_pickaxe_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
				FacingDirection.DOWN:
					_player_sprite.play("swing_pickaxe_down")
					_player_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)
					_pickaxe_sprite.play("swing_down")
					_pickaxe_sprite.set_frame_and_progress(_pickaxe_swing_anim_frame, 0.0)

		# The player is not moving, use an idle animation.
		elif (velocity.is_zero_approx()):
			match _face_dir:
				FacingDirection.LEFT:
					_player_sprite.play("idle_left")
				FacingDirection.RIGHT:
					_player_sprite.play("idle_right")
				FacingDirection.UP:
					_player_sprite.play("idle_up")
				FacingDirection.DOWN:
					_player_sprite.play("idle_down")

		# The player is moving, use a running animation.
		else:
			match _face_dir:
				FacingDirection.LEFT:
					_player_sprite.play("run_left")
				FacingDirection.RIGHT:
					_player_sprite.play("run_right")
				FacingDirection.UP:
					_player_sprite.play("run_up")
				FacingDirection.DOWN:
					_player_sprite.play("run_down")

# Handles a tilemap being hit at a certain point. The hit_point parameter is in global coordinates.
func _handle_tilemap_hit_with_pickaxe(tilemap:TileMapLayer, hit_point:Vector2) -> void:
	
	# Hit tilemap must be part of the mine level
	var tilemap_parent:Node = tilemap.get_parent()
	if (tilemap_parent is MineLevel):
	
		# Get the hit point coordinates in the tilemap's local coordinate system.
		var tilemap_local_hit_point:Vector2 = tilemap.to_local(hit_point)
		
		# Get the coordinates of the cell that was hit.
		var hit_cell_coords:Vector2i = tilemap.local_to_map(tilemap_local_hit_point)
		
		# Call function on MineLevel to remove the tile at the hit cell.
		tilemap_parent.remove_tile(hit_cell_coords)

func _on_pickaxe_down_hitbox_body_entered(body: Node2D) -> void:
	
	if (body is TileMapLayer):
		_disable_pickaxe_hitbox()
		_handle_tilemap_hit_with_pickaxe(body, _pickaxe_down_hitbox_shape.global_position)

func _on_pickaxe_up_hitbox_body_entered(body: Node2D) -> void:
	
	if (body is TileMapLayer):
		_disable_pickaxe_hitbox()
		_handle_tilemap_hit_with_pickaxe(body, _pickaxe_up_hitbox_shape.global_position)

func _on_pickaxe_left_hitbox_body_entered(body: Node2D) -> void:
	
	if (body is TileMapLayer):
		_disable_pickaxe_hitbox()
		_handle_tilemap_hit_with_pickaxe(body, _pickaxe_left_hitbox_shape.global_position)

func _on_pickaxe_right_hitbox_body_entered(body: Node2D) -> void:
	
	if (body is TileMapLayer):
		_disable_pickaxe_hitbox()
		_handle_tilemap_hit_with_pickaxe(body, _pickaxe_right_hitbox_shape.global_position)
