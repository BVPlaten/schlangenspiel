## Options scene controller for the Snake game.
##
## This class manages an options menu with volume controls for music and sound effects,
## plus a back button to return to the start screen.
extends Control

## Reference to the back button
var back_button
## Reference to the volume slider
var volume_slider
## Reference to the volume label
var volume_label

## Current volume (0-10)
var current_volume: int = 10

## Initialize the options scene when it enters the scene tree.
##
## Sets up the volume slider, label, and back button.
## Called automatically by the Godot engine when the scene is loaded.
func _ready():
	load_settings()
	create_ui()
	set_focus_mode(Control.FOCUS_ALL)
	grab_focus()  # Set focus for keyboard input

## Load saved settings from config file
func load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		if parse_result == OK:
			var data = json.data
			current_volume = data.get("volume", 10)
		else:
			current_volume = 10
	else:
		current_volume = 10

## Save settings to config file
func save_settings():
	var data = {
		"volume": current_volume
	}
	
	var json_text = JSON.stringify(data, "\t")
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(json_text)
		file.close()

## Create the complete UI with volume control and back button
func create_ui():
	var viewport_size = get_viewport_rect().size
	
	# Create container for all UI elements
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	container.position = Vector2(viewport_size.x / 2 - 150, viewport_size.y / 2 - 150)
	container.size = Vector2(300, 300)
	
	# Volume control
	var volume_container = VBoxContainer.new()
	volume_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	volume_label = Label.new()
	volume_label.text = "Volume: %d" % current_volume
	volume_label.add_theme_font_size_override("font_size", 20)
	volume_container.add_child(volume_label)
	
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 10
	volume_slider.step = 1
	volume_slider.value = current_volume
	volume_slider.size = Vector2(300, 30)
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_slider.focus_mode = Control.FOCUS_ALL
	volume_container.add_child(volume_slider)
	
	container.add_child(volume_container)
	
	# Create back button
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.add_theme_font_size_override("font_size", 24)
	back_button.pressed.connect(_on_back_pressed)
	back_button.focus_mode = Control.FOCUS_ALL
	
	container.add_child(back_button)
	
	add_child(container)
	
	# Set initial focus to volume slider
	volume_slider.grab_focus()
	
	# Apply initial volume
	apply_volume(current_volume)

## Handle volume changes
func _on_volume_changed(value: float):
	current_volume = int(value)
	volume_label.text = "Volume: %d" % current_volume
	apply_volume(current_volume)

## Apply volume to audio system
func apply_volume(volume: int):
	var db_value = linear_to_db(volume / 10.0)
	AudioServer.set_bus_volume_db(0, db_value)  # Master bus
	
	# Mute at 0
	AudioServer.set_bus_mute(0, volume == 0)

## Convert linear volume to decibel scale
func linear_to_db(linear_volume: float) -> float:
	if linear_volume <= 0.0:
		return -80.0
	return 20.0 * log(linear_volume) / log(10.0)

## Handle keyboard and controller input
func _input(event):
	if event.is_action_pressed("ui_accept"):
		if back_button.has_focus():
			_on_back_pressed()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		navigate_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		navigate_focus(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		adjust_slider(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		adjust_slider(1)
		get_viewport().set_input_as_handled()

## Navigate focus between UI elements
func navigate_focus(direction: int):
	var focusable_nodes = [volume_slider, back_button]
	var current_index = -1
	
	for i in range(focusable_nodes.size()):
		if focusable_nodes[i].has_focus():
			current_index = i
			break
	
	if current_index == -1:
		return
	
	var new_index = current_index + direction
	if new_index < 0:
		new_index = focusable_nodes.size() - 1
	elif new_index >= focusable_nodes.size():
		new_index = 0
	
	focusable_nodes[new_index].grab_focus()

## Adjust slider value with keyboard/controller
func adjust_slider(direction: int):
	var focused = get_viewport().gui_get_focus_owner()
	
	if focused == volume_slider:
		var new_value = clamp(volume_slider.value + direction, 0, 10)
		volume_slider.value = new_value

## Handle back button press
##
## Saves settings and switches back to the start scene.
func _on_back_pressed():
	save_settings()
	get_tree().change_scene_to_file("res://start_scene.tscn")
