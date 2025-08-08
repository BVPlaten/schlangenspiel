## Start scene controller for the Snake game.
##
## This class manages the start screen with title graphics, background music,
## and a simple menu system for navigation between game and options.
extends Control

## Reference to the title graphics sprite
@onready var title_sprite = $TitleSprite
## Reference to the title music player
var title_music
## Reference to the menu container
@onready var menu_container = $MenuContainer
## Currently selected menu option
var selected_option = 0
## Array of menu buttons
var menu_buttons = []

## Initialize the start scene when it enters the scene tree.
##
## Sets up the title graphics, background music, and menu system.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	# Apply green transparency to the scene
	#modulate = Color(0, 1, 0, 0.75)
	
	# Set up title music
	title_music = AudioStreamPlayer.new()
	var music_stream = load("res://sfx/startscreen.mp3")
	if music_stream:
		music_stream.loop = true  # Enable looping for title music
	title_music.stream = music_stream
	add_child(title_music)
	title_music.play()
	
	# Configure the scene
	configure_title_graphics()
	create_menu()
	update_menu_selection()
	
	# Set focus to this control for input handling
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()

## Configure the title graphics to fill the screen.
##
## Centers the title sprite and scales it to fit the viewport while maintaining aspect ratio.
func configure_title_graphics():
	var viewport_size = get_viewport_rect().size
	
	# Center the title sprite
	title_sprite.position = viewport_size / 2
	
	# Scale the sprite to fit the screen while maintaining aspect ratio
	var texture_size = title_sprite.texture.get_size()
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var scale_factor = min(scale_x, scale_y)
	
	# Apply scaling with slight padding
	title_sprite.scale = Vector2(scale_factor, scale_factor) * 0.9
	
## Create the menu buttons and layout.
##
## Sets up Start and Options buttons with proper positioning and styling.
func create_menu():
	var viewport_size = get_viewport_rect().size

	# Load the font
	var font = load("res://gfx/KidpixiesRegular-p0Z1.ttf")

	# Define menu items with their text and the action to perform when pressed.
	# This makes it easy to add more buttons in the future.
	var menu_items_data = [
		{"text": "Start", "action": _on_start_pressed},
		{"text": "Options", "action": _on_options_pressed}
	]

	# Create buttons in a loop to avoid repetition
	for item_data in menu_items_data:
		var button = Button.new()
		button.text = item_data.text
		button.custom_minimum_size = Vector2(200, 50)
		button.add_theme_font_override("font", font)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(item_data.action)
		menu_buttons.append(button)
		menu_container.add_child(button)

	# Configure menu container
	menu_container.position = Vector2(viewport_size.x / 2, viewport_size.y * 0.8)

	# Set up vertical layout
	menu_container.add_theme_constant_override("separation", 20)

## Handle keyboard input for menu navigation.
##
## Supports arrow keys and Enter for menu navigation and selection.
## @param event: The input event to process
func _input(event):
	if event.is_action_pressed("ui_up"):
		selected_option = wrapi(selected_option - 1, 0, menu_buttons.size())
		update_menu_selection()
	elif event.is_action_pressed("ui_down"):
		selected_option = wrapi(selected_option + 1, 0, menu_buttons.size())
		update_menu_selection()
	elif event.is_action_pressed("ui_accept"):
		menu_buttons[selected_option].emit_signal("pressed")

## Update the visual selection state of menu buttons.
##
## Highlights the currently selected button and unhighlights others.
func update_menu_selection():
	for i in range(menu_buttons.size()):
		if i == selected_option:
			menu_buttons[i].add_theme_color_override("font_color", Color.YELLOW)
			menu_buttons[i].add_theme_stylebox_override("normal", get_theme_stylebox("pressed"))
		else:
			menu_buttons[i].add_theme_color_override("font_color", Color.WHITE)
			menu_buttons[i].add_theme_stylebox_override("normal", get_theme_stylebox("normal"))

## Handle Start button press.
##
## Stops title music and switches to the main game scene.
func _on_start_pressed():
	title_music.stop()
	get_tree().change_scene_to_file("res://main.tscn")

## Handle Options button press.
##
## Stops title music and switches to the options scene.
func _on_options_pressed():
	title_music.stop()
	get_tree().change_scene_to_file("res://options_scene.tscn")

## Clean up resources when the scene is exited.
##
## Ensures title music is properly stopped when leaving the start scene.
func _exit_tree():
	if title_music and title_music.playing:
		title_music.stop()
