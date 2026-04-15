class_name Bomb extends Area2D

@onready var _collision_shape:CollisionShape2D = $CollisionShape2D

const EXPLODE_TIME:float = 1.0
const EXPLOSION_RADIUS:int = 2
const CAMERA_TRAUMA_ON_EXPLOSION:float = 1.0

var _mine_level:MineLevel = null
var _cell_position:Vector2i = Vector2i.ZERO

var _explode_timer:float = EXPLODE_TIME

func setup(mine_level:MineLevel, cell_position:Vector2i) -> void:
	_mine_level = mine_level
	_cell_position = cell_position

func _process(delta: float) -> void:
	
	# Do not allow this bomb to explode if the level is cleaning up.
	if (_mine_level.level_cleanup_imminent):
		return
	
	if (_explode_timer > 0.0):
		_explode_timer -= delta
	else:
		_handle_explosion()

func _handle_explosion() -> void:
	
	# Camera shake.
	_mine_level.player_camera.add_trauma(CAMERA_TRAUMA_ON_EXPLOSION)
	
	var area_hits:Array[Area2D] = get_overlapping_areas()
	var body_hits:Array[Node2D] = get_overlapping_bodies()
	
	# These will be enemies and hidden rooms.
	for area_hit:Area2D in area_hits:
		
		if (area_hit is SecretRoom):
			area_hit.unhide_room()
		if (area_hit is BugEnemy):
			area_hit.queue_free()
		elif (area_hit is SlimeEnemy):
			area_hit.queue_free()
		elif (area_hit.get_parent() is CannonheadEnemy):
			area_hit.get_parent().queue_free()
		
	# These will be rocks.
	for body_hit:Node2D in body_hits:
		
		if (body_hit is Rock):
			_mine_level.remove_rock(body_hit)
			
	# Handle removing walls.
	var circle:CircleShape2D = _collision_shape.shape as CircleShape2D
	# Round up here since we'll check every cell anyways and would rather oversample.
	var cell_radius:int = ceil(circle.radius / 16)
	
	for y:int in range(_cell_position.y - cell_radius, _cell_position.y + cell_radius + 1):
		for x:int in range(_cell_position.x - cell_radius, _cell_position.x + cell_radius + 1):
			var cell:Vector2i = Vector2i(x, y)
			if (cell.distance_to(_cell_position) <= cell_radius):
				_mine_level.remove_tile(cell)
	
	self.queue_free()
