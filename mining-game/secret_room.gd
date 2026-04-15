class_name SecretRoom extends Area2D

@onready var _collision_shape:CollisionShape2D = $CollisionShape2D
@onready var _sprite:Sprite2D = $Sprite2D

const HINT_SCENE:PackedScene = preload("res://secret_room_hint.tscn")

const UNHIDE_TIME:float = 0.5
const HINT_COOLDOWN:float = 5.0

var _discovered:bool = false
var _unhide_timer:float = UNHIDE_TIME

var _hint_cooldown_timer:float = HINT_COOLDOWN

# Sets the size of the secret room. Assumes the secret rooms origin is at the top-left of where the secret room should go. Size parameter should be in cell coordinates.
func set_size(size:Vector2i) -> void:
	
	var pixel_size:Vector2 = (size * 16.0) + Vector2(44.0, 44.0)
	var relative_position:Vector2 = (pixel_size * 0.5) - Vector2(22.0, 26.0)
	
	# Update the collision shape size.
	var shape:RectangleShape2D = _collision_shape.shape as RectangleShape2D
	shape.size = pixel_size
	_collision_shape.position = relative_position
	
	# Update the sprite size.
	_sprite.region_rect.size = pixel_size
	_sprite.position = relative_position 
	
	_sprite.material.set_shader_parameter("region_size", _sprite.region_rect.size)

func _process(delta: float) -> void:
	
	_update_cover_opacity(delta)
	
	_handle_hint_dispatch(delta)

func _handle_hint_dispatch(delta: float) -> void:
	
	# Do not dispatch hints after this room has been discovered.
	if (_discovered):
		return
	
	if (_hint_cooldown_timer > 0.0):
		_hint_cooldown_timer -= delta
	else:
		_hint_cooldown_timer = HINT_COOLDOWN
		
		# Spawn a hint.
		var hint:SecretRoomHint = HINT_SCENE.instantiate()
		self.add_child(hint)
		hint.global_position = _collision_shape.global_position
		var angle:float = randf_range(0.0, PI * 2.0)
		hint.set_direction(Vector2.RIGHT.rotated(angle))

func _update_cover_opacity(delta: float) -> void:
	
	# Handle the cover fade out once room is discovered.
	if (_discovered):
		if (_unhide_timer > 0.0):
			_unhide_timer -= delta
		else:
			_unhide_timer = 0.0
		_sprite.material.set_shader_parameter("alpha", _unhide_timer / UNHIDE_TIME)

func _unhide_room() -> void:
	_discovered = true
	
	# Expidite the removal of all hints spawned from this secret room.
	for child:Node2D in self.get_children():
		if (child is SecretRoomHint):
			child.expidite_removal()

func _on_body_entered(body: Node2D) -> void:
	
	if (body is PlayerCharacter):
		_unhide_room()
