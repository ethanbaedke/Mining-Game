class_name CannonheadEnemy extends Node2D

@onready var _head:Area2D = $Head

# This distance is measured in cells.
const HEAD_THROW_MAX_DISTANCE:int = 10
const HEAD_THROW_LEFT_FAR_OFFSET:Vector2 = Vector2(-HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_RIGHT_FAR_OFFSET:Vector2 = Vector2(HEAD_THROW_MAX_DISTANCE * 16.0, 0.0)
const HEAD_THROW_UP_FAR_OFFSET:Vector2 = Vector2(0.0, -HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_DOWN_FAR_OFFSET:Vector2 = Vector2(0.0, HEAD_THROW_MAX_DISTANCE * 16.0)
const HEAD_THROW_COOLDOWN:float = 1.0

enum ThrowingDirection { LEFT, RIGHT, UP, DOWN }

# Used for random decision making.
var _rng:RandomNumberGenerator = RandomNumberGenerator.new()

var _head_throwing_direction:ThrowingDirection = ThrowingDirection.DOWN
var _throwing_head:bool = false
var _head_throw_cooldown_timer:float = HEAD_THROW_COOLDOWN

func _physics_process(delta: float) -> void:
	
	if (_head_throw_cooldown_timer > 0.0):
		_head_throw_cooldown_timer -= delta
	elif (!_throwing_head):
		_start_head_throw()

func _draw() -> void:
	
	# Only draw if we have visible collision shapes checked in the editor.
	if (get_tree().debug_collisions_hint):
		draw_line(Vector2(0.0, 0.0), HEAD_THROW_LEFT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(Vector2(0.0, 0.0), HEAD_THROW_RIGHT_FAR_OFFSET, Color.RED, 1.0)
		draw_line(Vector2(0.0, 0.0), HEAD_THROW_UP_FAR_OFFSET, Color.RED, 1.0)
		draw_line(Vector2(0.0, 0.0), HEAD_THROW_DOWN_FAR_OFFSET, Color.RED, 1.0)

func _start_head_throw() -> void:
	
	_throwing_head = true
	
	# Select a random direction to throw the head.
	# TESTING: Only throws left right now.
	_head_throwing_direction = randi_range(0, 3) as ThrowingDirection
	
	var space_state:PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	match (_head_throwing_direction):
		ThrowingDirection.LEFT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2.ZERO, HEAD_THROW_LEFT_FAR_OFFSET)
			var result:Dictionary = space_state.intersect_ray(query)
			print(result)
		ThrowingDirection.RIGHT:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2.ZERO, HEAD_THROW_RIGHT_FAR_OFFSET)
			var result:Dictionary = space_state.intersect_ray(query)
			print(result)
		ThrowingDirection.UP:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2.ZERO, HEAD_THROW_UP_FAR_OFFSET)
			var result:Dictionary = space_state.intersect_ray(query)
			print(result)
		ThrowingDirection.DOWN:
			var query:PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(Vector2.ZERO, HEAD_THROW_DOWN_FAR_OFFSET)
			var result:Dictionary = space_state.intersect_ray(query)
			print(result)

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
