extends Node

signal direction_changed(new_direction)
signal pause_pressed
signal exit_pressed
signal restart_pressed

var last_direction = Vector2.ZERO

func _input(event):
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_START:
				pause_pressed.emit()
			JOY_BUTTON_BACK:
				exit_pressed.emit()
			JOY_BUTTON_A:
				restart_pressed.emit()
			JOY_BUTTON_DPAD_LEFT:
				if Vector2.LEFT != last_direction:
					direction_changed.emit(Vector2.LEFT)
					last_direction = Vector2.LEFT
			JOY_BUTTON_DPAD_RIGHT:
				if Vector2.RIGHT != last_direction:
					direction_changed.emit(Vector2.RIGHT)
					last_direction = Vector2.RIGHT
			JOY_BUTTON_DPAD_UP:
				if Vector2.UP != last_direction:
					direction_changed.emit(Vector2.UP)
					last_direction = Vector2.UP
			JOY_BUTTON_DPAD_DOWN:
				if Vector2.DOWN != last_direction:
					direction_changed.emit(Vector2.DOWN)
					last_direction = Vector2.DOWN
	
	elif event is InputEventJoypadMotion:
		var new_direction = Vector2.ZERO
		
		# Left stick
		var stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# D-Pad
		var dpad_left = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)
		var dpad_right = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)
		var dpad_up = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
		var dpad_down = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)
		
		# Determine direction from stick or D-Pad
		if abs(stick_x) > 0.5 or abs(stick_y) > 0.5:
			if abs(stick_x) > abs(stick_y):
				new_direction = Vector2.RIGHT if stick_x > 0 else Vector2.LEFT
			else:
				new_direction = Vector2.DOWN if stick_y > 0 else Vector2.UP
		elif dpad_right:
			new_direction = Vector2.RIGHT
		elif dpad_left:
			new_direction = Vector2.LEFT
		elif dpad_up:
			new_direction = Vector2.UP
		elif dpad_down:
			new_direction = Vector2.DOWN
		
		# Only emit if direction changed
		if new_direction != Vector2.ZERO and new_direction != last_direction:
			direction_changed.emit(new_direction)
			last_direction = new_direction
