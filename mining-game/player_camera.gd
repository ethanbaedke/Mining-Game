class_name PlayerCamera extends Camera2D

const MAX_SHAKE_DIST:float = 32.0
const MAX_ROT_RADS:float = PI / 8
const TRAUMA_DECAY:float = 1.0

@export var _noise:FastNoiseLite

var _trauma:float = 0.0
var _noise_progression:float = 0.0

func add_trauma(amount:float) -> void:
	# Ensure trauma always sits between 0 and 1.
	_trauma = min(max(_trauma + amount, 0.0), 1.0)

func _process(delta: float) -> void:
	
	if (_trauma > 0.0):
		_trauma = max(_trauma - delta, 0.0)
		_handle_shake(delta)

func _handle_shake(delta:float) -> void:
	
	_noise_progression += delta
	
	var amt:float = pow(_trauma, 2.0)
	
	offset.x = _noise.get_noise_1d(_noise_progression) * amt * MAX_SHAKE_DIST
	offset.y = _noise.get_noise_1d(_noise_progression + 1.0) * amt * MAX_SHAKE_DIST
	rotation = _noise.get_noise_1d(_noise_progression + 2.0) * amt * MAX_ROT_RADS
