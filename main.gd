## Main game controller for the Snake game.
##
## This class manages the overall game state, coordinates between the snake and food,
## handles scoring, pause functionality, and manages different input methods.
## It serves as the central hub for all game logic and interactions.
extends Node2D

var snake             # Referenz zur Schlangeninstanz
var food              # Referenz zur Futterinstanz
var score = 0         # Aktueller Spielstand, erhöht sich, wenn die Schlange Futter frisst
var game_over = false # Flag, das anzeigt, ob das Spiel beendet ist
var is_paused = false # Flag, das anzeigt, ob das Spiel aktuell pausiert ist
var eat_sound         # Audio-Player für den Fress-Soundeffekt
var background_music  # Audio-Player für die Hintergrundmusik
var enemies = []      # Array, das alle aktiven Gegnerinstanzen auf dem Spielfeld speichert

## Input configuration mode: "keyboard", "controller", or "both"
## Determines which input methods are active for player control
@export var input_mode = "both"
## Reference to keyboard input handler instance
var keyboard_input
## Reference to controller input handler instance
var controller_input


## Initialize the game when the node enters the scene tree.
##
## Sets up the snake, food, audio, and input systems.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	# Create and initialize the snake
	snake = load("res://snake.gd").new()
	add_child(snake)
	snake.game_over.connect(Callable(self, "_on_snake_game_over"))
	
	# Create and initialize the food
	food = load("res://food.tscn").instantiate()
	add_child(food)
	food.respawn()
	
	# Set up eating sound effect
	eat_sound = AudioStreamPlayer.new()
	eat_sound.stream = load("res://sfx/gotcha.wav")
	add_child(eat_sound)
	
	# Set up background music
	background_music = AudioStreamPlayer.new()
	var music_stream = load("res://sfx/background_tune.mp3")
	if music_stream:
		music_stream.loop = true  # Enable looping on the audio stream
	background_music.stream = music_stream
	background_music.bus = "Music"  # Optional: Use dedicated music bus for volume control
	add_child(background_music)
	
	# Start background music
	background_music.play()
	
	# Configure input handling and initialize UI
	setup_input()
	update_score_display()
	
	# Connect to viewport size changes
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

## Configure input handling based on the selected input mode.
##
## Loads and initializes keyboard and/or controller input handlers
## depending on the input_mode setting. Connects signals for
## direction changes, pause, exit, and restart actions.
func setup_input():
	# Set up keyboard input if enabled
	if input_mode == "keyboard" or input_mode == "both":
		keyboard_input = load("res://input_keyboard.gd").new()
		add_child(keyboard_input)
		keyboard_input.direction_changed.connect(Callable(self, "_on_direction_changed"))
		keyboard_input.pause_pressed.connect(Callable(self, "_on_pause_pressed"))
		keyboard_input.exit_pressed.connect(Callable(self, "_on_exit_pressed"))
		keyboard_input.restart_pressed.connect(Callable(self, "_on_restart_pressed"))
	
	# Set up controller input if enabled
	if input_mode == "controller" or input_mode == "both":
		controller_input = load("res://input_controller.gd").new()
		add_child(controller_input)
		controller_input.direction_changed.connect(Callable(self, "_on_direction_changed"))
		controller_input.pause_pressed.connect(Callable(self, "_on_pause_pressed"))
		controller_input.exit_pressed.connect(Callable(self, "_on_exit_pressed"))
		controller_input.restart_pressed.connect(Callable(self, "_on_restart_pressed"))

## Main game loop processing called every frame.
##
## Handles collision detection between snake and food/poison items,
## updates score, and manages game state transitions.
func _process(_delta):
	# Skip processing when paused or game over
	if is_paused or game_over:
		return
	
	var block_size = ProjectSettings.get_setting("global/block_size")
	var grid_background = get_node("GridBackground")
	var grid_offset = grid_background.get_grid_offset()
	
	# Calculate snake head position in world coordinates
	var snake_head_world_pos = grid_offset + snake.body[0] * block_size
	
	# Check if snake head collides with food
	if snake_head_world_pos.distance_to(food.position) < block_size * 0.5:
		snake.grow()  # Make snake grow by one segment
		food.respawn()  # Move food to new random position
		score += 1  # Increase score
		eat_sound.play()  # Play eating sound effect
		
		# Add enemy every 5 points for increased difficulty
		if score % 5 == 0:
			add_enemy()
		
		update_score_display()
	
	# Check for collisions with enemies
	for enemy in enemies:
		for segment in enemy.body:
			if snake.body[0] == segment:
				_on_snake_game_over()  # Trigger game over on enemy collision
				return

