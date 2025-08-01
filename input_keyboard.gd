extends Node

signal direction_changed(new_direction)
signal pause_pressed
signal exit_pressed
signal restart_pressed

func _input(event):
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