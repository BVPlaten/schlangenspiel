## Snake entity for the Snake game.
##
## This class handles the snake's movement logic, collision detection,
## growth mechanism, and game over signaling. The snake moves on a grid
## system with screen wrapping and self-collision detection.
extends Node2D

## Signal emitted when the snake collides with itself
signal game_over

## Current movement direction vector (RIGHT, LEFT, UP, DOWN)
var direction = Vector2.RIGHT
## Array of Vector2 positions representing the snake's body segments
## The head is always at index 0
var body = [Vector2(5, 5)]
## Array of Vector2 directions for each body segment
## Stores the direction each segment was moving when it was created
var body_directions = [Vector2.RIGHT]
## Timer that controls movement speed and game loop
var timer
## Movement interval in seconds - lower values make snake move faster
@export var move_interval: float = ProjectSettings.get_setting("global/movement_speed", 0.05)
## Base movement interval (normal speed)
var base_move_interval: float
## Flag indicating if the snake should grow on the next move
var new_segment: bool = false
## Timer for speed boost duration
var speed_boost_timer
## Flag indicating if speed boost is active
var is_speed_boosted: bool = false
## Speed boost multiplier from project settings
var speed_boost_multiplier: float = ProjectSettings.get_setting("global/speed_boost_multiplier", 2.0)
## Speed boost duration from project settings
var speed_boost_duration: float = ProjectSettings.get_setting("global/speed_boost_duration", 0.2)
## Head sprite texture
var head_texture
## Body sprite texture
var body_texture
## Array of Sprite2D nodes for visual representation
var sprite_nodes = []

## Initialize the snake when the node enters the scene tree.
##
## Sets up the movement timer, configures the movement interval,
## loads sprite textures, and starts the game loop. Called automatically by Godot engine.
func _ready():
	# Store base movement interval
	base_move_interval = move_interval
	
	# Load sprite textures
	head_texture = load("res://gfx/snake_head.png")
	body_texture = load("res://gfx/snake_body.png")
	
	# Create initial sprite for head
	create_sprite_nodes()
	
	# Create and configure movement timer
	timer = Timer.new()
	timer.set_wait_time(move_interval)
	timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	add_child(timer)
	timer.start()  # Start the game loop
	
	# Create and configure speed boost timer
	speed_boost_timer = Timer.new()
	speed_boost_timer.set_wait_time(speed_boost_duration)
	speed_boost_timer.one_shot = true
	speed_boost_timer.connect("timeout", Callable(self, "_on_speed_boost_timeout"))
	add_child(speed_boost_timer)

## Timer callback for snake movement.
##
## Called at regular intervals based on move_interval. Handles:
## - Movement calculation based on current direction
## - Screen wrapping (snake appears on opposite side)
## - Self-collision detection
## - Body growth when food is eaten
func _on_Timer_timeout():
	var block_size = ProjectSettings.get_setting("global/block_size")
	var head = body[0]
	var new_head = head + direction
	
	var viewport_size = get_viewport_rect().size
	
	# Handle horizontal screen wrapping
	if new_head.x * block_size >= viewport_size.x:
		new_head.x = 0  # Wrap to left edge
	if new_head.x < 0:
		new_head.x = floor(viewport_size.x / block_size) - 1  # Wrap to right edge
	
	# Handle vertical screen wrapping
	if new_head.y * block_size >= viewport_size.y:
		new_head.y = 0  # Wrap to top edge
	if new_head.y < 0:
		new_head.y = floor(viewport_size.y / block_size) - 1  # Wrap to bottom edge

	# Check for self-collision - game over if head hits any body segment
	for i in range(1, body.size()):
		if new_head == body[i]:
			game_over.emit()  # Signal game over to main controller
			return

	# Add new head position to body
	body.insert(0, new_head)
	# Add current direction for new head
	body_directions.insert(0, direction)
	
	# Handle growth: keep new segment if flag is set, otherwise remove tail
	if new_segment:
		new_segment = false  # Reset growth flag after growing
	else:
		body.pop_back()  # Remove tail segment to maintain length
		body_directions.pop_back()  # Remove tail direction to maintain length
	
	# Update sprite representation
	update_sprites()

