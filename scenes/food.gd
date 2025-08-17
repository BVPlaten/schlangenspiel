## Food entity for the Snake game.
##
## This class manages food items that the snake can eat to grow and increase score.
## Food items automatically respawn at random positions and have visual effects
## including fade-out before respawning.
extends Node2D

## The visual representation of the food.
@onready var sprite: Sprite2D = $Sprite2D
 
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
func _ready() -> void:
	block_size = ProjectSettings.get_setting("global/block_size")

	# Scale the sprite to match the block size, ensuring the texture is valid.
	if sprite.texture:
		var texture_size = sprite.texture.get_size()
		if texture_size.x > 0 and texture_size.y > 0:
			sprite.scale = Vector2(block_size, block_size) / texture_size

	# Offset the sprite to center it within its grid cell.
	sprite.position = Vector2(block_size / 2.0, block_size / 2.0)

	spawn_timer = Timer.new()
	spawn_timer.set_wait_time(8.0)  # Respawn every 8 seconds
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	spawn_timer.start()

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
		sprite.modulate.a = lerp(1.0, 0.1, fade_progress)
		sprite.modulate.a = max(sprite.modulate.a, 0.1)  # Ensure minimum visibility

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
	sprite.modulate.a = 1.0
	life_time = 0.0

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
		var rand_x = randi_range(0, grid_size.x - 1)
		var rand_y = randi_range(0, grid_size.y - 1)
		var new_pos = grid_offset + Vector2(rand_x * block_size, rand_y * block_size)
		
		if new_pos != snake_head_pos:
			position = new_pos
			sprite.modulate.a = 1.0
			life_time = 0.0
			return
		
		attempts += 1
	
	# Fallback: place at first available position
	var fallback_x = randi_range(0, max(0, grid_size.x - 1))
	var fallback_y = randi_range(0, max(0, grid_size.y - 1))
	position = grid_offset + Vector2(fallback_x * block_size, fallback_y * block_size)
	sprite.modulate.a = 1.0
	life_time = 0.0

## Timer callback for automatic respawning.
##
## Called when the spawn timer expires. Triggers respawn at a new random position.
func _on_spawn_timer_timeout():
	respawn()
