extends Node2D

var alpha = 1.0
var spawn_timer
var life_time = 0.0
var move_timer
var direction = Vector2.ZERO
var grid_position = Vector2.ZERO
var body = []
var new_segment = false

func _ready():
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

func _process(delta):
	life_time += delta
	
	if life_time >= 2.0:
		var fade_progress = (life_time - 2.0) / 2.0
		alpha = lerp(1.0, 0.1, fade_progress)
		alpha = max(alpha, 0.1)
		queue_redraw()

func _draw():
	var block_size = ProjectSettings.get_setting("global/block_size")
	var color = Color.RED
	color.a = alpha
	for segment in body:
		draw_rect(Rect2(segment * block_size, Vector2(block_size, block_size)), color)

func respawn_safe(snake_head_pos: Vector2):
	var block_size = ProjectSettings.get_setting("global/block_size")
	var viewport_size = get_viewport_rect().size
	var grid_width = floor(viewport_size.x / block_size)
	var grid_height = floor(viewport_size.y / block_size)
	var safe_distance = 3
	
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		var x = randi_range(0, grid_width - 1)
		var y = randi_range(0, grid_height - 1)
		var new_pos = Vector2(x, y)
		
		# Check distance from snake head
		var distance = new_pos.distance_to(snake_head_pos / block_size)
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

func set_random_direction():
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	direction = directions[randi() % directions.size()]

func _on_move_timer_timeout():
	var block_size = ProjectSettings.get_setting("global/block_size")
	var viewport_size = get_viewport_rect().size
	var grid_width = floor(viewport_size.x / block_size)
	var grid_height = floor(viewport_size.y / block_size)
	
	var new_head_pos = body[0] + direction
	
	# Wrap around screen edges
	if new_head_pos.x >= grid_width:
		new_head_pos.x = 0
	elif new_head_pos.x < 0:
		new_head_pos.x = grid_width - 1
	
	if new_head_pos.y >= grid_height:
		new_head_pos.y = 0
	elif new_head_pos.y < 0:
		new_head_pos.y = grid_height - 1
	
	body.insert(0, new_head_pos)
	
	if new_segment:
		new_segment = false
	else:
		body.pop_back()
	
	grid_position = new_head_pos
	queue_redraw()

func grow():
	new_segment = true

func _on_spawn_timer_timeout():
	# This will be called from main.gd with snake head position
	pass
