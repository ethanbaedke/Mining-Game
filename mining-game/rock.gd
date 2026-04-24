class_name Rock extends StaticBody2D

const SOUND_EFFECT_PLAYER_SCENE:PackedScene = preload("res://sound_effect_player.tscn")

@export var score_for_breaking:int = 1
@export var color_for_score_effect:Color = Color.WHITE
@export var _rock_break_sound_effect_clip:AudioStreamWAV = preload("res://pickaxe_hit.wav")
@export var _rock_break_sound_effect_base_volume_scale:float = 1.0
@export var _rock_break_sound_effect_pitch_scale:float = 1.0

func break_rock(broken_by_player:bool = false) -> void:
	
	# Only play sound effect if player breaks rock to avoid excessive sound effects when a bomb goes off.
	if (broken_by_player):
		# Instantiate the rock break sound effect outside the rock so when it's cleaned up the effect finishes.
		var rock_break_sound_effect:SoundEffectPlayer = SOUND_EFFECT_PLAYER_SCENE.instantiate()
		rock_break_sound_effect.stream = _rock_break_sound_effect_clip
		rock_break_sound_effect.pitch_scale = _rock_break_sound_effect_pitch_scale
		rock_break_sound_effect.base_volume_scale = _rock_break_sound_effect_base_volume_scale
		rock_break_sound_effect.cleanup_when_finished = true
		self.get_parent().add_child(rock_break_sound_effect)
		rock_break_sound_effect.global_position = self.global_position
		rock_break_sound_effect.play_effect()
	
	queue_free()

func handle_hit(broken_by_player:bool = false) -> void:
	
	_request_remove_from_mine_level(broken_by_player)

func _request_remove_from_mine_level(broken_by_player:bool = false) -> void:
	
	var parent:Node = get_parent()
	if (parent is MineLevel):
		parent.remove_rock(self, broken_by_player)
