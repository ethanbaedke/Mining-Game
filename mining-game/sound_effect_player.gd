class_name SoundEffectPlayer extends AudioStreamPlayer2D

@export var base_volume_scale:float = 1.0
@export var cleanup_when_finished:bool = false

func play_effect() -> void:
	
	self.volume_linear = base_volume_scale
	
	play()
	
	if (cleanup_when_finished):
		self.finished.connect(func () -> void:
			self.queue_free())
