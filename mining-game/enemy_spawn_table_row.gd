class_name EnemySpawnTableRow extends Resource

enum EnemyType { CANNONHEAD, CANNONHEAD_FAST, SLIME, SLIME_FAST, BUG, BUG_FAST }

@export var enemy_pool:Array[EnemyType] = []
@export var spawn_chance:int = 0
