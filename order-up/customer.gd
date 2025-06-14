extends CharacterBody2D

@export var speed = 80.0
@onready var animated_sprite = $AnimatedSprite2D
var target_position = Vector2.ZERO
var has_reached_counter = false
var order_item = "waffle_plate"  # wyyyhat the customer wants
var order_sprite = null
var is_served = false
var patience_timer = 15.0
var is_waiting = false

func _ready():
	# Start walking to serving position
	target_position = get_node("../ServingPosition").global_position
	
	# Create order display sprite
	order_sprite = Sprite2D.new()
	add_child(order_sprite)
	order_sprite.position = Vector2(0, -80)  # Higher above customer's head
	order_sprite.visible = false
	
	# Add timer label for visual countdown
	var timer_label = Label.new()
	add_child(timer_label)
	timer_label.position = Vector2(-15, -100)
	timer_label.add_theme_font_size_override("font_size", 16)

func _physics_process(delta):
	# Handle patience timer
	if is_waiting and not is_served:
		patience_timer -= delta
		
		# Update timer display
		var timer_label = get_node_or_null("Label")
		if timer_label:
			timer_label.text = str(int(patience_timer))
		
		if patience_timer <= 0:
			print("Customer got impatient and left!")
			leave_restaurant()
			return
	
	if target_position != Vector2.ZERO and not has_reached_counter and not is_served:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		
		# Simple animation based on movement
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				animated_sprite.play("walk_right")
			else:
				animated_sprite.play("walk_left")
		else:
			if direction.y > 0:
				animated_sprite.play("walk_down")
			else:
				animated_sprite.play("walk_up")
		
		# Check if reached destination
		if global_position.distance_to(target_position) < 30:
			velocity = Vector2.ZERO
			has_reached_counter = true
			animated_sprite.play("idle_down")
			show_order()
			
		move_and_slide()

func show_order():
	# Show what the customer wants - bigger and closer
	order_sprite.texture = get_node("../PlateWaffle").texture
	order_sprite.scale = Vector2(1.5, 1.5)  # Make it bigger
	order_sprite.position = Vector2(30, -10)  # Closer to customer
	order_sprite.visible = true
	is_waiting = true  # Start the patience timer
	print("Customer wants: waffle with plate! (" + str(patience_timer) + " seconds to serve)")

func serve_customer(item_type):
	if item_type == order_item:
		print("Customer satisfied! Order complete!")
		is_served = true
		is_waiting = false
		order_sprite.visible = false
		
		# Hide timer label too
		var timer_label = get_node_or_null("Label")
		if timer_label:
			timer_label.visible = false
			
		# Start walking back immediately
		leave_restaurant()
	else:
		print("That's not what I ordered!")

func leave_restaurant():
	# Walk back to spawn point
	target_position = get_node("../CustomerSpawn").global_position
	has_reached_counter = false
	is_waiting = false
	order_sprite.visible = false
	
	# Hide timer
	var timer_label = get_node_or_null("Label")
	if timer_label:
		timer_label.visible = false
	
	# Wait until customer reaches spawn, then tell lobby to spawn new customer
	await get_tree().create_timer(3.0).timeout
	
	# Tell the lobby to spawn a new customer in 5 seconds
	var lobby = get_parent()
	lobby.schedule_new_customer()
	
	# Don't delete - just reset position to spawn for reuse
	global_position = get_node("../CustomerSpawn").global_position
	has_reached_counter = false
	is_served = false
	is_waiting = false
	patience_timer = 15.0
	target_position = get_node("../ServingPosition").global_position
