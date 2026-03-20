class_name EnemySpawnTableRow extends Resource

enum EnemyType { CANNONHEAD, CANNONHEAD_FAST, SLIME, BUG }

@export var enemy_pool:Array[EnemyType] = []
@export var spawn_chance:int = 0
