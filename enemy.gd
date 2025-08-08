## Enemy entity for the Snake game.
##
## This class manages enemy entities that move randomly on the grid.
## Enemies can collide with the snake and cause game over.
extends Node2D

## Current alpha transparency value for fade effects (1.0 = fully visible)
var alpha = 1.0
## Timer that controls automatic respawning
var spawn_timer
## Counter tracking how long this enemy has existed
var life_time = 0.0
## Timer that controls movement
var move_timer
## Current movement direction
var direction = Vector2.ZERO
## Current grid position
var grid_position = Vector2.ZERO
## Array of body segments
var body = []
## Flag for growing the enemy
var new_segment = false
## Size of a grid block in pixels, cached for performance
var block_size: int
## Minimum grid dimensions (10x10 fields)
var min_grid_size = Vector2(10, 10)

## Initialize the enemy when the node enters the scene tree.
##
## Sets up timers and starts movement. Called automatically by Godot engine.
func _ready():
	block_size = ProjectSettings.get_setting("global/block_size")
	
	spawn_timer = Timer.new()
	spawn_timer.set_wait_time(4.0)
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(spawn_timer)
	spawn_timer.start()
	
	move_timer = Timer.new()
	move_timer.set_wait_time(ProjectSettings.get_setting("global/movement_speed", 0.05))
	move_timer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	add_child(move_timer)
	move_timer.start()
	
	set_random_direction()
	body.append(grid_position)
	
	# Connect to viewport size changes
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

## Update enemy appearance every frame.
##
## Handles fade-out effect as the enemy ages.
## @param delta: Time elapsed since the last frame
func _process(delta):
	life_time += delta
	
	if life_time >= 2.0:
		var fade_progress = (life_time - 2.0) / 2.0
		alpha = lerp(1.0, 0.1, fade_progress)
		alpha = max(alpha, 0.1)
		queue_redraw()

## Custom drawing for the enemy.
##
## Draws red rectangles representing the enemy on the grid.
func _draw():
	var color = Color.RED
	color.a = alpha
	
	# Get grid offset for positioning
	var grid_background = get_parent().get_node("GridBackground")
	var grid_offset = grid_background.get_grid_offset()
	
	for segment in body:
		var pos = grid_offset + segment * block_size
		draw_rect(Rect2(pos, Vector2(block_size, block_size)), color)

## Respawn the enemy at a safe position away from the snake.
##
## Finds a random position that's at least 3 grid units away from the snake head.
## @param snake_head_pos: Position of the snake's head to avoid
func respawn_safe(snake_head_pos: Vector2):
	var grid_background = get_parent().get_node("GridBackground")
	var grid_size = grid_background.get_actual_grid_size()
	var grid_offset = grid_background.get_grid_offset()
	
	var safe_distance = 3
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		var x = randi_range(0, grid_size.x - 1)
		var y = randi_range(0, grid_size.y - 1)
		var new_pos = Vector2(x, y)
		
		# Check distance from snake head
		var distance = new_pos.distance_to((snake_head_pos - grid_offset) / block_size)
		if distance >= safe_distance:
			grid_position = new_pos
			body = [grid_position]
			alpha = 1.0
			life_time = 0.0
			set_random_direction()
			queue_redraw()
			return
		attempts += 1
	
	# Fallback if no safe position found
	grid_position = Vector2(0, 0)
	body = [grid_position]
	alpha = 1.0
	life_time = 0.0
	set_random_direction()
	queue_redraw()

## Set a random movement direction.
##
## Chooses one of the four cardinal directions randomly.
func set_random_direction():
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = directions[randi() % directions.size()]

## Timer callback for enemy movement.
##
## Moves the enemy in the current direction with screen wrapping.
func _on_move_timer_timeout():
	var grid_background = get_parent().get_node("GridBackground")
	var grid_size = grid_background.get_actual_grid_size()
	# var grid_offset = grid_background.get_grid_offset()
	
	var new_head_pos = body[0] + direction
	
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
	queue_redraw()

## Grow the enemy by one segment.
##
## Sets the growth flag which causes the enemy to retain its tail segment
## on the next movement.
func grow():
	new_segment = true

## Timer callback for automatic respawning.
##
## Called when the spawn timer expires.
func _on_spawn_timer_timeout():
	# This will be called from main.gd with snake head position
	pass

## Handle viewport size changes.
##
## Redraws the enemy when the window is resized.
func _on_viewport_size_changed():
	queue_redraw()
