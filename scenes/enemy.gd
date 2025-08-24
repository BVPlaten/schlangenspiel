## Enemy entity for the Snake game.
##
## This class manages enemy entities that move randomly on the grid.
## Enemies can collide with the snake and cause game over.
extends Node2D

## Current alpha transparency value for fade effects (1.0 = fully visible)
var alpha: float = 1.0
## Timer that controls automatic respawning
var spawn_timer: Timer = null
## Counter tracking how long this enemy has existed
var life_time: float = 0.0
## Timer that controls movement
var move_timer: Timer = null
## Current movement direction
var direction: Vector2 = Vector2.ZERO
## Current grid position
var grid_position: Vector2 = Vector2.ZERO
## Array of body segments
var body: Array[Vector2] = []
## Flag for growing the enemy
var new_segment: bool = false
## Size of a grid block in pixels, cached for performance
var block_size: int = 0
## Minimum grid dimensions (10x10 fields)
var min_grid_size: Vector2 = Vector2(10, 10)

# Cached references for performance
@onready var grid_background: Node2D = null

## Initialize the enemy when the node enters the scene tree.
##
## Sets up timers and starts movement. Called automatically by Godot engine.
func _ready() -> void:
	# Cache references for performance
	grid_background = get_parent().get_node("GridBackground")
	block_size = ProjectSettings.get_setting("global/block_size")
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 4.0
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	
	var global_speed = ProjectSettings.get_setting("global/movement_speed", 0.05)
	if global_speed > 0:
		move_timer = Timer.new()
		move_timer.wait_time = global_speed
		move_timer.timeout.connect(_on_move_timer_timeout)
		add_child(move_timer)
		move_timer.start()
	
	set_random_direction()
	body.append(grid_position)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Initial sprite setup
	update_sprite_position()

## Update enemy appearance every frame.
##
## Handles fade-out effect as the enemy ages and updates sprite position.
## @param delta: Time elapsed since the last frame
func _process(delta: float) -> void:
	life_time += delta
	
	if life_time >= 2.0:
		var fade_progress: float = (life_time - 2.0) / 2.0
		alpha = lerp(1.0, 0.1, fade_progress)
		alpha = max(alpha, 0.1)
	
	update_sprite_position()

## Update the sprite position and scale to fit the grid.
func update_sprite_position() -> void:
	var sprite = $Sprite2D
	if sprite and sprite.texture:
		# Get grid offset for positioning
		var grid_offset: Vector2 = grid_background.get_grid_offset()
		
		# Position based on current grid position
		var pos: Vector2 = grid_offset + grid_position * block_size
		sprite.position = pos
		
		# Scale sprite to fit grid cell
		var texture_size = sprite.texture.get_size()
		var scale_factor = Vector2(block_size / texture_size.x, block_size / texture_size.y)
		sprite.scale = scale_factor
		
		# Apply alpha for fade effect
		sprite.modulate = Color(1, 1, 1, alpha)

## Respawn the enemy at a safe position away from the snake.
##
## Finds a random position that's at least 3 grid units away from the snake head.
## @param snake_head_pos: Position of the snake's head to avoid
func respawn_safe(snake_head_pos: Vector2) -> void:
	var grid_size: Vector2 = grid_background.get_actual_grid_size()
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	
	var safe_distance: int = 3
	var attempts: int = 0
	var max_attempts: int = 100
	
	while attempts < max_attempts:
		var x: int = randi_range(0, int(grid_size.x) - 1)
		var y: int = randi_range(0, int(grid_size.y) - 1)
		var new_pos: Vector2 = Vector2(x, y)
		
		# Check distance from snake head
		var distance: float = new_pos.distance_to((snake_head_pos - grid_offset) / block_size)
		if distance >= safe_distance:
			grid_position = new_pos
			body = [grid_position]
			alpha = 1.0
			life_time = 0.0
			set_random_direction()
			update_sprite_position()
			return
		attempts += 1
	
	# Fallback if no safe position found
	grid_position = Vector2(0, 0)
	body = [grid_position]
	alpha = 1.0
	life_time = 0.0
	set_random_direction()
	update_sprite_position()

## Set a random movement direction.
##
## Chooses one of the four cardinal directions randomly.
func set_random_direction() -> void:
	var directions: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = directions[randi() % directions.size()]

## Timer callback for enemy movement.
##
## Moves the enemy in the current direction with screen wrapping.
func _on_move_timer_timeout() -> void:
	var grid_size: Vector2 = grid_background.get_actual_grid_size()
	
	var new_head_pos: Vector2 = body[0] + direction
	
	# Wrap around screen edges within actual grid
	if new_head_pos.x >= grid_size.x:
		new_head_pos.x = 0
	elif new_head_pos.x < 0:
		new_head_pos.x = grid_size.x - 1
	
	if new_head_pos.y >= grid_size.y:
		new_head_pos.y = 0
	elif new_head_pos.y < 0:
		new_head_pos.y = grid_size.y - 1
	
	body.insert(0, new_head_pos)
	
	if new_segment:
		new_segment = false
	else:
		body.pop_back()
	
	grid_position = new_head_pos
	update_sprite_position()

## Grow the enemy by one segment.
##
## Sets the growth flag which causes the enemy to retain its tail segment
## on the next movement.
func grow() -> void:
	new_segment = true

## Timer callback for automatic respawning.
##
## Called when the spawn timer expires.
func _on_spawn_timer_timeout() -> void:
	# This will be called from main.gd with snake head position
	pass

## Handle viewport size changes.
##
## Updates sprite position when the window is resized.
func _on_viewport_size_changed() -> void:
	update_sprite_position()