## Update the score display label.
##
## Shows current score during gameplay or "Pause" when game is paused.
func update_score_display():
	if is_paused:
		$CanvasLayer/ScoreLabel.text = "Pause"
	else:
		$CanvasLayer/ScoreLabel.text = "Score: " + str(score)

## Handle game over event triggered by the snake.
##
## Stops snake movement, displays game over UI, plays game over sound,
## stops background music, and sets the game over flag to prevent further gameplay.
func _on_snake_game_over():
	print("Game Over signal received!")
	snake.timer.stop()  # Stop snake movement
	$CanvasLayer/GameOverRect.visible = true  # Show game over screen
	$CanvasLayer/GameOverSound.play()  # Play game over sound effect
	background_music.stop()  # Stop background music during game over
	game_over = true

## Handle direction change from input systems.
##
## Updates the snake's direction while preventing 180-degree turns
## that would cause immediate self-collision.
## @param new_direction: The new direction vector to attempt
func _on_direction_changed(new_direction):
	if game_over or is_paused:
		return
	
	# Prevent reversing into itself (180-degree turns)
	var direction_changed = false
	if new_direction == Vector2.RIGHT and snake.direction != Vector2.LEFT:
		snake.direction = new_direction
		direction_changed = true
	elif new_direction == Vector2.LEFT and snake.direction != Vector2.RIGHT:
		snake.direction = new_direction
		direction_changed = true
	elif new_direction == Vector2.UP and snake.direction != Vector2.DOWN:
		snake.direction = new_direction
		direction_changed = true
	elif new_direction == Vector2.DOWN and snake.direction != Vector2.UP:
		snake.direction = new_direction
		direction_changed = true
	
	# Activate speed boost if direction actually changed
	if direction_changed:
		snake.activate_speed_boost()

## Handle pause toggle from input systems.
##
## Toggles the paused state and updates snake movement and background music accordingly.
func _on_pause_pressed():
	if game_over:
		return
	is_paused = not is_paused
	snake.timer.paused = is_paused
	
	# Control background music based on pause state
	if is_paused:
		background_music.stream_paused = true
	else:
		background_music.stream_paused = false
	
	update_score_display()

## Handle exit action from input systems.
##
## Immediately ends the game and returns to the start scene.
func _on_exit_pressed():
	return_to_start_scene()

## Handle restart action from input systems.
##
## Reloads the current scene to restart the game, but only when game is over.
func _on_restart_pressed():
	if game_over:
		get_tree().reload_current_scene()

## Handle global input events for restart functionality.
##
## Provides fallback restart functionality using SPACE key when game is over.
## @param event: The input event to process
func _input(event):
	# Fallback for SPACE key restart when game is over
	if game_over and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

## Add a new enemy to the game field.
##
## Creates an enemy at a safe location (not on snake head) and
## adds it to the enemies array. Enemies respawn automatically.
func add_enemy():
	# Grow existing enemies
	for e in enemies:
		e.grow()
	
	var enemy = load("res://enemy.tscn").instantiate()
	add_child(enemy)
	enemy.respawn_safe(snake.body[0] * ProjectSettings.get_setting("global/block_size"))
	enemies.append(enemy)
	
	# Connect timer to respawn enemy when it expires
	enemy.spawn_timer.connect("timeout", Callable(self, "_on_enemy_respawn").bind(enemy))

## Handle enemy respawn when timer expires.
##
## Respawns the enemy at a new safe location.
## @param enemy: The enemy instance to respawn
func _on_enemy_respawn(enemy):
	enemy.respawn_safe(snake.body[0] * ProjectSettings.get_setting("global/block_size"))

## Handle viewport size changes.
##
## Updates all game elements when the window is resized.
func _on_viewport_size_changed():
	# Ensure food stays within bounds after resize
	food.respawn()
	
	# Ensure enemies stay within bounds after resize
	for enemy in enemies:
		enemy.respawn_safe(snake.body[0] * ProjectSettings.get_setting("global/block_size"))

## Return to the start scene from the game.
##
## Stops all game audio and switches back to the start screen.
func return_to_start_scene():
	background_music.stop()
	get_tree().change_scene_to_file("res://start_scene.tscn")
