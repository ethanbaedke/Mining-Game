class_name MineLevel extends Node2D

@onready var map_outline_layer:TileMapLayer = $MapOutlineLayer
@onready var wall_physical_layer:TileMapLayer = $WallPhysicalLayer
@onready var wall_visual_layer:TileMapLayer = $WallVisualLayer
@onready var floor_sprite:Sprite2D = $FloorSprite

@onready var player_character:PlayerCharacter = $PlayerCharacter
@onready var player_camera:Camera2D = $PlayerCharacter/Camera2D

const CAVE_HOLE_SCENE:PackedScene = preload("res://cave_hole.tscn")
const CANNONHEAD_ENEMY_SCENE:PackedScene = preload("res://cannonhead_enemy.tscn")
const CANNONHEAD_ENEMY_FAST_SCENE:PackedScene = preload("res://cannonhead_enemy_fast.tscn")
const SLIME_ENEMY_SCENE:PackedScene = preload("res://slime_enemy.tscn")
const SLIME_ENEMY_FAST_SCENE:PackedScene = preload("res://slime_enemy_fast.tscn")
const BUG_ENEMY_SCENE:PackedScene = preload("res://bug_enemy.tscn")
const BUG_ENEMY_FAST_SCENE:PackedScene = preload("res://bug_enemy_fast.tscn")
const GHOST_ENEMY_SCENE:PackedScene = preload("res://ghost_enemy.tscn")
const SECRET_ROOM_SCENE:PackedScene = preload("res://secret_room.tscn")
const COAL_ROCK_SCENE:PackedScene = preload("res://coal_rock.tscn")
const GOLD_ROCK_SCENE:PackedScene = preload("res://gold_rock.tscn")
const DIAMOND_ROCK_SCENE:PackedScene = preload("res://diamond_rock.tscn")
const BOMB_SCENE:PackedScene = preload("res://bomb.tscn")
const BETTER_BOMB_SCENE:PackedScene = preload("res://better_bomb.tscn")
const BEST_BOMB_SCENE:PackedScene = preload("res://best_bomb.tscn")

const ENEMY_SPAWN_TABLE:EnemySpawnTable = preload("res://enemy_spawn_table.tres")

const MAP_WIDTH:int = 64
const MAP_HEIGHT:int = 64
# The width and height of a secret area use the same minimum size.
const MIN_SECRET_AREA_SIZE:int = 3
const SECONDS_FROM_START_TO_GHOST_SPAWN:int = 70

const CELL_NEIGHBORS:Array[TileSet.CellNeighbor] = [
	TileSet.CellNeighbor.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CellNeighbor.CELL_NEIGHBOR_TOP_RIGHT_CORNER
]

signal level_cleared
signal player_killed
signal rock_broken(rock:Rock)
signal wall_broken_by_player
signal bomb_placed(bombType:int)

# Used by the HUD to modify the intensity of the screen effect applied when the ghost is spawned.
var time_since_ghost_spawned:float = 0.0

# Set to true when the level is cleared or the player dies.
var level_cleanup_imminent:bool = false

# Reference retrieved on ready.
var _game_manager:GameManager = null

# Navigation
var _astar:AStarGrid2D = AStarGrid2D.new()

var _ghost_spawned:bool = false
var _ghost_spawn_timer:float = SECONDS_FROM_START_TO_GHOST_SPAWN

func remove_tile(cell_coordinates:Vector2i, broken_by_player:bool = false) -> void:
	
	# Can't remove a tile from a cell that's already empty. This also handels out of bounds errors for us.
	if (wall_physical_layer.get_cell_source_id(cell_coordinates) == -1):
		return
	
	# This call removes the tile at the input cell coordinates and updates the tiles of the surrounding cells using their terrain.
	wall_physical_layer.set_cells_terrain_connect([cell_coordinates], 0, -1)
	
	# Update the visual tilemap to reflect changes in the physical tilemap.
	_update_visual_tilemap_cell(cell_coordinates)
	for neighbor:TileSet.CellNeighbor in CELL_NEIGHBORS:
		var neighbor_coords:Vector2i = wall_visual_layer.get_neighbor_cell(cell_coordinates, neighbor)
		if (wall_visual_layer.get_cell_source_id(neighbor_coords) != -1):
			_update_visual_tilemap_cell(neighbor_coords)
			
	# Update navigation so enemies can move into the newely empty space.
	_astar.set_point_solid(cell_coordinates, false)
	
	if (broken_by_player):
		wall_broken_by_player.emit()
	
