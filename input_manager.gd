## Unified Input Manager for Snake Game
##
## This class handles all input sources (keyboard and controller) for multiple players.
## Supports configurable keyboard mappings for multiple players on same keyboard
## and multiple controllers simultaneously.
class_name InputManager
extends Node

## Signal emitted when any player changes direction
## @param player_id: The ID of the player (0, 1, 2, etc.)
## @param direction: The new direction vector
signal direction_changed(player_id: int, direction: Vector2)

## Signal emitted when any player presses pause
## @param player_id: The ID of the player
signal pause_pressed(player_id: int)

## Signal emitted when any player presses exit
## @param player_id: The ID of the player
signal exit_pressed(player_id: int)

## Signal emitted when any player presses restart
## @param player_id: The ID of the player
signal restart_pressed(player_id: int)

## Dictionary storing all active input configurations
## Key: player_id, Value: InputConfig object
var player_configs = {}

## Array of detected controllers
var controllers = []

## Maximum number of supported players
@export var max_players: int = 4

## Structure to hold input configuration for a single player
class InputConfig:
	var player_id: int
	var input_type: String  # "keyboard" or "controller"
	var keyboard_map: Dictionary  # Custom keyboard mappings
	var controller_id: int  # Controller device ID
	var last_direction: Vector2 = Vector2.RIGHT

## Default keyboard mappings for multiple players
const DEFAULT_KEYBOARD_MAPPINGS = {
	0: {  # Player 1 (WASD)
		"up": KEY_W,
		"down": KEY_S,
		"left": KEY_A,
		"right": KEY_D,
		"pause": KEY_ESCAPE,
		"exit": KEY_Q,
		"restart": KEY_R
	},
	1: {  # Player 2 (Arrow keys)
		"up": KEY_UP,
		"down": KEY_DOWN,
		"left": KEY_LEFT,
		"right": KEY_RIGHT,
		"pause": KEY_ENTER,
		"exit": KEY_BACKSPACE,
		"restart": KEY_SPACE
	},
	2: {  # Player 3 (IJKL)
		"up": KEY_I,
		"down": KEY_K,
		"left": KEY_J,
		"right": KEY_L,
		"pause": KEY_U,
		"exit": KEY_O,
		"restart": KEY_P
	},
	3: {  # Player 4 (TFGH)
		"up": KEY_T,
		"down": KEY_G,
		"left": KEY_F,
		"right": KEY_H,
		"pause": KEY_Y,
		"exit": KEY_V,
		"restart": KEY_B
	}
}

## Initialize the input manager
func _ready():
	# Detect available controllers
	detect_controllers()
	
	# Set up default configurations
	setup_default_configs()
	
	# Start input processing
	set_process_input(true)
	set_process(true)

## Detect all connected controllers
func detect_controllers():
	controllers.clear()
	for i in Input.get_connected_joypads():
		controllers.append(i)
		print("Controller " + str(i) + " detected: " + Input.get_joy_name(i))

## Set up default input configurations
func setup_default_configs():
	# Clear existing configs
	player_configs.clear()
	
	# Set up keyboard players
	var keyboard_players = min(max_players, DEFAULT_KEYBOARD_MAPPINGS.size())
	for i in range(keyboard_players):
		var config = InputConfig.new()
		config.player_id = i
		config.input_type = "keyboard"
		config.keyboard_map = DEFAULT_KEYBOARD_MAPPINGS[i].duplicate()
		player_configs[i] = config
	
	# Set up controller players
	var controller_start_id = keyboard_players
	for i in range(controllers.size()):
		var player_id = controller_start_id + i
		if player_id >= max_players:
			break
			
		var config = InputConfig.new()
		config.player_id = player_id
		config.input_type = "controller"
		config.controller_id = controllers[i]
		player_configs[player_id] = config

## Configure custom keyboard mapping for a player
## @param player_id: The player to configure
## @param key_map: Dictionary with keys: "up", "down", "left", "right", "pause", "exit", "restart"
func set_keyboard_mapping(player_id: int, key_map: Dictionary):
	if not player_configs.has(player_id):
		return
		
	var config = player_configs[player_id]
	if config.input_type != "keyboard":
		return
		
	config.keyboard_map = key_map.duplicate()

## Get current input configuration for a player
## @param player_id: The player ID
## @return: InputConfig object or null if not found
func get_player_config(player_id: int):
	return player_configs.get(player_id, null)

## Get all active player IDs
## @return: Array of player IDs
func get_active_players():
	return player_configs.keys()

