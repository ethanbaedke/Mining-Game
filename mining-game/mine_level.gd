class_name MineLevel extends Node2D

@onready var map_outline_layer:TileMapLayer = $MapOutlineLayer
@onready var wall_physical_layer:TileMapLayer = $WallPhysicalLayer
@onready var wall_visual_layer:TileMapLayer = $WallVisualLayer
@onready var floor_sprite:Sprite2D = $FloorSprite

@onready var player_character:PlayerCharacter = $PlayerCharacter
@onready var player_camera:Camera2D = $PlayerCharacter/Camera2D

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
	
	_generate_map()
	
	# Place visual tiles for all physical tiles present in the wall_physical_layer.
	var used_cell_coords:Array[Vector2i] = wall_physical_layer.get_used_cells()
	for cell_coords:Vector2i in used_cell_coords:
		_update_visual_tilemap_cell(cell_coords)
		
	_set_player_starting_position()
	
	# Set the player camera's bounds
	player_camera.limit_left = -1 * 16
	player_camera.limit_right = (MAP_WIDTH + 1) * 16
	player_camera.limit_top = -1 * 16
	player_camera.limit_bottom = (MAP_HEIGHT + 1) * 16

# Set the player's position to the open tile closest to the center of the map.
func _set_player_starting_position() -> void:
	
	# Start at the center of the map and breadth first search for an open cell.
	var cell_queue:Array[Vector2i] = [Vector2i(MAP_WIDTH * 0.5, MAP_HEIGHT * 0.5)]
	var processed_set:Dictionary[Vector2i, bool] = {}
	while (!cell_queue.is_empty()):
		
		# Get the next cell from the queue.
		var current:Vector2i = cell_queue.pop_front()
		processed_set[current] = true
		
		# If this cell is empty, move the player there and return.
		if (wall_physical_layer.get_cell_source_id(current) == -1):
			player_character.global_position = wall_physical_layer.map_to_local(current)
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

# Generates the map. Places the physical tiles on the map.
func _generate_map() -> void:
	
	_place_map_outline()
	
	floor_sprite.position = Vector2(MAP_WIDTH * 16 * 0.5, MAP_HEIGHT * 16 * 0.5)
	floor_sprite.region_rect.size = Vector2((MAP_WIDTH + 1) * 16, (MAP_HEIGHT + 1) * 16)
	
	# Use FastNoiseLite for our noise algorithm.
	var noise:FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	noise.frequency = 0.04
	
	# Generate a random seed for the noise alogirithm.
	var rng:RandomNumberGenerator = RandomNumberGenerator.new()
	noise.seed = rng.randi()
	
	# Place physical tiles.
	for y:int in range(MAP_HEIGHT):
		for x:int in range(MAP_WIDTH):
			if (noise.get_noise_2d(x, y) < -0.7):
				wall_physical_layer.set_cells_terrain_connect([Vector2i(x, y)], 0, 0)

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