func remove_rock(rock:Rock) -> void:
	
	rock_broken.emit(rock)
	
	# Update navigation so enemies can move into the newely empty space.
	var cell_coords:Vector2i = rock.position * 0.0625
	_astar.set_point_solid(cell_coords, false)
	
	# Let the rock handle removal itself.
	rock.break_rock()

func try_place_bomb(world_pos:Vector2) -> void:
	
	# Can't place a bomb if not enough coal has been collected.
	if (_game_manager.current_coal < _game_manager.COAL_NEEDED_FOR_BOMB):
		return
	
	var cell:Vector2i = wall_physical_layer.local_to_map(wall_physical_layer.to_local(world_pos))
	
	# If this assert fails, the player is inside a wall.
	assert(wall_physical_layer.get_cell_source_id(cell) == -1)
	
	var bomb:Bomb = null
	var bombType:int = 0
	if (_game_manager.current_coal < _game_manager.COAL_NEEDED_FOR_BOMB * 2):
		bomb = BOMB_SCENE.instantiate()
		bombType = 1
	elif (_game_manager.current_coal < _game_manager.COAL_NEEDED_FOR_BOMB * 3):
		bomb = BETTER_BOMB_SCENE.instantiate()
		bombType = 2
	else:
		bomb = BEST_BOMB_SCENE.instantiate()
		bombType = 3
	
	bomb.setup(self, cell)
	self.add_child(bomb)
	
	# The reason we convert our world position back and fourth is to center the bomb on the cell.
	bomb.global_position = wall_physical_layer.to_global(wall_physical_layer.map_to_local(cell))
	
	bomb_placed.emit(bombType)

func _ready() -> void:
	
	# Grab a reference to the game manager, which should be this nodes parent.
	_game_manager = get_parent()
	
	# Generate the map
	_generate_map()
	
	# Place visual tiles for all physical tiles present in the wall_physical_layer.
	var used_cell_coords:Array[Vector2i] = wall_physical_layer.get_used_cells()
	for cell_coords:Vector2i in used_cell_coords:
		_update_visual_tilemap_cell(cell_coords)
	
	# Listen for the player dying so we can fire our own event.
	player_character.player_killed.connect(func() -> void:
		level_cleanup_imminent = true
		player_killed.emit()
	)
	
	# Set the player camera's bounds.
	player_camera.limit_left = -1 * 16
	player_camera.limit_right = (MAP_WIDTH + 1) * 16
	player_camera.limit_top = -1 * 16
	player_camera.limit_bottom = (MAP_HEIGHT + 1) * 16

func _process(delta: float) -> void:
	
	if (!_ghost_spawned):
		if (_ghost_spawn_timer > 0):
			_ghost_spawn_timer -= delta
		else:
			_ghost_spawned = true
			_spawn_ghost()
	else:
		time_since_ghost_spawned += delta

# Generates the map and returns a row major PackedByteArray representing the 2d grid holding 1's in area's that are filled with objects.
func _generate_map() -> PackedByteArray:
	
	# A row major representation of where objects are on the map. This is filled out as the map is generated.
	# 0 -> An empty cell.
	# 1 -> A cell taken up by a static object (removed from navigation)
	# 2 -> A cell taken up by a non-static object (kept in navigation)
	var map:PackedByteArray = []
	map.resize(MAP_WIDTH * MAP_HEIGHT)
	
	# Create a RandomNumberGenerator object to handle randomness during generation.
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	
	# This is the first things we do since our navigation grid may be affected by things during generation, and needs to have valid properties.
	_setup_navigation()
	
	# These have NO EFFECT on the map.
	_place_map_outline()
	_place_floor()
	
	_place_walls(map, rng)
	
	# After placing walls but before placing secret rooms, so the player doesn't spawn inside of one.
	_place_player(map)
	
	_place_secret_rooms(map, rng)
	
	# NOTE: Prefereably, this goes right after secret rooms are placed. The algorithm to place holes can be slow if they must avoid many objects, so having this happen
	#  after secret rooms are carved out but before other entities are placed helps performance.
	_place_holes(map, rng)
	
	# NOTE: The spawn rates for the below entities are per-cell, so the higher-up calls will often have more of their entities placed in the overall level than lower-down calls.
	# In the future, an entity spawn chance table should be created that is parsed for each cell, with a high chance of it being empty.
	_place_enemies(map, rng)
	_place_coal_rocks(map, rng)
	_place_gold_rocks(map, rng)
	
	# This is the last thing we do so it can look at the final state of our map as it updates.
	_update_navigation(map)
	
	return map

