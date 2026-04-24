class_name BugEnemy extends Area2D

# The distance squared away from the next point (in pixels) we have to be to consider ourselves at that point.
const MOVEMENT_PATH_POINT_REACHED_MARGIN:float = 16 #4-pixels
# The distance squared away from the player the enemy has to be within to move directly towards them instead of following it's path.
const DIRECT_MOVEMENT_MARGIN:float = 256 #16-pixels

@export var points_for_killed:int = 1
@export var color_for_score_effect:Color = Color.WHITE

@export var _move_speed:int = 16

# Should be set by the instantiator. Used for pathfinding.
var astar:AStarGrid2D = null
var player_character:PlayerCharacter = null

# Reference retrieved on ready.
var _mine_level:MineLevel = null

var _movement_point_path:PackedVector2Array = []
var _point_path_index:int = 0

func _ready() -> void:
	
	_mine_level = get_parent()

func _physics_process(delta: float) -> void:
	
	# Do no processing if the level is ending.
	if (_mine_level.level_cleanup_imminent):
		return
	
	# Must have a reference to the player character to function.
	if (player_character == null):
		return
		
	_handle_movement(delta)

func _draw() -> void:
	
	# Draw pathfinding if visible paths is checked in the editor.
	if (get_tree().debug_paths_hint):
		for i:int in range(_movement_point_path.size() - 1):
			draw_line(to_local(_movement_point_path[i]), to_local(_movement_point_path[i + 1]), Color.GREEN, 1.0)

func _handle_movement(delta:float) -> void:
	
	var to_player:Vector2 = player_character.global_position - self.global_position
	var dist_sqrd_to_player:float = to_player.length_squared()
	
	# If close enough to the player, move directly towards them.
	if (dist_sqrd_to_player <= DIRECT_MOVEMENT_MARGIN):
		position += to_player.normalized() * _move_speed * delta
		
		# These are for debug drawing.
		_movement_point_path.clear()
		queue_redraw()
		
		return
	
	# Otherwise, calculate a path towards them.
	_calculate_new_movement_path()
	
	# If the enemy can't get to the player, return.
	if (_movement_point_path.size() < 2):
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
	
	var player_cell:Vector2i = player_character.global_position * 0.0625
	var enemy_cell:Vector2i = self.global_position * 0.0625
	
	# NOTE: Calling this every frame could be extremely slow. Look here if performance becomes and issue and cap the amount of times a new path is generated per second.
	_movement_point_path = astar.get_point_path(enemy_cell, player_cell)
	
	_point_path_index = 0
	
	# Update path visualization.
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:

	# If this enemy touches the player, kill them.
	if (body is PlayerCharacter):
		body.kill_player()
