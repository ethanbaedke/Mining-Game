class_name CannonheadEnemy extends Node2D

@onready var _head:Area2D = $Head
@onready var _head_sprite:Sprite2D = $Head/Sprite2D
@onready var _body:Area2D = $Body

@onready var _head_throw_sound_effect:SoundEffectPlayer = $HeadThrowSoundEffect

# The distance squared away from the next point (in pixels) we have to be to consider ourselves at that point.
const MOVEMENT_PATH_POINT_REACHED_MARGIN:float = 16 #4-pixels
# This distance is measured in cells.
const HEAD_THROW_MAX_DISTANCE:int = 10
const HEAD_THROW_LEFT_FAR_OFFSET:Vector2 = Vector2(-HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_RIGHT_FAR_OFFSET:Vector2 = Vector2(HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_UP_FAR_OFFSET:Vector2 = Vector2(0.0, -HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_DOWN_FAR_OFFSET:Vector2 = Vector2(0.0, HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_COOLDOWN:float = 2.0

@export var points_for_killed:int = 2

@export var _move_speed:int = 16
@export var _head_throw_telegraph_time:float = 1.0
@export var _head_throw_total_time_multiplier:float = 1.0

enum ThrowingDirection { LEFT, RIGHT, UP, DOWN }

# Should be set by the instantiator. Used for pathfinding.
var astar:AStarGrid2D = null

# Reference retrieved on ready.
var _mine_level:MineLevel = null

var _movement_point_path:PackedVector2Array = []
var _point_path_index:int = -1
var _head_throwing_direction:ThrowingDirection = ThrowingDirection.DOWN
var _throwing_head:bool = false
var _telegraphing:bool = false
var _head_throw_cooldown_timer:float = randf_range(0.0, HEAD_THROW_COOLDOWN)
var _telegraph_timer:float = _head_throw_telegraph_time
var _head_throw_total_time:float = 1.0
var _head_throw_timer:float = 0.0
# These two positions are in global coordinates.
var _head_throw_start_pos:Vector2 = Vector2.ZERO
var _head_throw_end_pos:Vector2 = Vector2.ZERO

func _ready() -> void:
	
	_mine_level = get_parent()

func _physics_process(delta: float) -> void:
	
	# Do no processing if the level is ending.
	if (_mine_level.level_cleanup_imminent):
		return
	
	if (_head_throw_cooldown_timer > 0.0):
		_head_throw_cooldown_timer -= delta
		_handle_movement(delta)
	elif (!_telegraphing && !_throwing_head):
		_telegraph_head_throw()
	elif (_telegraph_timer > 0.0):
		_telegraph_timer -= delta
	elif (!_throwing_head):
		_start_head_throw()
	else:
		_update_head_throw(delta)

func _draw() -> void:
	
	# Draw pathfinding if visible paths is checked in the editor.
	if (get_tree().debug_paths_hint):
		for i:int in range(_movement_point_path.size() - 1):
			draw_line(to_local(_movement_point_path[i]), to_local(_movement_point_path[i + 1]), Color.GREEN, 1.0)
	
	# Only draw collision if we have visible collision shapes checked in the editor.
	if (get_tree().debug_collisions_hint):
		draw_line(_head.position, _head.position + HEAD_THROW_LEFT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_RIGHT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_UP_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_DOWN_FAR_OFFSET, Color.RED, 1.0)
		if (_throwing_head):
			draw_line(self.to_local(_head_throw_start_pos), self.to_local(_head_throw_end_pos), Color.BLACK, 2.0)

func _handle_movement(delta:float) -> void:
	
	# If we're at our destination, calculate a new path.
	if (_point_path_index >= _movement_point_path.size() - 1):
		_calculate_new_movement_path()
		return
	
	# Grab info about our next point.
	var next_point:Vector2 = _movement_point_path[_point_path_index + 1]
	var vec_to_next_point:Vector2 = next_point - self.global_position
	
	# If we're at our next point, increment our point index
	if (vec_to_next_point.length_squared() < MOVEMENT_PATH_POINT_REACHED_MARGIN):
		_point_path_index += 1
	# Otherwise, move towards our next point.
	else:
		position += vec_to_next_point.normalized() * _move_speed * delta
		
		# Update path visualization.
		queue_redraw()

func _calculate_new_movement_path() -> void:
	
	# Get the tile this enemy is on.
	var cur_tile:Vector2i = (self.global_position * 0.0625) as Vector2i
	
	# Select a random tile in a 5x5 grid centered on this enemy.
	var x_off:int = randi_range(-2, 2)
	var y_off:int = randi_range(-2, 2)
	var new_tile:Vector2i = Vector2i(cur_tile.x + x_off, cur_tile.y + y_off)
	new_tile.x = clampi(new_tile.x, 0, astar.region.size.x - 1)
	new_tile.y = clampi(new_tile.y, 0, astar.region.size.y - 1)
	
	# Try and calculate the movement path.
	_movement_point_path = astar.get_point_path(cur_tile, new_tile)
	
	_point_path_index = -1
	
	# Update path visualization.
	queue_redraw()

func _telegraph_head_throw() -> void:
	
	_telegraphing = true
	_telegraph_timer = _head_throw_telegraph_time
	
	# Select a random direction to throw the head.
	_head_throwing_direction = randi_range(0, 3) as ThrowingDirection
	
	# Update the head sprite to telegraph this direction.
	match (_head_throwing_direction):
		ThrowingDirection.LEFT:
			_head_sprite.region_rect.position.x = 48.0
		ThrowingDirection.RIGHT:
			_head_sprite.region_rect.position.x = 64.0
		ThrowingDirection.UP:
			_head_sprite.region_rect.position.x = 80.0
		ThrowingDirection.DOWN:
			_head_sprite.region_rect.position.x = 96.0

func _update_head_throw(delta:float) -> void:
	
	_head_throw_timer += delta
	
	# Plug the following into desmos exactly to see the function used for head throwing: y\ =\ -\left(\left(\frac{x}{0.5t}\right)\ -\ 1\right)^{2}\ +\ 1
	# x: the amount of time that has passed.
	# y: the percent the head should be between the start and end positions.
	# t: the total amount of time for the head throw.
	if (_head_throw_timer < _head_throw_total_time):
		var weight:float = -pow(((_head_throw_timer / (_head_throw_total_time * 0.5)) - 1), 2) + 1
		_head.global_position = _head_throw_start_pos.lerp(_head_throw_end_pos, weight)
	else:
		_finish_head_throw()

func _finish_head_throw() -> void:

	_head.global_position = _head_throw_start_pos
	_head_throw_cooldown_timer = HEAD_THROW_COOLDOWN
	_throwing_head = false
	
	# Set our head sprite back to default.
	_head_sprite.region_rect.position.x = 16.0
	
	# Here to turn of throw path visualization.
	queue_redraw()

func _start_head_throw() -> void:
	
	_telegraphing = false
	
	# Setup head throw variables.
	_throwing_head = true
	_head_throw_timer = 0.0
	_head_throw_start_pos = _head.global_position
	
	# Update the head sprite to the throwing head sprite.
	_head_sprite.region_rect.position.x = 32.0
	
	# Raycast in the direction of the head throw to see if a wall is between the enemy and its max throw distance.
	# We set the end position of the throw to the cell in front of any wall we hit, or the cell at our max distance if no wall is in the way.
	var space_state:PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	match (_head_throwing_direction):
		ThrowingDirection.LEFT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_LEFT_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			query.collision_mask = 1
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(8.0, 0.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_LEFT_FAR_OFFSET
		ThrowingDirection.RIGHT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_RIGHT_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			query.collision_mask = 1
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(-8.0, 0.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_RIGHT_FAR_OFFSET
		ThrowingDirection.UP:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_UP_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			query.collision_mask = 1
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(0.0, 8.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_UP_FAR_OFFSET
		ThrowingDirection.DOWN:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_DOWN_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			query.collision_mask = 1
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(0.0, -8.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_DOWN_FAR_OFFSET
	
	# Scale the head throw time linearly with distance.
	_head_throw_total_time = _head_throw_start_pos.distance_to(_head_throw_end_pos) * .02 * _head_throw_total_time_multiplier
	
	# Here to visualize throw path.
	queue_redraw()
	
	# Play the head throw sound effect.
	_head_throw_sound_effect.play_effect()

# This handles another body enetering the head or body area's of this enemy.
# The "body" in the function title does not refer specifically to the body node of the enemy.
func _handle_body_entered(body:Node2D) -> void:
	
	# If this enemy touches the player, kill them.
	if (body is PlayerCharacter):
		body.kill_player()

func _on_head_body_entered(body: Node2D) -> void:
	_handle_body_entered(body)

func _on_body_body_entered(body: Node2D) -> void:
	_handle_body_entered(body)
