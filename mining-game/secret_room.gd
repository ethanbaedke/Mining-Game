class_name SecretRoom extends Area2D

@onready var _collision_shape:CollisionShape2D = $CollisionShape2D
@onready var _sprite:Sprite2D = $Sprite2D

# Sets the size of the secret room. Assumes the secret rooms origin is at the top-left of where the secret room should go. Size parameter should be in cell coordinates.
func set_size(size:Vector2i) -> void:
	
	var pixel_size:Vector2 = (size * 16.0) + Vector2(20.0, 18.0)
	var relative_position:Vector2 = (pixel_size * 0.5) - Vector2(10.0, 16.0)
	
	# Update the collision shape size.
	var shape:RectangleShape2D = _collision_shape.shape as RectangleShape2D
	shape.size = pixel_size
	_collision_shape.position = relative_position
	
	# Update the sprite size.
	_sprite.region_rect.size = pixel_size + Vector2(4.0, 4.0) # Sprite should be slightly larger than collision area (adjust as shader changes).
	_sprite.position = relative_position 
	
	_sprite.material.set_shader_parameter("region_size", _sprite.region_rect.size)

func _unhide_room() -> void:
	_sprite.visible = false

func _on_body_entered(body: Node2D) -> void:
	
	if (body is PlayerCharacter):
		_unhide_room()
