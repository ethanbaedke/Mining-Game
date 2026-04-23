class_name Bomb extends Area2D

const SOUND_EFFECT_PLAYER_SCENE:PackedScene = preload("res://sound_effect_player.tscn")
const EXPLODE_SOUND_EFFECT_CLIP:AudioStreamWAV = preload("res://bomb_explode.wav")

@onready var _collision_shape:CollisionShape2D = $CollisionShape2D
@onready var _drop_sound_effect:SoundEffectPlayer = $DropSoundEffect
@onready var _light_sound_effect:SoundEffectPlayer = $LightSoundEffect

const EXPLODE_TIME:float = 1.0

@export var _camera_trauma_on_explosion:float = 0.6
@export var _explode_sound_effect_pitch_scale:float = 1.0

var _mine_level:MineLevel = null
var _cell_position:Vector2i = Vector2i.ZERO

var _explode_timer:float = EXPLODE_TIME

func setup(mine_level:MineLevel, cell_position:Vector2i) -> void:
	_mine_level = mine_level
	_cell_position = cell_position

func _ready() -> void:
	
	_drop_sound_effect.play()
	await get_tree().create_timer(EXPLODE_TIME * 0.5).timeout
	_light_sound_effect.play()

func _process(delta: float) -> void:
	
	# Do not allow this bomb to explode if the level is cleaning up.
	if (_mine_level.level_cleanup_imminent):
		return
	
	if (_explode_timer > 0.0):
		_explode_timer -= delta
	else:
		_handle_explosion()

func _handle_explosion() -> void:
	
	# Instantiate the bomb sound effect outside the bomb so when it's cleaned up the effect finishes.
	var explode_sound_effect:SoundEffectPlayer = SOUND_EFFECT_PLAYER_SCENE.instantiate()
	explode_sound_effect.stream = EXPLODE_SOUND_EFFECT_CLIP
	explode_sound_effect.pitch_scale = _explode_sound_effect_pitch_scale
	explode_sound_effect.cleanup_when_finished = true
	self.get_parent().add_child(explode_sound_effect)
	explode_sound_effect.global_position = self.global_position
	explode_sound_effect.play_effect()
	
	# Camera shake.
	_mine_level.player_camera.add_trauma(_camera_trauma_on_explosion)
	
	var area_hits:Array[Area2D] = get_overlapping_areas()
	var body_hits:Array[Node2D] = get_overlapping_bodies()
	
	# These will be enemies and hidden rooms.
	for area_hit:Area2D in area_hits:
		
		if (area_hit is SecretRoom):
			area_hit.unhide_room()
		if (area_hit is BugEnemy):
			area_hit.queue_free()
		elif (area_hit is SlimeEnemy):
			area_hit.queue_free()
		elif (area_hit.get_parent() is CannonheadEnemy):
			area_hit.get_parent().queue_free()
		
	# These will be rocks.
	for body_hit:Node2D in body_hits:
		
		if (body_hit is Rock):
			_mine_level.remove_rock(body_hit)
			
	# Handle removing walls.
	var circle:CircleShape2D = _collision_shape.shape as CircleShape2D
	# Round up here since we'll check every cell anyways and would rather oversample.
	var cell_radius:int = ceil(circle.radius / 16)
	
	for y:int in range(_cell_position.y - cell_radius, _cell_position.y + cell_radius + 1):
		for x:int in range(_cell_position.x - cell_radius, _cell_position.x + cell_radius + 1):
			var cell:Vector2i = Vector2i(x, y)
			if (cell.distance_to(_cell_position) <= cell_radius):
				_mine_level.remove_tile(cell)
	
	self.queue_free()
