class_name CannonheadEnemy extends Node2D

@onready var _head:Area2D = $Head
@onready var _body:Area2D = $Body

# This distance is measured in cells.
const HEAD_THROW_MAX_DISTANCE:int = 10
const HEAD_THROW_LEFT_FAR_OFFSET:Vector2 = Vector2(-HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_RIGHT_FAR_OFFSET:Vector2 = Vector2(HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_UP_FAR_OFFSET:Vector2 = Vector2(0.0, -HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_DOWN_FAR_OFFSET:Vector2 = Vector2(0.0, HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_COOLDOWN:float = 1.0

enum ThrowingDirection { LEFT, RIGHT, UP, DOWN }

var _head_throwing_direction:ThrowingDirection = ThrowingDirection.DOWN
var _throwing_head:bool = false
var _head_throw_cooldown_timer:float = HEAD_THROW_COOLDOWN
var _head_throw_total_time:float = 1.0
var _head_throw_timer:float = 0.0
# These two positions are in global coordinates.
var _head_throw_start_pos:Vector2 = Vector2.ZERO
var _head_throw_end_pos:Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	
	if (_head_throw_cooldown_timer > 0.0):
		_head_throw_cooldown_timer -= delta
	elif (!_throwing_head):
		_start_head_throw()
	else:
		_update_head_throw(delta)

func _draw() -> void:
	
	# Only draw if we have visible collision shapes checked in the editor.
	if (get_tree().debug_collisions_hint):
		draw_line(_head.position, _head.position + HEAD_THROW_LEFT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_RIGHT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_UP_FAR_OFFSET, Color.RED, 1.0)
		draw_line(_head.position, _head.position + HEAD_THROW_DOWN_FAR_OFFSET, Color.RED, 1.0)
		if (_throwing_head):
			draw_line(self.to_local(_head_throw_start_pos), self.to_local(_head_throw_end_pos), Color.ORANGE, 2.0)

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
	
	# Here to turn of throw path visualization.
	queue_redraw()

func _start_head_throw() -> void:
	
	# Setup head throw variables.
	_throwing_head = true
	_head_throw_timer = 0.0
	_head_throw_start_pos = _head.global_position
	
	# Select a random direction to throw the head.
	_head_throwing_direction = randi_range(0, 3) as ThrowingDirection
	
	# Raycast in the direction of the head throw to see if a wall is between the enemy and its max throw distance.
	# We set the end position of the throw to the cell in front of any wall we hit, or the cell at our max distance if no wall is in the way.
	var space_state:PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	match (_head_throwing_direction):
		ThrowingDirection.LEFT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_LEFT_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(8.0, 0.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_LEFT_FAR_OFFSET
		ThrowingDirection.RIGHT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_RIGHT_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(-8.0, 0.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_RIGHT_FAR_OFFSET
		ThrowingDirection.UP:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_UP_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(0.0, 8.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_UP_FAR_OFFSET
		ThrowingDirection.DOWN:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(_head_throw_start_pos, _head_throw_start_pos + HEAD_THROW_DOWN_FAR_OFFSET)
			query.exclude = [_head.get_rid(), _body.get_rid()]
			var result:Dictionary = space_state.intersect_ray(query)
			if (result):
				_head_throw_end_pos = result.position + Vector2(0.0, -8.0)
			else:
				_head_throw_end_pos = _head_throw_start_pos + HEAD_THROW_DOWN_FAR_OFFSET
	
	# Scale the head throw time linearly with distance.
	_head_throw_total_time = _head_throw_start_pos.distance_to(_head_throw_end_pos) * .02
				
	# Here to visualize throw path.
	queue_redraw()

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