## Process input events
func _input(event):
	# Handle keyboard input
	for player_id in player_configs.keys():
		var config = player_configs[player_id]
		if config.input_type == "keyboard":
			process_keyboard_input(player_id, config, event)
	
	# Handle controller input
	for player_id in player_configs.keys():
		var config = player_configs[player_id]
		if config.input_type == "controller":
			process_controller_input(player_id, config)

## Process keyboard input for a specific player
## @param player_id: The player ID
## @param config: The input configuration
## @param event: The input event
func process_keyboard_input(player_id: int, config: InputConfig, event):
	if not event is InputEventKey:
		return
		
	var key_map = config.keyboard_map
	
	# Direction changes
	var new_direction = null
	if event.pressed:
		if event.keycode == key_map["up"]:
			new_direction = Vector2.UP
		elif event.keycode == key_map["down"]:
			new_direction = Vector2.DOWN
		elif event.keycode == key_map["left"]:
			new_direction = Vector2.LEFT
		elif event.keycode == key_map["right"]:
			new_direction = Vector2.RIGHT
		elif event.keycode == key_map["pause"]:
			pause_pressed.emit(player_id)
		elif event.keycode == key_map["exit"]:
			exit_pressed.emit(player_id)
		elif event.keycode == key_map["restart"]:
			restart_pressed.emit(player_id)
	
	if new_direction != null and new_direction != config.last_direction:
		config.last_direction = new_direction
		direction_changed.emit(player_id, new_direction)

## Process controller input for all controller players
func process_controller_input(player_id: int, config: InputConfig):
	var controller_id = config.controller_id
	
	# Check if controller is still connected
	if not Input.is_joy_known(controller_id):
		return
	
	# Direction changes using D-pad
	var new_direction = null
	
	if Input.is_joy_button_pressed(controller_id, JOY_BUTTON_DPAD_UP):
		new_direction = Vector2.UP
	elif Input.is_joy_button_pressed(controller_id, JOY_BUTTON_DPAD_DOWN):
		new_direction = Vector2.DOWN
	elif Input.is_joy_button_pressed(controller_id, JOY_BUTTON_DPAD_LEFT):
		new_direction = Vector2.LEFT
	elif Input.is_joy_button_pressed(controller_id, JOY_BUTTON_DPAD_RIGHT):
		new_direction = Vector2.RIGHT
	
	# Alternative: Use analog stick
	var axis_left = Vector2(
		Input.get_joy_axis(controller_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(controller_id, JOY_AXIS_LEFT_Y)
	)
	
	if axis_left.length() > 0.5:
		# Convert analog input to discrete directions
		if abs(axis_left.x) > abs(axis_left.y):
			new_direction = Vector2.RIGHT * sign(axis_left.x)
		else:
			new_direction = Vector2.DOWN * sign(axis_left.y)
	
	# Action buttons
	if Input.is_joy_button_just_pressed(controller_id, JOY_BUTTON_START):
		pause_pressed.emit(player_id)
	elif Input.is_joy_button_just_pressed(controller_id, JOY_BUTTON_BACK):
		exit_pressed.emit(player_id)
	elif Input.is_joy_button_just_pressed(controller_id, JOY_BUTTON_Y):
		restart_pressed.emit(player_id)
	
	if new_direction != null and new_direction != config.last_direction:
		config.last_direction = new_direction
		direction_changed.emit(player_id, new_direction)

## Add a new player with specified input type
## @param input_type: "keyboard" or "controller"
## @param key_map: Optional keyboard mapping (only for keyboard type)
## @param controller_id: Optional controller ID (only for controller type)
## @return: The new player ID or -1 if max players reached
func add_player(input_type: String, key_map: Dictionary = {}, controller_id: int = -1):
	if player_configs.size() >= max_players:
		return -1
	
	var new_player_id = player_configs.size()
	var config = InputConfig.new()
	config.player_id = new_player_id
	config.input_type = input_type
	
	if input_type == "keyboard":
		config.keyboard_map = key_map if key_map else DEFAULT_KEYBOARD_MAPPINGS.get(new_player_id, {})
	elif input_type == "controller":
		if controller_id == -1 and controllers.size() > 0:
			controller_id = controllers[0]
		config.controller_id = controller_id
	
	player_configs[new_player_id] = config
	return new_player_id

## Remove a player
## @param player_id: The player to remove
func remove_player(player_id: int):
	if player_configs.has(player_id):
		player_configs.erase(player_id)

## Check if a specific key is already mapped
## @param key: The key to check
## @return: Array of players using this key
func is_key_mapped(key: int):
	var users = []
	for player_id in player_configs.keys():
		var config = player_configs[player_id]
		if config.input_type == "keyboard":
			for action in config.keyboard_map.values():
				if action == key:
					users.append(player_id)
					break
	return users
