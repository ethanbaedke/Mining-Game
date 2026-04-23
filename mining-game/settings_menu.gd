class_name SettingsMenu extends Control

@onready var _music_volume_slider:HSlider = $MarginContainer/VBoxContainer/VBoxContainer/MusicVolume/MusicVolumeSlider
@onready var _sound_effect_volume_slider:HSlider = $MarginContainer/VBoxContainer/VBoxContainer/SoundEffectVolume/SoundEffectVolumeSlider
@onready var _back_button:StylizedButton = $MarginContainer/VBoxContainer/Buttons/BackButton
@onready var _reset_to_default_button:StylizedButton = $MarginContainer/VBoxContainer/Buttons/ResetToDefaultButton
@onready var _slider_moved_sound_effect:SoundEffectPlayer = $SliderMovedSoundEffect

func set_input_available(available:bool) -> void:
	
	if (available):
		_music_volume_slider.focus_mode = Control.FOCUS_ALL
		_sound_effect_volume_slider.focus_mode = Control.FOCUS_ALL
		_back_button.set_input_allowed(true)
		_reset_to_default_button.set_input_allowed(true)
		
		if (Globals.input_type != Globals.InputType.MOUSE):
			_music_volume_slider.grab_focus()
	else:
		_music_volume_slider.focus_mode = Control.FOCUS_NONE
		_sound_effect_volume_slider.focus_mode = Control.FOCUS_NONE
		_back_button.set_input_allowed(false)
		_reset_to_default_button.set_input_allowed(false)
		
		var focus_owner:Control = get_viewport().gui_get_focus_owner()
		if (focus_owner != null):
			focus_owner.release_focus()

func _ready() -> void:
	
	_music_volume_slider.value = Globals.game_data.music_volume * _music_volume_slider.max_value
	_music_volume_slider.value_changed.connect(func (value:float) -> void:
		_slider_moved_sound_effect.play_effect()
		Globals.set_music_volume(value / _music_volume_slider.max_value))
		
	_sound_effect_volume_slider.value = Globals.game_data.sound_effect_volume * _sound_effect_volume_slider.max_value
	_sound_effect_volume_slider.value_changed.connect(func (value:float) -> void:
		_slider_moved_sound_effect.play_effect()
		Globals.set_sound_effect_volume(value / _sound_effect_volume_slider.max_value))
	
	Globals.input_type_changed.connect(_on_globals_input_type_changed)

func _on_globals_input_type_changed(old_type:Globals.InputType) -> void:
	
	# If the mouse is not over an element (no focus) and we switch to keyboard or gamepad input, focus the start button.
	if (old_type == Globals.InputType.MOUSE):
		var focus_owner:Control = get_viewport().gui_get_focus_owner()
		if (focus_owner == null):
			# Must wait so the default navigation doesn't happen right after setting focus on the start button (we overwrite it instead).
			_music_volume_slider.grab_focus.call_deferred()
