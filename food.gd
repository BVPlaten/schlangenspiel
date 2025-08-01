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

## Initialize the food when the node enters the scene tree.
##
## Sets up the respawn timer and starts automatic respawning.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
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
		alpha = lerp(1.0, 0.1, fade_progress)
		alpha = max(alpha, 0.1)  # Ensure minimum visibility
		queue_redraw()

## Custom drawing for the food item.
##
## Draws a white rectangle representing the food item on the grid.
## The transparency is controlled by the alpha value for fade effects.
func _draw():
	var block_size = ProjectSettings.get_setting("global/block_size")
	var color = Color.WHITE
	color.a = alpha  # Apply transparency
	draw_rect(Rect2(0, 0, block_size, block_size), color)

## Respawn the food at a new random position.
##
## Calculates a random grid position within the viewport boundaries
## and moves the food to that position. Resets fade effects and timers.
func respawn():
	var block_size = ProjectSettings.get_setting("global/block_size")
	var viewport_size = get_viewport_rect().size
	
	# Calculate random grid position
	var x = randi_range(0, floor(viewport_size.x / block_size) - 1)
	var y = randi_range(0, floor(viewport_size.y / block_size) - 1)
	
	# Set position based on grid coordinates
	position = Vector2(x * block_size, y * block_size)
	
	# Reset visual effects and timers
	alpha = 1.0
	life_time = 0.0
	queue_redraw()

## Timer callback for automatic respawning.
##
## Called when the spawn timer expires. Triggers respawn at a new random position.
func _on_spawn_timer_timeout():
	respawn()
