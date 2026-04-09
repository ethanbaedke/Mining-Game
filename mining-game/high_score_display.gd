class_name HighScoreDisplay extends Control

@onready var _high_score_entry_ui:Array[HBoxContainer] = [
	$Scoreboard/MarginContainer/VBoxContainer/Entry1,
	$Scoreboard/MarginContainer/VBoxContainer/Entry2,
	$Scoreboard/MarginContainer/VBoxContainer/Entry3,
	$Scoreboard/MarginContainer/VBoxContainer/Entry4,
	$Scoreboard/MarginContainer/VBoxContainer/Entry5,
	$Scoreboard/MarginContainer/VBoxContainer/Entry6,
	$Scoreboard/MarginContainer/VBoxContainer/Entry7,
	$Scoreboard/MarginContainer/VBoxContainer/Entry8,
	$Scoreboard/MarginContainer/VBoxContainer/Entry9,
	$Scoreboard/MarginContainer/VBoxContainer/Entry10]
@onready var _timer_label:Label = $Timer/TimerLabel


const NAME_ENTRY_UNICODE_OPTIONS:Array[int] = [
	65, # A
	66,
	67,
	68,
	69,
	70,
	71,
	72,
	73,
	74,
	75,
	76,
	77,
	78,
	79,
	80,
	81,
	82,
	83,
	84,
	85,
	86,
	87,
	88,
	89,
	90, # Z
	48, # 0
	49,
	50,
	51,
	52,
	53,
	54,
	55,
	56,
	57, # 9
	32, # Space
]
const NAME_ENTRY_TIME:int = 30
const DISPLAY_TIME:int = 5

signal display_finished

# Reference retrieved on ready.
var _game_manager:GameManager = null

var _name_entry_countdown_complete:bool = false
var _name_entry_countdown:float = NAME_ENTRY_TIME
var _entry_to_name:HighScoreEntry = null
var _name_entry_label:Label = null
var _name_entry_character_index:int = 0
var _name_entry_unicode_index:int = 0
var _name_entry_cursor_flash_timer:float = 0.0

var _display_countdown_complete:bool = false
var _display_countdown:float = DISPLAY_TIME

func _ready() -> void:
	
	_game_manager = get_parent()
	
	_fillout_high_score_ui()
	
	# See if we need the user to enter a name.
	for i:int in range(_game_manager.high_scores.size()):
		if (_game_manager.high_scores[i].name == ""):
			_entry_to_name = _game_manager.high_scores[i]
			_name_entry_label = _high_score_entry_ui[i].get_child(0) as Label
			break
	
	# User did not make it on the board.
	if (_entry_to_name == null):
		_name_entry_countdown_complete = true
	# User made it!
	else:
		var space_char:String = char(NAME_ENTRY_UNICODE_OPTIONS[NAME_ENTRY_UNICODE_OPTIONS.size() - 1])
		_entry_to_name.name = char(NAME_ENTRY_UNICODE_OPTIONS[0]) + space_char + space_char
		_name_entry_label.text = _entry_to_name.name

func _process(delta: float) -> void:
	
	# Name entry is complete.
	if (_name_entry_countdown_complete):
		
		# Display countdown is complete. Do nothing.
		if (_display_countdown_complete):
			return
			
		# Tick the display countdown.
		else:
			_display_countdown -= delta
			_timer_label.text = "STARTING NEW GAME: " + str(int(ceil(_display_countdown)))
			if (_display_countdown <= 0.0):
				_display_countdown_complete = true
				display_finished.emit()
				
	# Name entry is in progress.
	else:
		
		# Tick our name entry.
		_name_entry_countdown -= delta
		_timer_label.text = "TIME REMAINING: " + str(int(ceil(_name_entry_countdown)))
		if (_name_entry_countdown <= 0.0):
			_name_entry_countdown_complete = true
			# Update name one last time (in case flashing cursor is active)
			_name_entry_label.text = _entry_to_name.name
			
		# Handle cursor flashing
		_name_entry_cursor_flash_timer += delta
		if (int(_name_entry_cursor_flash_timer * 2.0) % 2 == 1):
			_name_entry_label.text[_name_entry_character_index] = '+'
		else:
			_name_entry_label.text = _entry_to_name.name
			
		_handle_name_user_input()

func _handle_name_user_input() -> void:
	
	if (Input.is_action_just_pressed("move_up")):
		# Increment unicode character from list.
		_name_entry_unicode_index = (_name_entry_unicode_index + 1) % NAME_ENTRY_UNICODE_OPTIONS.size()
		# Update name.
		_entry_to_name.name[_name_entry_character_index] = char(NAME_ENTRY_UNICODE_OPTIONS[_name_entry_unicode_index])
		_name_entry_label.text = _entry_to_name.name
		# Reset cursor flash timer
		_name_entry_cursor_flash_timer = 0.0
	elif (Input.is_action_just_pressed("move_down")):
		# Decrement unicode character from list.
		_name_entry_unicode_index -= 1
		if (_name_entry_unicode_index == -1):
			_name_entry_unicode_index = NAME_ENTRY_UNICODE_OPTIONS.size() - 1
		# Update name.
		_entry_to_name.name[_name_entry_character_index] = char(NAME_ENTRY_UNICODE_OPTIONS[_name_entry_unicode_index])
		_name_entry_label.text = _entry_to_name.name
		# Reset cursor flash timer
		_name_entry_cursor_flash_timer = 0.0
	elif (Input.is_action_just_pressed("use_pickaxe")):
		# Move to next character.
		if (_name_entry_character_index < 2):
			_name_entry_character_index += 1
			# Move the last input character over to the next spot by default.
			_entry_to_name.name[_name_entry_character_index] = char(NAME_ENTRY_UNICODE_OPTIONS[_name_entry_unicode_index])
			_name_entry_label.text = _entry_to_name.name
			# Reset cursor flash timer
			_name_entry_cursor_flash_timer = 0.0
		# Finished
		else:
			_name_entry_countdown_complete = true
			# Save the new high score to the filesystem as soon as the user finishes entering their name.
			_game_manager.save_high_scores()
			# Update name one last time (in case flashing cursor is active)
			_name_entry_label.text = _entry_to_name.name

func _fillout_high_score_ui() -> void:
	
	# Fill out the high score ui with all high scores on the game manager.
	var entry_ind:int = 0
	while (entry_ind < _game_manager.high_scores.size()):
		(_high_score_entry_ui[entry_ind].get_child(0) as Label).text = _game_manager.high_scores[entry_ind].name
		(_high_score_entry_ui[entry_ind].get_child(1) as Label).text = str(_game_manager.high_scores[entry_ind].score)
		(_high_score_entry_ui[entry_ind].get_child(2) as Label).text = str(_game_manager.high_scores[entry_ind].floor_number)
		entry_ind += 1
		
	# Fill out the remaining high score ui with blanks.
	while (entry_ind < 10):
		(_high_score_entry_ui[entry_ind].get_child(0) as Label).text = ""
		(_high_score_entry_ui[entry_ind].get_child(1) as Label).text = ""
		(_high_score_entry_ui[entry_ind].get_child(2) as Label).text = ""
		entry_ind += 1
