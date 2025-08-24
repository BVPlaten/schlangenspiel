## Snake entity for the Snake game.
##
## This class handles the snake's movement logic, collision detection,
## growth mechanism, and game over signaling. The snake moves on a grid
## system with screen wrapping and self-collision detection.
extends Node2D

## Signal emitted when the snake collides with itself
signal game_over

var direction: Vector2 = Vector2.RIGHT                    # Current movement vector (RIGHT, LEFT, UP, DOWN)
var body: Array[Vector2] = [Vector2(5, 5)]               # Array of Vector2 positions representing body segments (head at index 0)
var body_directions: Array[Vector2] = [Vector2.RIGHT]    # Array of directions for each body segment
var timer: Timer = null                                  # Timer controlling movement speed
@export var move_interval: float = 0.05                  # Movement interval in seconds (lower = faster)
var base_move_interval: float = 0.0                      # Base movement interval (normal speed)
var new_segment: bool = false                            # Flag indicating if snake should grow on next move
var speed_boost_timer: Timer = null                      # Timer for speed boost duration
var is_speed_boosted: bool = false                       # Flag indicating if speed boost is active
var speed_boost_multiplier: float = 2.0                  # Multiplier for speed boost
var speed_boost_duration: float = 0.2                    # Duration of speed boost
var head_texture: Texture2D = null                       # Texture for head sprite
var body_texture: Texture2D = null                       # Texture for body sprite
var sprite_nodes: Array[Sprite2D] = []                   # Array of Sprite2D nodes for visual representation
## Minimum grid dimensions (10x10 fields)
var min_grid_size: Vector2 = Vector2(10, 10)

# Cached references for performance
@onready var grid_background: Node2D = null
@onready var block_size: int = 0

## Initialize the snake when the node enters the scene tree.
##
## Sets up the movement timer, configures the movement interval,
## loads sprite textures, and starts the game loop. Called automatically by Godot engine.
func _ready() -> void:
	# Cache references for performance
	grid_background = get_parent().get_node("GridBackground")
	block_size = ProjectSettings.get_setting("global/block_size")
	
	# Load settings
	var global_speed = ProjectSettings.get_setting("global/movement_speed", 0.05)
	if global_speed > 0:
		move_interval = global_speed
	
	var global_multiplier = ProjectSettings.get_setting("global/speed_boost_multiplier", 2.0)
	if global_multiplier > 0:
		speed_boost_multiplier = global_multiplier
	
	var global_duration = ProjectSettings.get_setting("global/speed_boost_duration", 0.2)
	if global_duration > 0:
		speed_boost_duration = global_duration
	
	# Store base movement interval
	base_move_interval = move_interval
	
	# Load sprite textures
	head_texture = load("res://gfx/snake_head.png")
	body_texture = load("res://gfx/snake_body.png")
	
	# Create initial sprite for head
	create_sprite_nodes()
	
	# Create and configure movement timer
	timer = Timer.new()
	timer.wait_time = move_interval
	timer.timeout.connect(_on_Timer_timeout)
	add_child(timer)
	timer.start()  # Start the game loop
	
	# Create and configure speed boost timer
	speed_boost_timer = Timer.new()
	speed_boost_timer.wait_time = speed_boost_duration
	speed_boost_timer.one_shot = true
	speed_boost_timer.timeout.connect(_on_speed_boost_timeout)
	add_child(speed_boost_timer)
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_size_changed)