func _place_coal_rocks(map:PackedByteArray, rng:RandomNumberGenerator) -> void:

	# Iterate over the map.
		for y:int in range(MAP_HEIGHT):
			for x:int in range(MAP_WIDTH):
				
				# For each empty cell, there is a 2% chance to spawn a coal rock.
				if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 49) == 0):
					
					# Spawn the coal rock.
					map[x + (y * MAP_WIDTH)] = 1
					var rock:Rock = COAL_ROCK_SCENE.instantiate()
					rock.position = Vector2((x * 16) + 8, (y * 16) + 8)
					self.add_child(rock)

func _place_gold_rocks(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Iterate over the map.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			
			# For each empty cell, there is a 1% chance to spawn a gold rock.
			if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 99) == 0):
				
				# Spawn the gold rock.
				map[x + (y * MAP_WIDTH)] = 1
				var rock:Rock = GOLD_ROCK_SCENE.instantiate()
				rock.position = Vector2((x * 16) + 8, (y * 16) + 8)
				self.add_child(rock)

# Sets up navigation without setting any points as solid.
func _setup_navigation() -> void:
	
	_astar.region = Rect2i(0, 0, MAP_WIDTH, MAP_HEIGHT)
	_astar.cell_size = Vector2(16.0, 16.0)
	_astar.offset = Vector2(8.0, 8.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()

# Fills in solid points.
func _update_navigation(map:PackedByteArray) -> void:
	
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			if (map[x + (y * MAP_WIDTH)] == 1):
				_astar.set_point_solid(Vector2i(x, y))

# Set the player's position to the open tile closest to the center of the map.
func _place_player(map:PackedByteArray) -> void:
	
	# Start at the center of the map and breadth first search for a 3x3 area of filled cells (to keep the player initially safe).
	var cell_queue:Array[Vector2i] = [Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5)]
	var processed_set:Dictionary[Vector2i, bool] = {}
	while (!cell_queue.is_empty()):
		
		# Get the next cell from the queue.
		var current:Vector2i = cell_queue.pop_front()
		processed_set[current] = true
		
		# Check if the cell is centered on a filled 3x3 grid.
		var surrounded:bool = true
		for y:int in range(current.y - 1, current.y + 2):
			for x:int in range(current.x - 1, current.x + 2):
				if (map[x + (y * MAP_WIDTH)] != 1):
					surrounded = false
					break
		
		# Success! Remove the center cell and place the player there.
		if (surrounded):
			remove_tile(current)
			player_character.global_position = (current * 16.0) + Vector2(8.0, 8.0)
			map[current.x + (current.y * MAP_WIDTH)] = 2
			return
			
		# Failure. Add the surrounding cells to the queue for processing.
		else:
			var left:Vector2i = Vector2i(current.x - 1, current.y)
			if (processed_set.get(left) == null):
				cell_queue.append(left)
			var right:Vector2i = Vector2i(current.x + 1, current.y)
			if (processed_set.get(right) == null):
				cell_queue.append(right)
			var top:Vector2i = Vector2i(current.x, current.y + 1)
			if (processed_set.get(top) == null):
				cell_queue.append(top)
			var bottom:Vector2i = Vector2i(current.x, current.y - 1)
			if (processed_set.get(bottom) == null):
				cell_queue.append(bottom)

func _place_floor() -> void:
	
	# Stretch the floor sprite to cover the entire map.
	floor_sprite.position = Vector2(MAP_WIDTH * 16 * 0.5, MAP_HEIGHT * 16 * 0.5)
	floor_sprite.region_rect.size = Vector2((MAP_WIDTH + 1) * 16, (MAP_HEIGHT + 1) * 16)

