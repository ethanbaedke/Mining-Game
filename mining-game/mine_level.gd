class_name MineLevel extends Node2D

@onready var map_outline_layer:TileMapLayer = $MapOutlineLayer
@onready var wall_physical_layer:TileMapLayer = $WallPhysicalLayer
@onready var wall_visual_layer:TileMapLayer = $WallVisualLayer
@onready var floor_sprite:Sprite2D = $FloorSprite

@onready var player_character:PlayerCharacter = $PlayerCharacter
@onready var player_camera:Camera2D = $PlayerCharacter/Camera2D

const CAVE_HOLE_SCENE:PackedScene = preload("res://cave_hole.tscn")
const CANNONHEAD_ENEMY_SCENE:PackedScene = preload("res://cannonhead_enemy.tscn")
const SECRET_ROOM_SCENE:PackedScene = preload("res://secret_room.tscn")

const MAP_WIDTH:int = 64
const MAP_HEIGHT:int = 64
# The width and height of a secret area use the same minimum size.
const MIN_SECRET_AREA_SIZE:int = 3

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

# Reference retrieved on ready.
var _game_manager:GameManager = null

# Navigation
var _astar:AStarGrid2D = AStarGrid2D.new()

func remove_tile(cell_coordinates:Vector2i) -> void:
	
	# This call removes the tile at the input cell coordinates and updates the tiles of the surrounding cells using their terrain.
	wall_physical_layer.set_cells_terrain_connect([cell_coordinates], 0, -1)
	
	# Update the visual tilemap to reflect changes in the physical tilemap.
	_update_visual_tilemap_cell(cell_coordinates)
	for neighbor:TileSet.CellNeighbor in CELL_NEIGHBORS:
		var neighbor_coords:Vector2i = wall_visual_layer.get_neighbor_cell(cell_coordinates, neighbor)
		if (wall_visual_layer.get_cell_source_id(neighbor_coords) != -1):
			_update_visual_tilemap_cell(neighbor_coords)

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
		player_killed.emit()
	)
	
	# Set the player camera's bounds.
	player_camera.limit_left = -1 * 16
	player_camera.limit_right = (MAP_WIDTH + 1) * 16
	player_camera.limit_top = -1 * 16
	player_camera.limit_bottom = (MAP_HEIGHT + 1) * 16

# Set the player's position to the open tile closest to the center of the map.
func _set_player_starting_position(map:PackedByteArray) -> void:
	
	# Start at the center of the map and breadth first search for an open cell.
	var cell_queue:Array[Vector2i] = [Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5)]
	var processed_set:Dictionary[Vector2i, bool] = {}
	while (!cell_queue.is_empty()):
		
		# Get the next cell from the queue.
		var current:Vector2i = cell_queue.pop_front()
		processed_set[current] = true
		
		# If this cell is empty, move the player there and return.
		if (map[current.x + (current.y * MAP_WIDTH)] == 0):
			player_character.global_position = (current * 16.0) + Vector2(8.0, 8.0)
			map[current.x + (current.y * MAP_WIDTH)] = 1
			return
		# Otherwise, add its surrounding cells to the queue to be checked against.
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

# Generates the map and returns a row major PackedByteArray representing the 2d grid holding 1's in area's that are filled with objects.
func _generate_map() -> PackedByteArray:
	
	# A row major representation of where objects are on the map. As things are placed, 1's should be filled in their locations to say that those areas are reserved.
	var map:PackedByteArray = []
	map.resize(MAP_WIDTH * MAP_HEIGHT)
	
	_place_map_outline()
	
	# Create a RandomNumberGenerator object to handle randomness during generation.
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	
	# Place holes.
	for i:int in range(8):
		_place_hole(map, rng)
	
	# Stretch the floor sprite to cover the entire map.
	floor_sprite.position = Vector2(MAP_WIDTH * 16 * 0.5, MAP_HEIGHT * 16 * 0.5)
	floor_sprite.region_rect.size = Vector2((MAP_WIDTH + 1) * 16, (MAP_HEIGHT + 1) * 16)
	
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
	
	# Set the starting position of the player here, before placing secret rooms, so they don't spawn in one.
	_set_player_starting_position(map)
	
	_place_secret_rooms(map)
	
	# Setup our navigation here, since it should see physical tiles and holes.
	_astar.region = Rect2i(0, 0, MAP_WIDTH, MAP_HEIGHT)
	_astar.cell_size = Vector2(16.0, 16.0)
	_astar.offset = Vector2(8.0, 8.0)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			if (map[x + (y * MAP_WIDTH)] == 1):
				_astar.set_point_solid(Vector2i(x, y))
	
	_place_enemies(map, rng)
	
	return map

# Hollows wall sections and replaces them with secret rooms.
func _place_secret_rooms(map:PackedByteArray) -> void:
	
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
		_setup_secret_room(map, clipped_rect)

# Sets up one secret room over the input rect, which is considered to be in cell coordinates.
func _setup_secret_room(map:PackedByteArray, room_rect:Rect2i) -> void:
	
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
	
	# Iterate over the map.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			
			# For each empty cell, there is a 1% chance to spawn a cannonhead enemy.
			if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 99) == 0):
				
				# Spawn the cannonhead enemy.
				map[x + (y * MAP_WIDTH)] = 1
				var enemy:CannonheadEnemy = CANNONHEAD_ENEMY_SCENE.instantiate()
				enemy.position = Vector2((x * 16) + 8, (y * 16) + 8)
				# Pass pathfinding for this mine level to the enemy.
				enemy.astar = _astar
				self.add_child(enemy)

# Places a hole.
func _place_hole(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Find an open position to place the hole.
	# Random selection here is fine since holes are placed before anything else. It should only have to retry if another hole is already there.
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
			level_cleared.emit()
	)

# Outlines the map with unbreakable physical and visual tiles.
func _place_map_outline() -> void:
	
	# Horizontal borders on the top and bottom.
	for x:int in range(0, MAP_WIDTH):
		map_outline_layer.set_cell(Vector2i(x, -1), 2, Vector2i(4, 2))
		map_outline_layer.set_cell(Vector2i(x, MAP_HEIGHT), 2, Vector2i(4, 0))
		
	# Vertical borders on the left and right.
	for y:int in range(0, MAP_HEIGHT):
		map_outline_layer.set_cell(Vector2i(-1, y), 2, Vector2i(5, 1))
		map_outline_layer.set_cell(Vector2i(MAP_WIDTH, y), 2, Vector2i(3, 1))
		
	# Corners.
	map_outline_layer.set_cell(Vector2i(-1, -1), 2, Vector2i(1, 4))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, -1), 2, Vector2i(0, 4))
	map_outline_layer.set_cell(Vector2i(-1, MAP_HEIGHT), 2, Vector2i(1, 3))
	map_outline_layer.set_cell(Vector2i(MAP_WIDTH, MAP_HEIGHT), 2, Vector2i(0, 3))

# Updates a cell on the visual tilemap to match the cooresponding cell on the physical tilemap.
func _update_visual_tilemap_cell(cell_coordinates:Vector2i) -> void:
	
	# Get the TileSet coordinates of the tile present on the physical tilemap at the input cell coordinates.
	var atlas_coords:Vector2i = wall_physical_layer.get_cell_atlas_coords(cell_coordinates)
	
	# Set the visual tilemap to use the same tile on the same cell, but from it's own TileSet.
	wall_visual_layer.set_cell(cell_coordinates, 1, atlas_coords)
