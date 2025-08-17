## Grid background renderer for the Snake game.
##
## This class draws a visual grid overlay on the game field using dark gray lines.
## The grid helps players visualize the discrete movement positions and
## provides visual reference for the game's coordinate system.
extends Node2D

## Size of a grid block in pixels, cached for performance.
var block_size: int
## Minimum grid dimensions (10x10 fields)
var min_grid_size: Vector2 = Vector2(10, 10)
## Actual grid dimensions calculated for centering
var actual_grid_size: Vector2 = Vector2.ZERO
## Offset for centering the grid
var grid_offset: Vector2 = Vector2.ZERO

## Initialize the grid background when the node enters the scene tree.
##
## Triggers an immediate redraw to ensure the grid is visible from the start.
## Called automatically by the Godot engine when the scene is loaded.
func _ready() -> void:
	block_size = ProjectSettings.get_setting("global/block_size")
	queue_redraw()  # Ensure _draw is called once to render the grid
	# Connect to viewport size changes
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))

## Custom drawing for the grid background.
##
## Draws a complete grid centered in the viewport with equal borders on all sides.
## The grid lines are drawn in dark gray to provide subtle visual guidance.
func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var background_color: Color = ProjectSettings.get_setting("global/background_color")
	var border_color: Color = ProjectSettings.get_setting("global/border_color")
	var line_color: Color = Color(0.15, 0.15, 0.15, 1)  # Dark gray lines for subtle grid

	# Calculate maximum possible grid dimensions that fit the viewport
	var max_grid_width: int = int(viewport_size.x / block_size)
	var max_grid_height: int = int(viewport_size.y / block_size)
	
	# Ensure minimum grid size
	var grid_width: int = max(max_grid_width, min_grid_size.x)
	var grid_height: int = max(max_grid_height, min_grid_size.y)
	
	# Calculate actual grid dimensions (limited by viewport)
	grid_width = min(grid_width, max_grid_width)
	grid_height = min(grid_height, max_grid_height)
	
	actual_grid_size = Vector2(grid_width, grid_height)
	
	# Calculate grid offset for centering
	var total_grid_width: float = float(grid_width * block_size)
	var total_grid_height: float = float(grid_height * block_size)
	
	grid_offset = Vector2(
		(viewport_size.x - total_grid_width) / 2,
		(viewport_size.y - total_grid_height) / 2
	)
	
	# Draw background/border
	draw_rect(Rect2(Vector2.ZERO, viewport_size), border_color)
	
	# Draw game area background
	draw_rect(Rect2(grid_offset, Vector2(total_grid_width, total_grid_height)), background_color)
	
	# Draw vertical grid lines
	for x in range(0, grid_width + 1):
		var x_pos: float = grid_offset.x + x * block_size
		draw_line(
			Vector2(x_pos, grid_offset.y),  # Line start point (top)
			Vector2(x_pos, grid_offset.y + total_grid_height),  # Line end point (bottom)
			line_color
		)

	# Draw horizontal grid lines
	for y in range(0, grid_height + 1):
		var y_pos: float = grid_offset.y + y * block_size
		draw_line(
			Vector2(grid_offset.x, y_pos),  # Line start point (left)
			Vector2(grid_offset.x + total_grid_width, y_pos),  # Line end point (right)
			line_color
		)

## Get the actual grid offset for positioning other game elements.
##
## Returns the offset needed to position game elements correctly within the centered grid.
func get_grid_offset() -> Vector2:
	return grid_offset

## Get the actual grid dimensions.
##
## Returns the actual width and height of the grid in grid units.
func get_actual_grid_size() -> Vector2:
	return actual_grid_size

## Handle viewport size changes.
##
## Redraws the grid when the window is resized.
func _on_viewport_size_changed() -> void:
	queue_redraw()
