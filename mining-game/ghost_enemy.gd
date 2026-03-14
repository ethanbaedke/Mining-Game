class_name GhostEnemy extends Area2D

@onready var _sprite:Sprite2D = $Sprite2D

@export var _move_speed:int = 32

# Should be set by the instantiator.
var player_character:PlayerCharacter = null

# Reference retrieved on ready.
var _mine_level:MineLevel = null

func _ready() -> void:
	
	_mine_level = get_parent()

func _physics_process(delta: float) -> void:
	
	# Do no processing if the level is ending.
	if (_mine_level.level_cleanup_imminent):
		return
	
	# Must have a reference to the player character to function.
	if (player_character == null):
		return
		
	_handle_movement(delta)

func _draw() -> void:
	
	# Draw pathfinding if visible paths is checked in the editor.
	if (get_tree().debug_paths_hint && player_character != null):
		draw_line(Vector2(0, 0), to_local(player_character.global_position), Color.GREEN, 1.0)

func _handle_movement(delta:float) -> void:
	
	var to_player:Vector2 = player_character.global_position - self.global_position
	
	position += to_player.normalized() * _move_speed * delta
	
	# Flip sprite to face player
	_sprite.flip_h = to_player.x < 0
	
	# For debug drawing.
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:

	# If this enemy touches the player, kill them.
	if (body is PlayerCharacter):
		body.kill_player()
