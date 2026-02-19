class_name MineLevel extends Node2D

@onready var wallPhysicalLayer:TileMapLayer = $WallPhysicalLayer
@onready var wallVisualLayer:TileMapLayer = $WallVisualLayer

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
	wallPhysicalLayer.set_cells_terrain_connect([cell_coordinates], 0, -1)
	
	# Update the visual tilemap to reflect changes in the physical tilemap.
	_update_visual_tilemap_cell(cell_coordinates)
	for neighbor:TileSet.CellNeighbor in CELL_NEIGHBORS:
		var neighbor_coords:Vector2i = wallVisualLayer.get_neighbor_cell(cell_coordinates, neighbor)
		if (wallVisualLayer.get_cell_source_id(neighbor_coords) != -1):
			_update_visual_tilemap_cell(neighbor_coords)

func _ready() -> void:
	
	# Place visual tiles for all physical tiles present in the wallPhysicalLayer.
	var used_cell_coords:Array[Vector2i] = wallPhysicalLayer.get_used_cells()
	for cell_coords:Vector2i in used_cell_coords:
		_update_visual_tilemap_cell(cell_coords)

# Updates a cell on the visual tilemap to match the cooresponding cell on the physical tilemap.
func _update_visual_tilemap_cell(cell_coordinates:Vector2i) -> void:
	
	# Get the TileSet coordinates of the tile present on the physical tilemap at the input cell coordinates.
	var atlas_coords:Vector2i = wallPhysicalLayer.get_cell_atlas_coords(cell_coordinates)
	
	# Set the visual tilemap to use the same tile on the same cell, but from it's own TileSet.
	wallVisualLayer.set_cell(cell_coordinates, 1, atlas_coords)