## Create sprite nodes for the snake body.
##
## Creates Sprite2D nodes for each body segment, with different textures
## for head and body parts. Scales sprites to match block_size.
func create_sprite_nodes():
	var block_size = ProjectSettings.get_setting("global/block_size")
	
	# Clear existing sprites
	for sprite in sprite_nodes:
		sprite.queue_free()
	sprite_nodes.clear()
	
	# Create sprites for each body segment
	for i in range(body.size()):
		var sprite = Sprite2D.new()
		
		# Use head texture for first segment, body texture for others
		if i == 0:
			sprite.texture = head_texture
		else:
			sprite.texture = body_texture
		
		# Scale sprite to match block size
		if sprite.texture:
			var texture_size = sprite.texture.get_size()
			sprite.scale = Vector2(block_size / texture_size.x, block_size / texture_size.y)
		
		# Position sprite
		sprite.position = body[i] * block_size + Vector2(block_size/2, block_size/2)
		
		# Rotate sprite based on direction
		if i == 0:
			update_head_rotation(sprite)
		else:
			update_body_rotation(sprite, i)
		
		add_child(sprite)
		sprite_nodes.append(sprite)

## Update sprite positions and rotations.
##
## Updates the visual representation of the snake by repositioning
## all sprite nodes and rotating the head based on movement direction.
func update_sprites():
	var block_size = ProjectSettings.get_setting("global/block_size")
	
	# Adjust sprite count to match body size
	while sprite_nodes.size() < body.size():
		var sprite = Sprite2D.new()
		sprite.texture = body_texture
		if sprite.texture:
			var texture_size = sprite.texture.get_size()
			sprite.scale = Vector2(block_size / texture_size.x, block_size / texture_size.y)
		add_child(sprite)
		sprite_nodes.append(sprite)
	
	while sprite_nodes.size() > body.size():
		var sprite = sprite_nodes.pop_back()
		sprite.queue_free()
	
	# Update positions and textures
	for i in range(body.size()):
		var sprite = sprite_nodes[i]
		
		# Update texture (head vs body)
		if i == 0:
			sprite.texture = head_texture
			update_head_rotation(sprite)
		else:
			sprite.texture = body_texture
			update_body_rotation(sprite, i)
		
		# Update position
		sprite.position = body[i] * block_size + Vector2(block_size/2, block_size/2)

## Update head sprite rotation based on movement direction.
##
## Rotates the head sprite to face the current movement direction.
## @param head_sprite: The Sprite2D node representing the snake's head
func update_head_rotation(head_sprite):
	if direction == Vector2.UP:
		head_sprite.rotation = 0
	elif direction == Vector2.RIGHT:
		head_sprite.rotation = PI/2
	elif direction == Vector2.DOWN:
		head_sprite.rotation = PI
	elif direction == Vector2.LEFT:
		head_sprite.rotation = 3*PI/2

## Update body sprite rotation based on stored direction.
##
## Rotates body segments to face the direction they were moving when created.
## Each segment maintains its original direction throughout its lifetime.
## @param body_sprite: The Sprite2D node representing a body segment
## @param segment_index: The index of the body segment
func update_body_rotation(body_sprite, segment_index):
	if segment_index < body_directions.size():
		var segment_direction = body_directions[segment_index]
		if segment_direction == Vector2.UP:
			body_sprite.rotation = 0
		elif segment_direction == Vector2.RIGHT:
			body_sprite.rotation = PI/2
		elif segment_direction == Vector2.DOWN:
			body_sprite.rotation = PI
		elif segment_direction == Vector2.LEFT:
			body_sprite.rotation = 3*PI/2
	else:
		body_sprite.rotation = 0  # Fallback

## Trigger snake growth on next move.
##
## Sets the growth flag which causes the snake to retain its tail segment
## on the next movement, effectively increasing its length by one.
## Called by the main controller when the snake eats food.
func grow():
	new_segment = true

## Activate speed boost after direction change.
##
## Increases movement speed by the configured multiplier for the configured duration.
## Called by the main controller when direction changes.
func activate_speed_boost():
	if not is_speed_boosted:
		is_speed_boosted = true
		# Divide interval by multiplier to increase speed
		var boosted_interval = base_move_interval / speed_boost_multiplier
		timer.set_wait_time(boosted_interval)
		speed_boost_timer.start()

## Reset speed to normal after boost timer expires.
##
## Called automatically by the speed boost timer after the configured duration.
func _on_speed_boost_timeout():
	is_speed_boosted = false
	timer.set_wait_time(base_move_interval)

