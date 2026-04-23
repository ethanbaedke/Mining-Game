class_name SoundEffectPlayer extends AudioStreamPlayer2D

@export var base_volume_scale:float = 1.0
@export var cleanup_when_finished:bool = false
@export var infinite_distance:bool = false

func play_effect() -> void:
	
	self.volume_linear = base_volume_scale * Globals.game_data.sound_effect_volume
	
	play()
	
	if (cleanup_when_finished):
		self.finished.connect(func () -> void:
			self.queue_free())

func _ready() -> void:
	
	# Set distance falloff.
	if (!infinite_distance):
		# Set to screen width.
		max_distance = 480
	else:
		# Should be enough unless we make the mine level larger.
		max_distance = 2048
