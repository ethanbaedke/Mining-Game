extends Node

var initialized:bool = false

func _ready() -> void:
	
	# Try to initialize the steam api.
	var response:Dictionary = Steam.steamInitEx()
	if (response.status == 0):
		initialized = true
		print("Steam api initialized.")
	else:
		printerr("Steam api failed to initialize.")
		return

func _process(delta: float) -> void:
	
	# Must be called every frame for callbacks to occur.
	Steam.run_callbacks()
