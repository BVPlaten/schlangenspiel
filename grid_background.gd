## Grid background renderer for the Snake game.
##
## This class draws a visual grid overlay on the game field using dark gray lines.
## The grid helps players visualize the discrete movement positions and
## provides visual reference for the game's coordinate system.
extends Node2D

## Size of a grid block in pixels, cached for performance.
var block_size: int

## Initialize the grid background when the node enters the scene tree.
##
## Triggers an immediate redraw to ensure the grid is visible from the start.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	block_size = ProjectSettings.get_setting("global/block_size")
	queue_redraw()  # Ensure _draw is called once to render the grid

## Custom drawing for the grid background.
##
## Draws a complete grid of dark gray lines based on the global block_size setting.
## Creates both vertical and horizontal lines that form the game field's grid.
## The grid lines are drawn in dark gray to provide subtle visual guidance
## without being distracting during gameplay.
func _draw():
	var viewport_size = get_viewport_rect().size
	var line_color = Color(0.15, 0.15, 0.15, 1)  # Dark gray lines for subtle grid

	# Calculate grid dimensions based on viewport and block size
	var grid_width = int(viewport_size.x / block_size)
	var grid_height = int(viewport_size.y / block_size)

	# Draw vertical grid lines
	for x in range(0, grid_width + 1):
		draw_line(
			Vector2(x * block_size, 0),  # Line start point (top)
			Vector2(x * block_size, viewport_size.y),  # Line end point (bottom)
			line_color
		)

	# Draw horizontal grid lines
	for y in range(0, grid_height + 1):
		draw_line(
			Vector2(0, y * block_size),  # Line start point (left)
			Vector2(viewport_size.x, y * block_size),  # Line end point (right)
			line_color
		)