## Timer callback for snake movement.
##
## Called at regular intervals based on move_interval. Handles:
## - Movement calculation based on current direction
## - Screen wrapping (snake appears on opposite side)
## - Self-collision detection
## - Body growth when food is eaten
func _on_Timer_timeout() -> void:
	var head: Vector2 = body[0]
	var new_head: Vector2 = head + direction
	
	# Get actual grid dimensions from the grid background
	var grid_size: Vector2 = grid_background.get_actual_grid_size()
	
	# Handle horizontal screen wrapping within actual grid
	if new_head.x >= grid_size.x:
		new_head.x = 0  # Wrap to left edge
	if new_head.x < 0:
		new_head.x = grid_size.x - 1  # Wrap to right edge
	
	# Handle vertical screen wrapping within actual grid
	if new_head.y >= grid_size.y:
		new_head.y = 0  # Wrap to top edge
	if new_head.y < 0:
		new_head.y = grid_size.y - 1  # Wrap to bottom edge

	# Check for self-collision - game over if head hits any body segment
	for i: int in range(1, body.size()):
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
func create_sprite_nodes() -> void:
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	
	# Clear existing sprites
	for sprite: Sprite2D in sprite_nodes:
		sprite.queue_free()
	sprite_nodes.clear()
	
	# Create sprites for each body segment
	for i: int in range(body.size()):
		var sprite: Sprite2D = Sprite2D.new()
		
		# Use head texture for first segment, body texture for others
		if i == 0:
			sprite.texture = head_texture
		else:
			sprite.texture = body_texture
		
		# Scale sprite to match block size
		if sprite.texture:
			var texture_size: Vector2 = sprite.texture.get_size()
			if texture_size.x > 0 and texture_size.y > 0:
				sprite.scale = Vector2(block_size / texture_size.x, block_size / texture_size.y)
		
		# Position sprite with grid offset for centering
		sprite.position = grid_offset + body[i] * block_size + Vector2(float(block_size)/2.0, float(block_size)/2.0)
		
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
func update_sprites() -> void:
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	
	# Adjust sprite count to match body size
	while sprite_nodes.size() < body.size():
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = body_texture
		if sprite.texture:
			var texture_size: Vector2 = sprite.texture.get_size()
			if texture_size.x > 0 and texture_size.y > 0:
				sprite.scale = Vector2(block_size / texture_size.x, block_size / texture_size.y)
		add_child(sprite)
		sprite_nodes.append(sprite)
	
	while sprite_nodes.size() > body.size():
		var sprite: Sprite2D = sprite_nodes.pop_back()
		sprite.queue_free()
	
	# Update positions and textures
	for i: int in range(body.size()):
		var sprite: Sprite2D = sprite_nodes[i]
		
		# Update texture (head vs body)
		if i == 0:
			sprite.texture = head_texture
			update_head_rotation(sprite)
		else:
			sprite.texture = body_texture
			update_body_rotation(sprite, i)
		
		# Update position with grid offset for centering
		sprite.position = grid_offset + body[i] * block_size + Vector2(float(block_size)/2.0, float(block_size)/2.0)

## Update head sprite rotation based on movement direction.
##
## Rotates the head sprite to face the current movement direction.
## @param head_sprite: The Sprite2D node representing the snake's head
func update_head_rotation(head_sprite: Sprite2D) -> void:
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
func update_body_rotation(body_sprite: Sprite2D, segment_index: int) -> void:
	if segment_index < body_directions.size():
		var segment_direction: Vector2 = body_directions[segment_index]
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
func grow() -> void:
	new_segment = true

## Activate speed boost after direction change.
##
## Increases movement speed by the configured multiplier for the configured duration.
## Called by the main controller when direction changes.
func activate_speed_boost() -> void:
	if not is_speed_boosted:
		is_speed_boosted = true
		# Divide interval by multiplier to increase speed
		var boosted_interval: float = base_move_interval / speed_boost_multiplier
		timer.wait_time = boosted_interval
		speed_boost_timer.start()

## Reset speed to normal after boost timer expires.
##
## Called automatically by the speed boost timer after the configured duration.
func _on_speed_boost_timeout() -> void:
	is_speed_boosted = false
	timer.wait_time = base_move_interval

## Handle viewport size changes.
##
## Updates sprites when the window is resized.
func _on_viewport_size_changed() -> void:
	update_sprites()
