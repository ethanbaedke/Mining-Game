class_name GameManager extends Node

@onready var _loading_ui_anim_player:AnimationPlayer = $LoadingUI/AnimationPlayer
@onready var _screen_mask:ColorRect = $LoadingUI/ScreenMask
@onready var _music_player:MusicPlayer = $MusicPlayer
@onready var _pause_menu:PauseMenu = $PauseMenu

const MAIN_MENU_SCENE:PackedScene = preload("res://main_menu.tscn")
const HELP_SCREEN_SCENE:PackedScene = preload("res://help_screen.tscn")
const MINE_LEVEL_SCENE:PackedScene = preload("res://mine_level.tscn")
const HIGH_SCORE_DISPLAY_SCENE:PackedScene = preload("res://high_score_display.tscn")

const SCORE_FROM_PLAYER_KILLED:int = 0
const COAL_NEEDED_FOR_BOMB:int = 8
const COAL_FROM_WALL_BREAK:int = 1

const SOUND_EFFECT_PLAYER_SCENE:PackedScene = preload("res://sound_effect_player.tscn")
const BOMB_CHARGED_SOUND_EFFECT_CLIP:AudioStreamWAV = preload("res://bomb_ready.wav")

signal current_score_changed
signal current_coal_changed

var current_floor:int = 0
var current_score:int = 0
var current_coal:int = 0
var lives_remaining:int = 0

var _main_menu:MainMenu = null
var _mine_level:MineLevel = null
var _high_score_display:HighScoreDisplay = null

func _ready() -> void:
	
	_load_main_menu()
	
func _process(delta: float) -> void:
	
	# Handle parameter setting for load screen shader.
	var viewport:Viewport = get_viewport()
	if (_mine_level != null && _mine_level.player_character != null):
		_screen_mask.material.set_shader_parameter("player_uv", (viewport.get_canvas_transform() * _mine_level.player_character.global_position) / viewport.get_visible_rect().size)
	else:
		_screen_mask.material.set_shader_parameter("player_uv", Vector2(0.5, 0.5))
		
	# Handle toggling the pause menu.
	if (Input.is_action_just_pressed("pause_game") && (_mine_level != null || _high_score_display != null)):
		_pause_menu.toggle_game_paused()

func _load_main_menu() -> void:
	
	_main_menu = MAIN_MENU_SCENE.instantiate()
	self.add_child(_main_menu)
	
	_loading_ui_anim_player.play("black_to_full_visible")
	await _loading_ui_anim_player.animation_finished
	
	_main_menu.start_game_requested.connect(_on_main_menu_start_game_requested)
	_main_menu.quit_game_requested.connect(_on_main_menu_quit_game_requested)
	_main_menu.set_input_available(true)

func _on_main_menu_start_game_requested() -> void:
	
	_main_menu.set_input_available(false)
	
	_loading_ui_anim_player.play("full_visible_to_black")
	await _loading_ui_anim_player.animation_finished
	
	_main_menu.queue_free()
	
	_start_new_game()
	
func _on_main_menu_quit_game_requested() -> void:
	get_tree().quit()

func _start_new_game() -> void:
	
	current_floor = 1
	current_score = 0
	current_coal = 0
	
	# TESTING: Reset to 3.
	lives_remaining = 3
	
	await _show_help_screen()
	
	# Instantiate the mine level.
	_instantiate_mine_level()

func _instantiate_mine_level() -> void:
	
	_mine_level = MINE_LEVEL_SCENE.instantiate()
	_mine_level.level_cleared.connect(_on_mine_level_level_cleared)
	_mine_level.player_killed.connect(_on_mine_level_player_killed)
	_mine_level.rock_broken.connect(_on_mine_level_rock_broken)
	_mine_level.wall_broken_by_player.connect(_on_mine_level_wall_broken_by_player)
	_mine_level.bomb_placed.connect(_on_mine_level_bomb_placed)
	self.add_child(_mine_level)
	
	_music_player.play_game_theme()
	
	_loading_ui_anim_player.play("black_to_full_visible")

func _show_help_screen() -> void:
	
	# Create the help screen.
	var help_scene:HelpScene = HELP_SCREEN_SCENE.instantiate()
	self.add_child(help_scene)
	
	# Show the help screen.
	_loading_ui_anim_player.play("black_to_full_visible")
	await _loading_ui_anim_player.animation_finished
	
	# Wait for the user to skip the help screen.
	help_scene.make_skip_available()
	await help_scene.skipped
	
	# Hide the help screen.
	_loading_ui_anim_player.play("full_visible_to_black")
	await _loading_ui_anim_player.animation_finished
	
	# Cleanup the help scene.
	help_scene.queue_free()

func _free_mine_level() -> void:
	
	# Free the mine level and wait for it to be freed (end of the frame).
	_mine_level.queue_free()
	await get_tree().process_frame

func _modify_current_score(amount:int) -> void:
	
	current_score += amount
	current_score = max(0, current_score)
	current_score = min(999, current_score)
	
	current_score_changed.emit()