func _place_walls(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Use FastNoiseLite for our noise algorithm.
	var noise:FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	noise.frequency = 0.04
	
	# Generate a random seed for the noise alogirithm.
	noise.seed = rng.randi()
	
	# Place physical tiles.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			if (noise.get_noise_2d(x, y) < -0.7):
				wall_physical_layer.set_cells_terrain_connect([Vector2i(x, y)], 0, 0)
				map[x + (y * MAP_WIDTH)] = 1

# Hollows wall sections and replaces them with secret rooms.
func _place_secret_rooms(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Place secret rooms until the largest available area doesn't meet our size requirement.
	# NOTE: One issue here is that the largest rectangular area could be long and really thin. By having one dimension that doesn't meet our minimum size requirements,
	#        we will return even though there are many other spaces to put secret rooms. This is okay for now, since it adds some randomness to how many secret rooms will spawn.
	#         However, this issue should be noted and possibly ammended later.
	while (true):
		
		# Find largest filled rectangular area on map for secret room.
		var rect:Rect2i = _get_largest_wall_rect()
		
		# Ensure the area is big enough to fit a secret room. We -4 here since we leave two filled cells of space around the edges of the secret room.
		if (rect.size.x - 4 < MIN_SECRET_AREA_SIZE || rect.size.y - 4 < MIN_SECRET_AREA_SIZE):
			return
		
		var clipped_rect:Rect2i = Rect2i(rect.position + Vector2i(2, 2), rect.size - Vector2i(4, 4))
		_place_secret_room(map, clipped_rect, rng)

# Sets up one secret room over the input rect, which is considered to be in cell coordinates.
func _place_secret_room(map:PackedByteArray, room_rect:Rect2i, rng:RandomNumberGenerator) -> void:
	
	# Remove all cells from the secret rooms area.
	var start:Vector2i = room_rect.position
	var end:Vector2i = room_rect.position + room_rect.size
	for y:int in range(start.y, end.y):
		for x:int in range(start.x, end.x):
			remove_tile(Vector2i(x, y))
			map[x + (y * MAP_WIDTH)] = 0
			
	# Spawn the secret room.
	var room:SecretRoom = SECRET_ROOM_SCENE.instantiate()
	self.add_child(room)
	room.position = start * 16
	room.set_size(room_rect.size)
	
	# Place diamond rocks in the secret room.
	_place_diamond_rocks(map, room_rect, rng)

# Places diamond rocks randomly within the input rect's area.
func _place_diamond_rocks(map:PackedByteArray, rect:Rect2i, rng:RandomNumberGenerator) -> void:
	
	# Iterate over the rect's area.
	var start:Vector2i = rect.position
	var end:Vector2i = rect.position + rect.size
	for y:int in range(start.y, end.y):
		for x:int in range(start.x, end.x):
			
			# For each empty cell, there is a 2% chance to spawn a diamond rock.
			if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 24) == 0):
				
				# Spawn the diamond rock.
				map[x + (y * MAP_WIDTH)] = 1
				var rock:Rock = DIAMOND_ROCK_SCENE.instantiate()
				rock.position = Vector2((x * 16) + 8, (y * 16) + 8)
				self.add_child(rock)

# Returns a rect, in cell coordinates, representing the largest wall rectangle in the map.
func _get_largest_wall_rect() -> Rect2i:
	
	var max_area:int = 0
	var best_rect:Rect2i = Rect2i(0, 0, 0, 0)
	
	# Tracks the amount of walls in each column of the map.
	var heights:Array[int] = []
	heights.resize(MAP_WIDTH)
	
	for y:int in range(MAP_HEIGHT):
		
		# Loop over every cell in the row, adding to it's height if a wall exists there and resetting it's height if not.
		for x:int in range(MAP_WIDTH):
			if (wall_physical_layer.get_cell_source_id(Vector2i(x, y)) != -1):
				heights[x] += 1
			else:
				heights[x] = 0
		
		# Find the largest wall rect within our currently processed rows.
		var rect:Rect2i = _get_largest_wall_rect_from_sub_histogram(heights, y)
		
		# Update the largest found rectangle if this one beats our previous.
		var area:int = rect.size.x * rect.size.y
		if (area > max_area):
			max_area = area
			best_rect = rect
			
	return best_rect

