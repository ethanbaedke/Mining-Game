class_name GameManager extends Node

@onready var _loading_ui_anim_player:AnimationPlayer = $LoadingUI/AnimationPlayer
@onready var _screen_mask:ColorRect = $LoadingUI/ScreenMask

const MINE_LEVEL_SCENE:PackedScene = preload("res://mine_level.tscn")

const SCORE_FROM_PLAYER_KILLED:int = -10

signal current_score_changed

var current_floor:int = 0
var current_score:int = 0
var lives_remaining:int = 0

var _mine_level:MineLevel = null

func _ready() -> void:
	
	_start_new_game()
	
func _process(delta: float) -> void:
	
	var viewport:Viewport = get_viewport()
	_screen_mask.material.set_shader_parameter("screen_size", viewport.get_visible_rect().size)
	
	if (_mine_level != null && _mine_level.player_character != null):
		_screen_mask.material.set_shader_parameter("player_screen_pos", viewport.get_canvas_transform() * _mine_level.player_character.global_position)
	else:
		_screen_mask.material.set_shader_parameter("player_screen_pos", viewport.get_visible_rect().size * 0.5)
	
func _start_new_game() -> void:
	
	current_floor = 1
	current_score = 0
	lives_remaining = 3
	
	# Instantiate the mine level.
	_instantiate_mine_level()

func _instantiate_mine_level() -> void:
	
	_mine_level = MINE_LEVEL_SCENE.instantiate()
	_mine_level.level_cleared.connect(_on_mine_level_level_cleared)
	_mine_level.player_killed.connect(_on_mine_level_player_killed)
	_mine_level.rock_broken.connect(_on_mine_level_rock_broken)
	self.add_child(_mine_level)
	
	_loading_ui_anim_player.play("black_to_full_visible")

func _free_mine_level() -> void:
	
	# Free the mine level and wait for it to be freed (end of the frame).
	_mine_level.queue_free()
	await get_tree().process_frame

func _modify_current_score(amount:int) -> void:
	
	current_score += amount
	current_score = max(0, current_score)
	current_score = min(999, current_score)
	
	current_score_changed.emit()

func _on_mine_level_level_cleared() -> void:
	
	await _player_focus_to_black()
	
	# Increment our current floor.
	current_floor += 1
	
	await _free_mine_level()
	_instantiate_mine_level()

func _on_mine_level_player_killed() -> void:
	
	await _player_focus_to_black()
	
	_modify_current_score(SCORE_FROM_PLAYER_KILLED)
	
	await _free_mine_level()
	
	# If the player has lives left, subtract one and reload the level.
	if (lives_remaining > 1):
		lives_remaining -= 1
		_instantiate_mine_level()
	
	# Otherwise, start a new game.
	else:
		_start_new_game()
	
func _on_mine_level_rock_broken(rock:Rock) -> void:
	
	_modify_current_score(rock.score_for_breaking)

func _player_focus_to_black() -> void:
	
	# Bring the screen in on the player.
	_loading_ui_anim_player.play("full_visible_to_focus_player")
	await _loading_ui_anim_player.animation_finished
	
	# Wait a moment.
	await get_tree().create_timer(0.5).timeout
	
	# Black out the screen.
	_loading_ui_anim_player.play("player_focus_to_black")
	await _loading_ui_anim_player.animation_finished