func _modify_current_coal(amount:int) -> void:
	
	# Used for bomb charge sound effect, see below.
	var progress_toward_next_bomb_charge:int = current_coal % COAL_NEEDED_FOR_BOMB
	
	# Base modification, with clamping.
	current_coal = max(min(current_coal + amount, COAL_NEEDED_FOR_BOMB * 3), 0.0)
	
	# If we just charged a bomb with this addition of coal, play the sound effect for charging a bomb.
	if (current_coal % COAL_NEEDED_FOR_BOMB < progress_toward_next_bomb_charge):
		var bomb_charged_sound_effect:SoundEffectPlayer = SOUND_EFFECT_PLAYER_SCENE.instantiate()
		bomb_charged_sound_effect.stream = BOMB_CHARGED_SOUND_EFFECT_CLIP
		@warning_ignore("integer_division")
		bomb_charged_sound_effect.pitch_scale = 0.6 + (0.2 * ((current_coal / COAL_NEEDED_FOR_BOMB) - 1))
		bomb_charged_sound_effect.cleanup_when_finished = true
		_mine_level.player_character.add_child(bomb_charged_sound_effect)
		bomb_charged_sound_effect.position = Vector2.ZERO
		bomb_charged_sound_effect.play_effect()
		
	current_coal_changed.emit()

func _on_mine_level_level_cleared() -> void:
	
	_music_player.play_level_cleared()
	
	await _player_focus_to_black()
	
	# Increment our current floor.
	current_floor += 1
	
	await _free_mine_level()
	_instantiate_mine_level()

func _on_mine_level_player_killed() -> void:
	
	_music_player.play_player_killed()
	
	await _player_focus_to_black()
	
	_modify_current_score(SCORE_FROM_PLAYER_KILLED)
	
	await _free_mine_level()
	
	# If the player has lives left, subtract one and reload the level.
	if (lives_remaining > 1):
		lives_remaining -= 1
		_instantiate_mine_level()
	
	# Otherwise, go to high score display.
	else:
		# Try and add this run to the list of high scores.
		var new_entry:HighScoreEntry = HighScoreEntry.new()
		new_entry.score = current_score
		new_entry.floor_number = current_floor
		_try_add_score_to_high_scores(new_entry)
		
		# Go to high score display.
		_instantiate_high_score_display()

func _instantiate_high_score_display() -> void:
	
	# Instantiate the high score display scene.
	_high_score_display = HIGH_SCORE_DISPLAY_SCENE.instantiate()
	_high_score_display.display_finished.connect(_on_high_score_display_display_finished)
	self.add_child(_high_score_display)
	
	# Load out of our black screen.
	_loading_ui_anim_player.play("black_to_full_visible")

func _on_high_score_display_display_finished() -> void:
	
	# Load to black.
	_loading_ui_anim_player.play("full_visible_to_black")
	await _loading_ui_anim_player.animation_finished
	
	# Destroy the high score display scene.
	_high_score_display.queue_free()
	await get_tree().process_frame
	
	# Go to the main menu.
	_load_main_menu()

func _on_mine_level_rock_broken(rock:Rock) -> void:
	_modify_current_score(rock.score_for_breaking)

func _on_mine_level_wall_broken_by_player() -> void:
	_modify_current_coal(COAL_FROM_WALL_BREAK)

func _on_mine_level_bomb_placed(bombType:int) -> void:
	_modify_current_coal(-COAL_NEEDED_FOR_BOMB * bombType)

func _player_focus_to_black() -> void:
	
	# Bring the screen in on the player.
	_loading_ui_anim_player.play("full_visible_to_focus_player")
	await _loading_ui_anim_player.animation_finished
	
	# Wait a moment.
	await get_tree().create_timer(0.5).timeout
	
	# Black out the screen.
	_loading_ui_anim_player.play("player_focus_to_black")
	await _loading_ui_anim_player.animation_finished

func _try_add_score_to_high_scores(entry:HighScoreEntry) -> void:
	
	var add_ind:int = 0
	
	# Find the index where the new entry should be put.
	while (add_ind < Globals.game_data.high_scores.size() && !_compare_high_score_entries(entry, Globals.game_data.high_scores[add_ind])):
		add_ind += 1
	
	# If there is a valid spot, insert it.
	if (add_ind < 10):
		Globals.game_data.high_scores.insert(add_ind, entry)

	# If there are now 11 entries on the high score board, remove the last one.
	if (Globals.game_data.high_scores.size() == 11):
		Globals.game_data.high_scores.remove_at(10)

# Returns true if e1 should be ranked higher on the scoreboard than e2, and false otherwise.
func _compare_high_score_entries(e1:HighScoreEntry, e2:HighScoreEntry) -> bool:
	
	# Use score to determine who is higher.
	if (e1.score != e2.score):
		return e1.score > e2.score
	# Use floor as the tiebreaker (higher floor wins). If this is tied, e2 wins (since the question is, is e1 BETTER than e2).
	else:
		return e1.floor_number > e2.floor_number