# Should only be called by _get_largest_wall_rect
func _get_largest_wall_rect_from_sub_histogram(heights:Array[int], current_row:int) -> Rect2i:
	
	# Each entry in left/right holds the location of the closest left/right height that is smaller than itself.
	var left:Array[int] = []
	left.resize(MAP_WIDTH)
	var right:Array[int] = []
	right.resize(MAP_WIDTH)
	var stack:Array[int] = []
	
	# Fill out the left array.
	for i:int in range(MAP_WIDTH):
		while (!stack.is_empty() && heights[stack[stack.size() - 1]] >= heights[i]):
			stack.remove_at(stack.size() - 1)
		if (stack.is_empty()):
			left[i] = -1
		else:
			left[i] = stack[stack.size() - 1]
		stack.append(i)
		
	# Fill out the right array.
	for i:int in range(MAP_WIDTH - 1, -1, -1):
		while (!stack.is_empty() && heights[stack[stack.size() - 1]] >= heights[i]):
			stack.remove_at(stack.size() - 1)
		if (stack.is_empty()):
			right[i] = MAP_WIDTH
		else:
			right[i] = stack[stack.size() - 1]
		stack.append(i)
		
	# Find the max rect
	var max_area:int = 0
	var best_rect:Rect2i = Rect2i(0, 0, 0, 0)
	for i:int in range(MAP_WIDTH):
		var width:int = right[i] - left[i] - 1
		var area:int = heights[i] * width
		if (area > max_area):
			max_area = area
			best_rect = Rect2i(left[i] + 1, (current_row - heights[i]) + 1, width, heights[i])
			
	return best_rect

# Places enemies around the map.
func _place_enemies(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Get the row in the spawn table to use.
	var table_row:EnemySpawnTableRow = ENEMY_SPAWN_TABLE.get_row_from_floor(_game_manager.current_floor)
	
	if (table_row == null || table_row.enemy_pool.size() == 0):
		return
	
	# Iterate over the map.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			
			# For each empty cell, roll to spawn an enemy
			if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 99) < table_row.spawn_chance):
				
				# Select an enemy from the pool.
				var pool_ind:int = randi_range(0, table_row.enemy_pool.size() - 1)
				var enemy_type:EnemySpawnTableRow.EnemyType = table_row.enemy_pool[pool_ind]
				match (enemy_type):
					EnemySpawnTableRow.EnemyType.CANNONHEAD:
						# Spawn the cannonhead enemy.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:CannonheadEnemy = CANNONHEAD_ENEMY_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						self.add_child(enemy)
					EnemySpawnTableRow.EnemyType.CANNONHEAD_FAST:
						# Spawn the fast cannonhead enemy variant.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:CannonheadEnemy = CANNONHEAD_ENEMY_FAST_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						self.add_child(enemy)
					EnemySpawnTableRow.EnemyType.SLIME:
						# Spawn the slime enemy.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:SlimeEnemy = SLIME_ENEMY_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						self.add_child(enemy)
					EnemySpawnTableRow.EnemyType.SLIME_FAST:
						# Spawn the slime enemy.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:SlimeEnemy = SLIME_ENEMY_FAST_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						self.add_child(enemy)
					EnemySpawnTableRow.EnemyType.BUG:
						# Spawn the bug enemy.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:BugEnemy = BUG_ENEMY_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						# Pass player character to the enemy.
						enemy.player_character = player_character
						self.add_child(enemy)
					EnemySpawnTableRow.EnemyType.BUG_FAST:
						# Spawn the bug enemy.
						map[x + (y * MAP_WIDTH)] = 2
						var enemy:BugEnemy = BUG_ENEMY_FAST_SCENE.instantiate()
						enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
						# Pass pathfinding for this mine level to the enemy.
						enemy.astar = _astar
						# Pass player character to the enemy.
						enemy.player_character = player_character
						self.add_child(enemy)

