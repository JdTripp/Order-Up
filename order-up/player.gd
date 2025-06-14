extends CharacterBody2D

@export var speed = 300.0
@onready var animated_sprite = $AnimatedSprite2D

var last_direction = "down"

func _physics_process(delta):
	var direction = Vector2.ZERO
	
	# Get input direction
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		last_direction = "right"
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
		last_direction = "left"
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
		last_direction = "down"
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
		last_direction = "up"
	
	# Move and animate
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		velocity = direction * speed
		animated_sprite.play("walk_" + last_direction)
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle_" + last_direction)
	
	move_and_slide()
