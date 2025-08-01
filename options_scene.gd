## Options scene controller for the Snake game.
##
## This class manages a simple options menu with only a back button
## to return to the start screen. Can be extended for more options later.
extends Control

## Reference to the back button
var back_button

## Initialize the options scene when it enters the scene tree.
##
## Sets up the back button and basic UI layout.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	create_back_button()
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()  # Set focus for keyboard input

## Create the back button.
##
## Sets up a simple back button centered on screen.
func create_back_button():
	var viewport_size = get_viewport_rect().size
	
	# Create back button
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.add_theme_font_size_override("font_size", 24)
	back_button.pressed.connect(_on_back_pressed)
	
	# Position the button in center of screen
	back_button.position = Vector2(
		(viewport_size.x - back_button.custom_minimum_size.x) / 2,
		(viewport_size.y - back_button.custom_minimum_size.y) / 2
	)
	
	add_child(back_button)

## Handle keyboard input.
##
## Supports Enter key to go back to start screen.
## @param event: The input event to process
func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_back_pressed()

## Handle back button press.
##
## Switches back to the start scene.
func _on_back_pressed():
	get_tree().change_scene_to_file("res://start_scene.tscn")