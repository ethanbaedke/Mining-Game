class_name SecretRoom extends Area2D

@onready var _collision_shape:CollisionShape2D = $CollisionShape2D
@onready var _sprite:Sprite2D = $Sprite2D

const UNHIDE_TIME:float = 0.5

var _discovered:bool = false
var _unhide_timer:float = UNHIDE_TIME

# Sets the size of the secret room. Assumes the secret rooms origin is at the top-left of where the secret room should go. Size parameter should be in cell coordinates.
func set_size(size:Vector2i) -> void:
	
	var pixel_size:Vector2 = (size * 16.0) + Vector2(44.0, 44.0)
	var relative_position:Vector2 = (pixel_size * 0.5) - Vector2(22.0, 26.0)
	
	# Update the collision shape size.
	var shape:RectangleShape2D = _collision_shape.shape as RectangleShape2D
	shape.size = pixel_size
	_collision_shape.position = relative_position
	
	# Update the sprite size.
	_sprite.region_rect.size = pixel_size + Vector2(0.0, 0.0) # Sprite should be slightly larger than collision area (adjust as shader changes).
	_sprite.position = relative_position 
	
	_sprite.material.set_shader_parameter("region_size", _sprite.region_rect.size)

func _process(delta: float) -> void:
	
	# Handle the cover fade out once room is discovered.
	if (_discovered):
		if (_unhide_timer > 0.0):
			_unhide_timer -= delta
		else:
			_unhide_timer = 0.0
		_sprite.material.set_shader_parameter("alpha", _unhide_timer / UNHIDE_TIME)

func _unhide_room() -> void:
	_discovered = true

func _on_body_entered(body: Node2D) -> void:
	
	if (body is PlayerCharacter):
		_unhide_room()
