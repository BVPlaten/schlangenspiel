# manager_input.gd
extends Node

## Universal input manager for keyboard, gamepad, and touch.
##
## This class consolidates all player input logic into a single manager.
## It emits signals for game actions like direction changes, pause, exit,
## and restart, regardless of the input source (keyboard, gamepad, or touch).
## This decouples the game logic from the specific input hardware.

# Signals for game actions
signal direction_changed(new_direction: Vector2)
signal pause_pressed
signal exit_pressed
signal restart_pressed

# Stores the last direction sent to prevent duplicate signals, mainly for analog sticks.
var last_direction: Vector2 = Vector2.ZERO
# Stores the starting position of a touch gesture to calculate swipe direction.
var touch_start_position: Vector2 = Vector2.ZERO
# Threshold for analog stick input to be considered intentional
const JOYSTICK_DEADZONE: float = 0.5
# Minimum swipe distance to be registered
const SWIPE_THRESHOLD: float = 50.0


func _input(event: InputEvent) -> void:
	# --- Keyboard Input ---
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_RIGHT:
				direction_changed.emit(Vector2.RIGHT)
			KEY_LEFT:
				direction_changed.emit(Vector2.LEFT)
			KEY_UP:
				direction_changed.emit(Vector2.UP)
			KEY_DOWN:
				direction_changed.emit(Vector2.DOWN)
			KEY_P:
				pause_pressed.emit()
			KEY_Q:
				exit_pressed.emit()
			KEY_SPACE:
				restart_pressed.emit()

	# --- Gamepad Button Input ---
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_START:
				pause_pressed.emit()
			JOY_BUTTON_BACK:
				exit_pressed.emit()
			JOY_BUTTON_A:
				restart_pressed.emit()
			# D-Pad events are handled here as discrete button presses
			JOY_BUTTON_DPAD_UP:
				if last_direction != Vector2.UP:
					direction_changed.emit(Vector2.UP)
					last_direction = Vector2.UP
			JOY_BUTTON_DPAD_DOWN:
				if last_direction != Vector2.DOWN:
					direction_changed.emit(Vector2.DOWN)
					last_direction = Vector2.DOWN
			JOY_BUTTON_DPAD_LEFT:
				if last_direction != Vector2.LEFT:
					direction_changed.emit(Vector2.LEFT)
					last_direction = Vector2.LEFT
			JOY_BUTTON_DPAD_RIGHT:
				if last_direction != Vector2.RIGHT:
					direction_changed.emit(Vector2.RIGHT)
					last_direction = Vector2.RIGHT
	
	# --- Touchscreen Input (for mobile) ---
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Store start position when screen is first touched
			touch_start_position = event.position
		else:
			# Process swipe when touch is released
			var touch_end_position: Vector2 = event.position
			var swipe_vector: Vector2 = touch_end_position - touch_start_position
			
			# Only register as a swipe if it's long enough
			if swipe_vector.length() > SWIPE_THRESHOLD:
				var new_direction := Vector2.ZERO
				# Determine dominant direction (horizontal vs. vertical)
				if abs(swipe_vector.x) > abs(swipe_vector.y):
					new_direction = Vector2.RIGHT if swipe_vector.x > 0 else Vector2.LEFT
				else:
					new_direction = Vector2.DOWN if swipe_vector.y > 0 else Vector2.UP
				
				if new_direction != Vector2.ZERO:
					direction_changed.emit(new_direction)
					get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# --- Gamepad Analog Stick Input ---
	# Polling analog stick input in _process is more reliable for smooth controls.
	var axis_x: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var axis_y: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	
	var new_direction := Vector2.ZERO
	
	if abs(axis_x) > JOYSTICK_DEADZONE or abs(axis_y) > JOYSTICK_DEADZONE:
		if abs(axis_x) > abs(axis_y):
			new_direction = Vector2.RIGHT if axis_x > 0 else Vector2.LEFT
		else:
			new_direction = Vector2.DOWN if axis_y > 0 else Vector2.UP
	
	if new_direction != Vector2.ZERO and new_direction != last_direction:
		# Emit the signal and update the last direction
		direction_changed.emit(new_direction)
		last_direction = new_direction
	elif new_direction == Vector2.ZERO and last_direction != Vector2.ZERO:
		# Reset last_direction when stick is centered to allow immediate opposite direction input
		last_direction = Vector2.ZERO