class_name SlimeEnemy extends Area2D

@onready var _sprite:Sprite2D = $Sprite2D

# The distance squared away from the next point (in pixels) we have to be to consider ourselves at that point.
const MOVEMENT_PATH_POINT_REACHED_MARGIN:float = 16 #4-pixels

const DASH_TOTAL_TIME:float = 1.0

@export var _move_speed:int = 16
@export var _dash_telegraph_time:float = 1.0

# Should be set by the instantiator. Used for pathfinding.
var astar:AStarGrid2D = null

var _movement_point_path:PackedVector2Array = []
var _point_path_index:int = -1
var _dashing:bool = false
var _telegraphing:bool = false
var _telegraph_timer:float = _dash_telegraph_time
var _dash_timer:float = 0.0
# These two positions are in global coordinates.
var _dash_start_pos:Vector2 = Vector2.ZERO
var _dash_end_pos:Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	
	if (_movement_point_path.size() != 0):
		_handle_movement(delta)
	elif (!_telegraphing && !_dashing):
		_telegraph_dash()
	elif (_telegraph_timer > 0.0):
		_telegraph_timer -= delta
	elif (!_dashing):
		_start_dash()
	else:
		_update_dash(delta)

func _draw() -> void:
	
	# Draw pathfinding if visible paths is checked in the editor.
	if (get_tree().debug_paths_hint):
		for i:int in range(_movement_point_path.size() - 1):
			draw_line(to_local(_movement_point_path[i]), to_local(_movement_point_path[i + 1]), Color.GREEN, 1.0)
	
	# Only draw collision if we have visible collision shapes checked in the editor.
	if (get_tree().debug_collisions_hint):
		if (_telegraphing || _dashing):
			draw_line(to_local(_dash_start_pos), to_local(_dash_end_pos), Color.ORANGE, 1.0)

func _handle_movement(delta:float) -> void:
	
	# If we're at our destination, clear our path and return.
	if (_point_path_index >= _movement_point_path.size() - 1):
		_movement_point_path.clear()
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
	
	# Select a random tile in a 7x7 grid centered on this enemy.
	var x_off:int = randi_range(-3, 3)
	var y_off:int = randi_range(-3, 3)
	var new_tile:Vector2i = Vector2i(cur_tile.x + x_off, cur_tile.y + y_off)
	new_tile.x = clampi(new_tile.x, 0, astar.region.size.x - 1)
	new_tile.y = clampi(new_tile.y, 0, astar.region.size.y - 1)
	
	# Try and calculate the movement path.
	_movement_point_path = astar.get_point_path(cur_tile, new_tile)
	
	_point_path_index = -1
	
	# Update path visualization.
	queue_redraw()

func _telegraph_dash() -> void:
	
	var result:bool = _setup_dash_path()
	
	# If we couldn't set up a dash path, don't telegraph our dash, just try again later.
	if (!result):
		_calculate_new_movement_path()
		return
	
	# Begin telegraphing.
	_telegraphing = true
	_telegraph_timer = _dash_telegraph_time
	_sprite.region_rect.position.x = 16.0

# Returns true if the dash path was successfully set up, and false otherwise.
func _setup_dash_path() -> bool:
	
	# Get the tile this enemy is on.
	var cur_tile:Vector2i = (self.global_position * 0.0625) as Vector2i
	
	# Select a random tile from the edge of a 5x5 square centered on the enemy.
	var x_off:int = ((randi_range(0, 1) * 2) - 1) * 2
	var y_off:int = ((randi_range(0, 1) * 2) - 1) * 2
	var new_tile:Vector2i = Vector2i(cur_tile.x + x_off, cur_tile.y + y_off)
	new_tile.x = clampi(new_tile.x, 0, astar.region.size.x - 1)
	new_tile.y = clampi(new_tile.y, 0, astar.region.size.y - 1)
	
	# Try and calculate the dash path.
	var path:PackedVector2Array = astar.get_point_path(cur_tile, new_tile)
	
	# If the dash path couldn't be calculated, return.
	if (path.size() == 0):
		return false
	
	_dash_start_pos = global_position
	# Set the end of our dash to the end of our calculated path.
	_dash_end_pos = path[path.size() - 1]
	
	# If the dash path intersects a solid object, return.
	var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_dash_start_pos, _dash_end_pos)
	query.exclude = [self.get_rid()]
	query.collision_mask = 1
	var space_state:PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var result:Dictionary = space_state.intersect_ray(query)
	if (result):
		return false
	
	# Here to visualize the dash path.
	queue_redraw()
	
	return true

func _update_dash(delta:float) -> void:
	
	_dash_timer += delta
	
	# Plug the following into desmos exactly to see the function used for dashing: y=\sqrt[3]{\frac{x}{t}}
	# x: the amount of time that has passed.
	# y: the percent the enemy should be between the start and end positions.
	# t: the total amount of time for the dash.
	if (_dash_timer < DASH_TOTAL_TIME):
		var weight:float = pow(_dash_timer / DASH_TOTAL_TIME, 1.0 / 3.0)
		global_position = _dash_start_pos.lerp(_dash_end_pos, weight)
		
		# Update path visualization.
		queue_redraw()
	else:
		_finish_dash()

func _finish_dash() -> void:

	global_position = _dash_end_pos
	_dashing = false
	
	# Set our sprite back to default.
	_sprite.region_rect.position.x = 0.0
	
	# Start our new movement path.
	_calculate_new_movement_path()
	
	# Here to turn of dash visualization.
	queue_redraw()

func _start_dash() -> void:
	
	_telegraphing = false
	
	# Setup dash variables.
	_dashing = true
	_dash_timer = 0.0
	
	# Update the sprite to the dashing sprite
	_sprite.region_rect.position.x = 32.0

func _on_body_entered(body: Node2D) -> void:
	
	# If this enemy touches the player, kill them.
	if (body is PlayerCharacter):
		body.kill_player()
