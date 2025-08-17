## Options scene controller for the Snake game.
##
## This class manages an options menu with volume controls for music and sound effects,
## plus a back button to return to the start screen. It communicates with the
## GlobalSettings autoload singleton to apply and persist volume changes.
extends Control

# UI Element References
var music_volume_slider: HSlider
var music_volume_label: Label
var sfx_volume_slider: HSlider
var sfx_volume_label: Label
var back_button: Button

# Reference to the GlobalSettings singleton
var global_settings: Node

## Initialize the options scene when it enters the scene tree.
func _ready() -> void:
	# Access the singleton via its absolute path in the scene tree root.
	# This is a more robust way if the global name is causing issues.
	global_settings = get_node_or_null("/root/GlobalSettings")
	if not global_settings:
		push_error("GlobalSettings node not found at /root/GlobalSettings. Please check the Autoload configuration in Project Settings.")
		return

	create_ui()

	# Set initial slider values and labels from the singleton
	music_volume_slider.value = global_settings.music_volume
	music_volume_label.text = "Music Volume: %d" % global_settings.music_volume
	sfx_volume_slider.value = global_settings.sfx_volume
	sfx_volume_label.text = "SFX Volume: %d" % global_settings.sfx_volume

	# Connect signals
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

	# Set initial focus for UI navigation
	music_volume_slider.grab_focus()

## Create the complete UI with volume controls and back button programmatically.
func create_ui() -> void:
	var main_container = VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	main_container.add_theme_constant_override("separation", 30)
	add_child(main_container)

	var music_container = VBoxContainer.new()
	music_volume_label = Label.new()
	music_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	music_volume_slider = HSlider.new()
	music_volume_slider.min_value = 0
	music_volume_slider.max_value = 10
	music_volume_slider.step = 1
	music_volume_slider.custom_minimum_size = Vector2(300, 30)
	music_container.add_child(music_volume_label)
	music_container.add_child(music_volume_slider)
	main_container.add_child(music_container)

	var sfx_container = VBoxContainer.new()
	sfx_volume_label = Label.new()
	sfx_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_volume_slider = HSlider.new()
	sfx_volume_slider.min_value = 0
	sfx_volume_slider.max_value = 10
	sfx_volume_slider.step = 1
	sfx_volume_slider.custom_minimum_size = Vector2(300, 30)
	sfx_container.add_child(sfx_volume_label)
	sfx_container.add_child(sfx_volume_slider)
	main_container.add_child(sfx_container)

	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(200, 50)
	main_container.add_child(back_button)

## Handles changes from the music volume slider.
func _on_music_volume_changed(value: float) -> void:
	var volume: int = int(value)
	music_volume_label.text = "Music Volume: %d" % volume
	global_settings.set_music_volume(volume)

## Handles changes from the SFX volume slider.
func _on_sfx_volume_changed(value: float) -> void:
	var volume: int = int(value)
	sfx_volume_label.text = "SFX Volume: %d" % volume
	global_settings.set_sfx_volume(volume)

## Handles the back button press.
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://start_scene.tscn")

## Handle keyboard and controller input for UI navigation.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()