extends CharacterBody2D

@export var speed = 80.0
@onready var animated_sprite = $AnimatedSprite2D
var target_position = Vector2.ZERO
var has_reached_counter = false
var order_item = "waffle_plate"  # what the customer wants
var order_sprite = null
var is_served = false
var patience_timer = 15.0  # Always 15 seconds
var is_waiting = false
var is_leaving = false

func _ready():
	# Start walking to serving position
	target_position = get_node("../ServingPosition").global_position
	print("Customer spawned at: ", global_position)
	print("Walking to serving position: ", target_position)
	
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
	if is_waiting and not is_served and not is_leaving:
		patience_timer -= delta
		
		# Update timer display
		var timer_label = get_node_or_null("Label")
		if timer_label:
			timer_label.text = str(int(patience_timer))
		
		if patience_timer <= 0:
			print("Customer got impatient and left!")
			leave_restaurant()
			return
	
	# Handle movement - only move if we have a target and haven't reached it yet
	if target_position != Vector2.ZERO and global_position.distance_to(target_position) > 30:
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
		
		move_and_slide()
	else:
		# Reached destination or close enough
		velocity = Vector2.ZERO
		
		if not has_reached_counter and not is_leaving:
			# Just reached serving position
			has_reached_counter = true
			animated_sprite.play("idle_down")  # Face down towards counter
			show_order()
			target_position = Vector2.ZERO  # Stop moving
		elif is_leaving and global_position.distance_to(target_position) <= 30:
			# Reached spawn point - disappear
			disappear_and_spawn_new()

func show_order():
	# Show what the customer wants - bigger and closer
	var plate_waffle_node = get_node_or_null("../PlateWaffle")
	if plate_waffle_node and plate_waffle_node.texture:
		order_sprite.texture = plate_waffle_node.texture
	else:
		# Fallback - try to load the texture directly
		order_sprite.texture = load("res://102_waffle_dish.png")
	
	order_sprite.scale = Vector2(1.5, 1.5)  # Make it bigger
	order_sprite.position = Vector2(30, -10)  # Closer to customer
	order_sprite.visible = true
	is_waiting = true  # Start the patience timer
	print("Customer wants: waffle with plate! (" + str(patience_timer) + " seconds to serve)")

func serve_customer(item_type):
	if item_type == order_item and is_waiting:  # Only serve if customer is actually waiting
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
	elif is_waiting:
		print("That's not what I ordered!")
	else:
		print("Customer is not ready to be served!")

func leave_restaurant():
	# Set up leaving state
	is_leaving = true
	is_waiting = false
	order_sprite.visible = false
	
	# Hide timer
	var timer_label = get_node_or_null("Label")
	if timer_label:
		timer_label.visible = false
	
	# Walk back to spawn point
	target_position = get_node("../CustomerSpawn").global_position
	has_reached_counter = false

func disappear_and_spawn_new():
	print("Customer reached spawn point - disappearing")
	# Hide the customer completely
	visible = false
	set_physics_process(false)  # Stop all processing
	
	# Tell the lobby to spawn a new customer in exactly 5 seconds
	var lobby = get_parent()
	if lobby:
		lobby.schedule_new_customer()
	
	# DON'T reset here - let the lobby handle it after the delay

func reset_customer():
	print("Resetting customer for reuse")
	# Reset all states to initial values
	has_reached_counter = false
	is_served = false
	is_waiting = false
	is_leaving = false
	patience_timer = 15.0  # Always reset to exactly 15 seconds
	
	# Make customer visible and active again
	visible = true
	set_physics_process(true)
	
	# Reset position to spawn and set target
	global_position = get_node("../CustomerSpawn").global_position
	target_position = get_node("../ServingPosition").global_position
	
	# Hide order elements
	if order_sprite:
		order_sprite.visible = false
	var timer_label = get_node_or_null("Label")
	if timer_label:
		timer_label.visible = false
		timer_label.text = "15"  # Reset timer display
	
	print("Customer reset complete - walking to serving position")
