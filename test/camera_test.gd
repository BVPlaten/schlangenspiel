# camera_test.gd - Einfacher Spieler mit Camera2D
extends CharacterBody2D

@export var speed: float = 300.0
@export var zoom_length: float = 10.0

var camera: Camera2D

func _ready():
	# Camera2D als Child-Node hinzufügen
	camera = Camera2D.new()
	add_child(camera)
	
	# Camera2D Einstellungen
	camera.enabled = true
	
	# Smoothing aktivieren für weiche Kamerabewegung
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Limits setzen (optional)
	camera.limit_left = -1000
	camera.limit_right = 1000
	camera.limit_top = -1000
	camera.limit_bottom = 1000

	# Zoom-Animation erstellen
	var tween = get_tree().create_tween().set_loops()
	tween.tween_property(camera, "zoom", Vector2(2, 2), zoom_length).from(Vector2(0.5, 0.5))
	tween.tween_property(camera, "zoom", Vector2(0.5, 0.5), zoom_length)


func _physics_process(delta):
	# Einfache Bewegungssteuerung
	var direction = Vector2()
	
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	
	# Bewegung normalisieren und anwenden
	velocity = direction.normalized() * speed
	move_and_slide()
