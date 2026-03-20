class_name EnemySpawnTable extends Resource

@export var table:Array[EnemySpawnTableRow] = []

func get_row_from_floor(floor_num:int) -> EnemySpawnTableRow:
	
	# If the table is empty, return a null row.
	if (table.size() == 0):
		return null
	# If the table contains an entry for this floor, return it.
	elif (floor_num <= table.size()):
		return table[floor_num - 1]
	# If we are through the whole table, return the last row.
	else:
		return table[table.size() - 1]
