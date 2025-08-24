## Main game controller for the Snake game.
##
## This class manages the overall game state, coordinates between the snake and food,
## handles scoring, pause functionality, and manages different input methods.
## It serves as the central hub for all game logic and interactions.
extends Node2D

@onready var snake: Node2D = null                    # Reference to snake instance
@onready var food: Node2D = null                     # Reference to food instance  
@onready var grid_background: Node2D = null          # Reference to grid background
@onready var score_label: Label = null               # Reference to score label
@onready var game_over_rect: Control = null          # Reference to game over overlay
@onready var game_over_sound: AudioStreamPlayer = null # Reference to game over sound

var score: int = 0                           # Current score, increases when snake eats food
var game_over: bool = false                  # Flag indicating if game is over
var is_paused: bool = false                  # Flag indicating if game is paused
var eat_sound: AudioStreamPlayer = null      # Audio player for eating sound effect
var background_music: AudioStreamPlayer = null # Audio player for background music
var enemies: Array[Node2D] = []              # Array storing all active enemy instances

## Reference to the universal input manager instance
var input_manager: Node = null


## Initialize the game when the node enters the scene tree.
##
## Sets up the snake, food, audio, and input systems.
## Called automatically by the Godot engine when the scene is loaded.
func _ready() -> void:
	# Cache node references
	grid_background = $GridBackground
	score_label = $CanvasLayer/ScoreLabel
	game_over_rect = $CanvasLayer/GameOverRect
	game_over_sound = $CanvasLayer/GameOverSound
	
	# Create and initialize the snake
	var snake_scene = load("res://scenes/snake.gd")
	snake = snake_scene.new()
	add_child(snake)
	snake.game_over.connect(_on_snake_game_over)
	
	# Create and initialize the food
	var food_scene = load("res://scenes/food.tscn")
	food = food_scene.instantiate()
	add_child(food)
	
	# Set up eating sound effect
	eat_sound = AudioStreamPlayer.new()
	eat_sound.stream = load("res://sfx/gotcha.wav")
	eat_sound.bus = "SFX" # Assign to SFX bus for volume control
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
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	# Wait for the first process frame to ensure all nodes (like GridBackground)
	# have their final sizes calculated. This is crucial for correct initial placement.
	await get_tree().process_frame

	# Now, it's safe to place the food at a random, valid position.
	# We use respawn_safe to ensure the food doesn't spawn on the snake's head.
	var block_size: int = ProjectSettings.get_setting("global/block_size")
	var snake_head_world_pos: Vector2 = grid_background.get_grid_offset() + snake.body[0] * block_size
	food.respawn_safe(snake_head_world_pos)

## Configure input handling.
##
## Loads and initializes the universal input manager and connects its signals.
func setup_input() -> void:
	# Set up the universal input manager
	var manager_scene = load("res://tools/manager_input.gd")
	input_manager = manager_scene.new()
	add_child(input_manager)
	
	# Connect to the input manager's signals
	input_manager.direction_changed.connect(_on_direction_changed)
	input_manager.pause_pressed.connect(_on_pause_pressed)
	input_manager.exit_pressed.connect(_on_exit_pressed)
	input_manager.restart_pressed.connect(_on_restart_pressed)

## Main game loop processing called every frame.
##
## Handles collision detection between snake and food/poison items,
## updates score, and manages game state transitions.
func _process(_delta: float) -> void:
	# Skip processing when paused or game over
	if is_paused or game_over:
		return
	
	var block_size: int = ProjectSettings.get_setting("global/block_size")
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	
	# Calculate snake head position in world coordinates
	var snake_head_world_pos: Vector2 = grid_offset + snake.body[0] * block_size
	
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
	for enemy: Node2D in enemies:
		for segment: Vector2 in enemy.body:
			if snake.body[0] == segment:
				_on_snake_game_over()  # Trigger game over on enemy collision
				return

## Update the score display label.
##
## Shows current score during gameplay or "Pause" when game is paused.
func update_score_display() -> void:
	if is_paused:
		score_label.text = "Pause"
	else:
		score_label.text = "Score: " + str(score)

## Handle game over event triggered by the snake.
##
## Stops snake movement, displays game over UI, plays game over sound,
## stops background music, and sets the game over flag to prevent further gameplay.
func _on_snake_game_over() -> void:
	print("Game Over signal received!")
	snake.timer.stop()  # Stop snake movement
	game_over_rect.visible = true  # Show game over screen
	game_over_sound.play()  # Play game over sound effect
	background_music.stop()  # Stop background music during game over
	game_over = true

## Handle direction change from input systems.
##
## Updates the snake's direction while preventing 180-degree turns
## that would cause immediate self-collision.
## @param new_direction: The new direction vector to attempt
func _on_direction_changed(new_direction: Vector2) -> void:
	if game_over or is_paused:
		return
	
	# Prevent reversing into itself (180-degree turns)
	var direction_changed: bool = false
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
func _on_pause_pressed() -> void:
	if game_over:
		return
	is_paused = not is_paused
	snake.timer.paused = is_paused
	
	# Control background music based on pause state
	if is_paused:
		if background_music.playing:
			background_music.stop()
	else:
		if not background_music.playing:
			background_music.play()
	
	update_score_display()

## Handle exit action from input systems.
##
## Immediately ends the game and returns to the start scene.
func _on_exit_pressed() -> void:
	return_to_start_scene()

## Handle restart action from input systems.
##
## Reloads the current scene to restart the game, but only when game is over.
func _on_restart_pressed() -> void:
	if game_over:
		get_tree().reload_current_scene()

## Handle global input events for restart functionality.
##
## Provides fallback restart functionality using SPACE key when game is over.
## @param event: The input event to process
func _input(event: InputEvent) -> void:
	# Fallback for SPACE key restart when game is over
	if game_over and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

## Add a new enemy to the game field.
##
## Creates an enemy at a safe location (not on snake head) and
## adds it to the enemies array. Enemies respawn automatically.
func add_enemy() -> void:
	# Grow existing enemies
	for e: Node2D in enemies:
		e.grow()
	
	var enemy_scene = load("res://scenes/enemy.tscn")
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	var block_size: int = ProjectSettings.get_setting("global/block_size")
	enemy.respawn_safe(snake.body[0] * block_size)
	enemies.append(enemy)
	
	# Connect timer to respawn enemy when it expires
	enemy.spawn_timer.timeout.connect(_on_enemy_respawn.bind(enemy))

## Handle enemy respawn when timer expires.
##
## Respawns the enemy at a new safe location.
## @param enemy: The enemy instance to respawn
func _on_enemy_respawn(enemy: Node2D) -> void:
	var block_size: int = ProjectSettings.get_setting("global/block_size")
	enemy.respawn_safe(snake.body[0] * block_size)

## Handle viewport size changes.
##
## Updates all game elements when the window is resized.
func _on_viewport_size_changed() -> void:
	# Ensure food stays within bounds after resize
	food.respawn()
	
	# Ensure enemies stay within bounds after resize
	var block_size: int = ProjectSettings.get_setting("global/block_size")
	for enemy: Node2D in enemies:
		enemy.respawn_safe(snake.body[0] * block_size)

## Return to the start scene from the game.
##
## Stops all game audio and switches back to the start screen.
func return_to_start_scene() -> void:
	background_music.stop()
	get_tree().change_scene_to_file("res://scenes/start_scene.tscn")