func _place_holes(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	for i:int in range(4):
		_place_hole(map, rng)

func _place_hole(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Find an open position to place the hole.
	# WARNING: This could take a LONG time.
	var hole_pos:Vector2i = Vector2i.ZERO
	while (true):
		hole_pos = Vector2(rng.randi_range(1, (MAP_WIDTH - 2)), rng.randi_range(1, (MAP_HEIGHT - 2)))
		if (map[hole_pos.x + (hole_pos.y * MAP_WIDTH)] == 0):
			break

	map[hole_pos.x + (hole_pos.y * MAP_WIDTH)] = 1
	var hole:Area2D = CAVE_HOLE_SCENE.instantiate()
	hole.position = hole_pos * 16
	self.add_child(hole)
	
	# If the player touches the hole, move to the next floor.
	hole.body_entered.connect(func(body:Node2D) -> void:
		if (body == player_character):
			level_cleanup_imminent = true
			level_cleared.emit()
	)

# Outlines the map with unbreakable physical and visual tiles.
func _place_map_outline() -> void:
	
	# Horizontal borders on the top and bottom, 2-thick.
	for x:int in range(0, MAP_WIDTH):
		map_outline_layer.set_cell(Vector2i(x, -2), 2, Vector2i(4, 1))
		map_outline_layer.set_cell(Vector2i(x, -1), 2, Vector2i(4, 2))
		map_outline_layer.set_cell(Vector2i(x, MAP_HEIGHT), 2, Vector2i(4, 0))
		map_outline_layer.set_cell(Vector2i(x, MAP_HEIGHT + 1), 2, Vector2i(4, 1))
		
	# Vertical borders on the left and right 2-thick.
	for y:int in range(0, MAP_HEIGHT):
		map_outline_layer.set_cell(Vector2i(-2, y), 2, Vector2i(4, 1))
		map_outline_layer.set_cell(Vector2i(-1, y), 2, Vector2i(5, 1))
		map_outline_layer.set_cell(Vector2i(MAP_WIDTH, y), 2, Vector2i(3, 1))
		map_outline_layer.set_cell(Vector2i(MAP_WIDTH + 1, y), 2, Vector2i(4, 1))
		
	# Corners.
	# Top left.
	map_outline_layer.set_cell(Vector2i(-1, -1), 2, Vector2i(1, 4))
	map_outline_layer.set_cell(Vector2i(-2, -1), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(-1, -2), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(-2, -2), 2, Vector2i(4, 1))
	# Top right.
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, -1), 2, Vector2i(0, 4))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH + 1, -1), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, -2), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH + 1, -2), 2, Vector2i(4, 1))
	# Bottom left.
	map_outline_layer.set_cell(Vector2i(-1, MAP_HEIGHT), 2, Vector2i(1, 3))
	map_outline_layer.set_cell(Vector2i(-2, MAP_HEIGHT), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(-1, MAP_HEIGHT + 1), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(-2, MAP_HEIGHT + 1), 2, Vector2i(4, 1))
	# Bottom right.
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, MAP_HEIGHT), 2, Vector2i(0, 3))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH + 1, MAP_HEIGHT), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, MAP_HEIGHT + 1), 2, Vector2i(4, 1))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH + 1, MAP_HEIGHT + 1), 2, Vector2i(4, 1))

# Updates a cell on the visual tilemap to match the cooresponding cell on the physical tilemap.
func _update_visual_tilemap_cell(cell_coordinates:Vector2i) -> void:
	
	# Get the TileSet coordinates of the tile present on the physical tilemap at the input cell coordinates.
	var atlas_coords:Vector2i = wall_physical_layer.get_cell_atlas_coords(cell_coordinates)
	
	# Set the visual tilemap to use the same tile on the same cell, but from it's own TileSet.
	wall_visual_layer.set_cell(cell_coordinates, 1, atlas_coords)

func _spawn_ghost() -> void:
	
	var ghost:GhostEnemy = GHOST_ENEMY_SCENE.instantiate()
	ghost.player_character = player_character
	
	var spawn:int = randi_range(0, 3)
	match (spawn):
		0:	# Top left
			ghost.position = Vector2(-32.0, -32.0)
		1:	# Top right
			ghost.position = Vector2((MAP_WIDTH + 2) * 16.0, -32.0)
		2:	# Bottom left
			ghost.position = Vector2(-32.0, (MAP_HEIGHT + 2) * 16.0)
		3:	# Bottom right
			ghost.position = Vector2((MAP_WIDTH + 2) * 16.0, (MAP_HEIGHT + 2) * 16.0)
	
	self.add_child(ghost)
