class_name MineLevel extends Node2D

@onready var map_outline_layer:TileMapLayer = $MapOutlineLayer
@onready var wall_physical_layer:TileMapLayer = $WallPhysicalLayer
@onready var wall_visual_layer:TileMapLayer = $WallVisualLayer
@onready var floor_sprite:Sprite2D = $FloorSprite

@onready var player_character:PlayerCharacter = $PlayerCharacter
@onready var player_camera:Camera2D = $PlayerCharacter/Camera2D

const CAVE_HOLE_SCENE:PackedScene = preload("res://cave_hole.tscn")
const CANNONHEAD_ENEMY_SCENE:PackedScene = preload("res://cannonhead_enemy.tscn")

const MAP_WIDTH:int = 64
const MAP_HEIGHT:int = 64

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
	var map:PackedByteArray = _generate_map()
	
	# Place visual tiles for all physical tiles present in the wall_physical_layer.
	var used_cell_coords:Array[Vector2i] = wall_physical_layer.get_used_cells()
	for cell_coords:Vector2i in used_cell_coords:
		_update_visual_tilemap_cell(cell_coords)
		
	# Set the starting position of the player.
	_set_player_starting_position(map)
	
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

# Places enemies around the map.
func _place_enemies(map:PackedByteArray, rng:RandomNumberGenerator) -> void:
	
	# Iterate over the map.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			
			# For each empty cell, there is a 1% chance to spawn a cannonhead enemy.
			if (map[x + (y * MAP_WIDTH)] == 0 && rng.randi_range(0, 1) == 0):
				
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
