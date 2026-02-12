class_name MineLevel extends Node2D

@onready var wallPhysicalLayer:TileMapLayer = $WallPhysicalLayer
@onready var wallVisualLayer:TileMapLayer = $WallVisualLayer

func _ready() -> void:
	
	# Place visual tiles for all physical tiles present in the wallPhysicalLayer
	var used_cell_positions:Array[Vector2i] = wallPhysicalLayer.get_used_cells()
	for pos:Vector2i in used_cell_positions:
		var atlas_coords:Vector2i = wallPhysicalLayer.get_cell_atlas_coords(pos)
		wallVisualLayer.set_cell(pos, 1, atlas_coords)
