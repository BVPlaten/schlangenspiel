## Base class for grid-based entities in the Snake game.
##
## This class provides common functionality for entities that move on a grid,
## including movement, screen wrapping, and grid positioning.
class_name GridEntity
extends Node2D

## Signal emitted when the entity moves
signal moved(new_position: Vector2)

## Current movement direction
var direction: Vector2 = Vector2.ZERO
## Current grid position
var grid_position: Vector2 = Vector2.ZERO
## Array of body segments
var body: Array[Vector2] = []
## Flag for growing the entity
var new_segment: bool = false
## Size of a grid block in pixels, cached for performance
var block_size: int = 0

# Cached references for performance
@onready var grid_background: Node2D = null

## Initialize the entity when the node enters the scene tree.
##
## Sets up common functionality. Should be called from child classes.
func _base_ready() -> void:
	# Cache references for performance
	grid_background = get_parent().get_node("GridBackground")
	block_size = ProjectSettings.get_setting("global/block_size")

## Move the entity in the current direction with screen wrapping.
##
## Handles movement calculation, screen wrapping, and body management.
## @return: The new head position after movement
func move_on_grid() -> Vector2:
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
	moved.emit(new_head_pos)
	return new_head_pos

## Grow the entity by one segment.
##
## Sets the growth flag which causes the entity to retain its tail segment
## on the next movement.
func grow() -> void:
	new_segment = true

## Get the world position from grid coordinates.
##
## Converts grid coordinates to world position with grid offset.
## @param grid_coords: Grid coordinates to convert
## @return: World position
func grid_to_world(grid_coords: Vector2) -> Vector2:
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	return grid_offset + grid_coords * block_size

## Get the grid coordinates from world position.
##
## Converts world position to grid coordinates.
## @param world_pos: World position to convert  
## @return: Grid coordinates
func world_to_grid(world_pos: Vector2) -> Vector2:
	var grid_offset: Vector2 = grid_background.get_grid_offset()
	return (world_pos - grid_offset) / block_size

## Check if a position is within grid bounds.
##
## Verifies that grid coordinates are within the playable area.
## @param grid_coords: Grid coordinates to check
## @return: True if position is valid, false otherwise
func is_valid_grid_position(grid_coords: Vector2) -> bool:
	var grid_size: Vector2 = grid_background.get_actual_grid_size()
	return (grid_coords.x >= 0 and grid_coords.x < grid_size.x and
			grid_coords.y >= 0 and grid_coords.y < grid_size.y)
