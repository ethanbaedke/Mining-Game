class_name SecretRoomHint extends Node2D

@onready var _sprite:Sprite2D = $Sprite2D

const MOVE_SPEED:int = 20
const WOBBLE_DISTANCE:int = 5
const WOBBLE_SPEED:float = 3.0
const INVISIBLE_TIME:float = 2.0
const FADE_IN_TIME:float = 2.0
const FADE_OUT_TIME:float = 8.0
const MAX_OPACITY:float = 0.75

var _direction:Vector2 = Vector2.ZERO
var _wobble_direction:Vector2 = Vector2.ZERO
var _object_time:float = 0.0
var _expiditing_removal:bool = false

func set_direction(dir:Vector2) -> void:
	_direction = dir.normalized()
	_wobble_direction = _direction.rotated(PI * 0.5)

# Called when the room is revealed and this hint should quickly go away.
func expidite_removal() -> void:
	_expiditing_removal = true

func _ready() -> void:
	
	# Ensure hint is invisible on instantiation.
	_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _process(delta: float) -> void:
	
	# Track the lifetime of this object.
	_object_time += delta
	
	# Handle moving the hint.
	position += _direction * MOVE_SPEED * delta
	
	# Handle the hint wobble.
	_sprite.position = _wobble_direction * sin(_object_time * WOBBLE_SPEED) * WOBBLE_DISTANCE
	
	# Handle the hint opacity.
	if (!_expiditing_removal):
		
		# Regular opacity handling.
		if (_object_time < INVISIBLE_TIME):
			pass
		elif ((_object_time - INVISIBLE_TIME) < FADE_IN_TIME):
			_sprite.modulate = Color(1.0, 1.0, 1.0, lerp(0.0, MAX_OPACITY, (_object_time - INVISIBLE_TIME) / FADE_IN_TIME))
		elif ((_object_time - INVISIBLE_TIME - FADE_IN_TIME) < FADE_OUT_TIME):
			_sprite.modulate = Color(1.0, 1.0, 1.0, lerp(MAX_OPACITY, 0.0, ((_object_time - FADE_IN_TIME - INVISIBLE_TIME)) / FADE_OUT_TIME))
		else:
			self.queue_free()
	
	# Opacity handling after object has been marked to expidite removal.
	elif (_sprite.modulate.a > 0.0):
		_sprite.modulate.a -= delta
	else:
		self.queue_free()
