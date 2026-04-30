class_name SplashScreen extends Node2D

@onready var _terrain_tiles:TileMapLayer = $TerrainTiles
@onready var _visual_tiles:TileMapLayer = $VisualTiles
@onready var _animation_player:AnimationPlayer = $AnimationPlayer
@onready var _wall_break_sound_effect:SoundEffectPlayer = $WallBreakSoundEffect

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

const LETTER_OUTLINE_REMOVE_LIST:Array[Vector2i] = [
	# Top.
	Vector2i(3, 5),
	Vector2i(4, 5),
	Vector2i(5, 5),
	
	# Bottom.
	Vector2i(3, 11),
	Vector2i(4, 11),
	Vector2i(5, 11),
	
	# Right.
	Vector2i(6, 5),
	Vector2i(6, 6),
	Vector2i(6, 7),
	Vector2i(6, 8),
	Vector2i(6, 9),
	Vector2i(6, 10),
	Vector2i(6, 11),
]

const B_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(5, 6),
	Vector2i(5, 8),
	Vector2i(5, 10),
	Vector2i(4, 7),
	Vector2i(4, 9),
]

const A_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(7, 6),
	Vector2i(9, 6),
	Vector2i(8, 7),
	Vector2i(8, 9),
	Vector2i(8, 10),
]

const D_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(13, 6),
	Vector2i(13, 10),
	Vector2i(12, 7),
	Vector2i(12, 8),
	Vector2i(12, 9),
]

const K_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(16, 6),
	Vector2i(16, 7),
	Vector2i(16, 9),
	Vector2i(16, 10),
	Vector2i(17, 8),
]

const E_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(20, 7),
	Vector2i(21, 7),
	Vector2i(20, 9),
	Vector2i(21, 9),
	Vector2i(21, 8),
]

const Y_REMOVE_LIST:Array[Vector2i] = [
	Vector2i(24, 6),
	Vector2i(24, 7),
	Vector2i(23, 9),
	Vector2i(23, 10),
	Vector2i(25, 9),
	Vector2i(25, 10),
]

signal finished

func _ready() -> void:
	
	# Place visual tiles for all tiles present in the terrain layer.
	var used_cell_coords:Array[Vector2i] = _terrain_tiles.get_used_cells()
	for cell_coords:Vector2i in used_cell_coords:
		_update_visual_tilemap_cell(cell_coords)
		
	await _play_wall_break_animation()
	await _play_logo_animation()
	
	finished.emit()

func _play_logo_animation() -> void:
	
	_animation_player.play("logo")
	await _animation_player.animation_finished

func _play_wall_break_animation() -> void:
	
	# Create six copies of the outline array, offset them, add their letter arrays, and shuffle them.
	var full_arrays:Array[Array]
	var letter_arrays:Array[Array] = [
		B_REMOVE_LIST.duplicate(true),
		A_REMOVE_LIST.duplicate(true),
		D_REMOVE_LIST.duplicate(true),
		K_REMOVE_LIST.duplicate(true),
		E_REMOVE_LIST.duplicate(true),
		Y_REMOVE_LIST.duplicate(true),
	]
	for i:int in range(6):
		var arr:Array[Vector2i] = letter_arrays[i].duplicate(true)
		for tile:Vector2i in LETTER_OUTLINE_REMOVE_LIST:
			arr.append(tile + Vector2i(i * 4, 0))
		arr.shuffle()
		full_arrays.append(arr)
	
	# Remove a single y first since it has one more at the end and looks weird
	_remove_tile(full_arrays[5][full_arrays[5].size() - 1])
	full_arrays[5].remove_at(full_arrays[5].size() - 1)
	
	# Remove all the outlines.
	var letters_finished:Array[bool] = [false, false, false, false, false, false]
	var tile_ind:int = 0
	while (letters_finished.find(false) != -1):
		for letter_ind:int in range(6):
			if (tile_ind < full_arrays[letter_ind].size()):
				_remove_tile(full_arrays[letter_ind][tile_ind])
			else:
				letters_finished[letter_ind] = true
		tile_ind += 1
		if (letters_finished.find(false) != -1):
			_wall_break_sound_effect.play_effect()
		await get_tree().create_timer(0.002 * (tile_ind * tile_ind)).timeout

# Updates a cell on the visual tilemap to match the cooresponding cell on the terrain tilemap.
func _update_visual_tilemap_cell(cell_coordinates:Vector2i) -> void:
	
	# Get the TileSet coordinates of the tile present on the terrain tilemap at the input cell coordinates.
	var atlas_coords:Vector2i = _terrain_tiles.get_cell_atlas_coords(cell_coordinates)
	
	# Set the visual tilemap to use the same tile on the same cell, but from it's own TileSet.
	_visual_tiles.set_cell(cell_coordinates, 1, atlas_coords)

func _remove_tile(cell_coordinates:Vector2i) -> void:
	
	# Can't remove a tile from a cell that's already empty. This also handels out of bounds errors for us.
	if (_terrain_tiles.get_cell_source_id(cell_coordinates) == -1):
		return
	
	# This call removes the tile at the input cell coordinates and updates the tiles of the surrounding cells using their terrain.
	_terrain_tiles.set_cells_terrain_connect([cell_coordinates], 0, -1)
	
	# Update the visual tilemap to reflect changes in the physical tilemap.
	_update_visual_tilemap_cell(cell_coordinates)
	for neighbor:TileSet.CellNeighbor in CELL_NEIGHBORS:
		var neighbor_coords:Vector2i = _visual_tiles.get_neighbor_cell(cell_coordinates, neighbor)
		if (_visual_tiles.get_cell_source_id(neighbor_coords) != -1):
			_update_visual_tilemap_cell(neighbor_coords)
