## Food entity for the Snake game.
##
## This class manages food items that the snake can eat to grow and increase score.
## Food items automatically respawn at random positions and have visual effects
## including fade-out before respawning.
extends Node2D

## Current alpha transparency value for fade effects (1.0 = fully visible)
var alpha = 1.0
## Timer that controls automatic respawning
var spawn_timer
## Counter tracking how long this food item has existed
var life_time = 0.0
## Size of a grid block in pixels, cached for performance.
var block_size: int
## Minimum grid dimensions (10x10 fields)
var min_grid_size = Vector2(10, 10)

## Initialize the food when the node enters the scene tree.
##
## Sets up the respawn timer and starts automatic respawning.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	block_size = ProjectSettings.get_setting("global/block_size")
	spawn_timer = Timer.new()
	spawn_timer.set_wait_time(8.0)  # Respawn every 8 seconds
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	spawn_timer.start()
	
	# Connect to viewport size changes
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

## Update food appearance every frame.
##
## Handles fade-out effect as the food ages. After 4 seconds,
## the food starts fading out until it reaches minimum visibility.
## @param delta: Time elapsed since the last frame
func _process(delta):
	life_time += delta
	
	# Start fading after 4 seconds of existence
	if life_time >= 4.0:
		var fade_progress = (life_time - 4.0) / 4.0
		alpha = lerp(1.0, 0.1, fade_progress)
		alpha = max(alpha, 0.1)  # Ensure minimum visibility
		queue_redraw()

## Custom drawing for the food item.
##
## Draws a white rectangle representing the food item on the grid.
## The transparency is controlled by the alpha value for fade effects.
func _draw():
	var color = Color.WHITE
	color.a = alpha  # Apply transparency
	draw_rect(Rect2(0, 0, block_size, block_size), color)

## Respawn the food at a new random position.
##
## Calculates a random grid position within the centered grid and moves the food
## to that position. Resets fade effects and timers.
func respawn():
	var grid_background = get_parent().get_node("GridBackground")
	var grid_size = grid_background.get_actual_grid_size()
	var grid_offset = grid_background.get_grid_offset()
	
	# Calculate random grid position within actual grid bounds
	var x = randi_range(0, max(0, grid_size.x - 1))
	var y = randi_range(0, max(0, grid_size.y - 1))
	
	# Ensure valid grid dimensions
	if grid_size.x <= 0 or grid_size.y <= 0:
		grid_size = Vector2(10, 10)  # Fallback
	
	# Set position based on grid coordinates with offset for centering
	var new_position = grid_offset + Vector2(x * block_size, y * block_size)
	
	# Ensure position is within viewport bounds
	var viewport_size = get_viewport_rect().size
	new_position.x = clamp(new_position.x, 0, viewport_size.x - block_size)
	new_position.y = clamp(new_position.y, 0, viewport_size.y - block_size)
	
	position = new_position
	
	# Reset visual effects and timers
	alpha = 1.0
	life_time = 0.0
	queue_redraw()

## Respawn food at a safe position (not on snake head).
##
## Similar to respawn() but ensures the food doesn't spawn on the snake's head.
## @param snake_head_pos: Position of the snake's head to avoid
func respawn_safe(snake_head_pos):
	var grid_background = get_parent().get_node("GridBackground")
	var grid_size = grid_background.get_actual_grid_size()
	var grid_offset = grid_background.get_grid_offset()
	
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		var x = randi_range(0, grid_size.x - 1)
		var y = randi_range(0, grid_size.y - 1)
		var new_pos = grid_offset + Vector2(x * block_size, y * block_size)
		
		if new_pos != snake_head_pos:
			position = new_pos
			alpha = 1.0
			life_time = 0.0
			queue_redraw()
			return
		
		attempts += 1
	
	# Fallback: place at first available position
	var x = randi_range(0, grid_size.x - 1)
	var y = randi_range(0, grid_size.y - 1)
	position = grid_offset + Vector2(x * block_size, y * block_size)
	alpha = 1.0
	life_time = 0.0
	queue_redraw()

## Timer callback for automatic respawning.
##
## Called when the spawn timer expires. Triggers respawn at a new random position.
func _on_spawn_timer_timeout():
	respawn()

## Handle viewport size changes.
##
## Redraws the food when the window is resized.
func _on_viewport_size_changed():
	queue_redraw()
