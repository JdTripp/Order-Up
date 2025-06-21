# customer.gd - Fixed customer script with proper animation handling
extends CharacterBody2D

# Customer states
enum CustomerState { WALKING_TO_COUNTER, WAITING_FOR_ORDER, WALKING_AWAY, GONE }
var state = CustomerState.GONE

# Order system - alternates between waffle and hotdog
static var customer_count = 0  # Tracks how many customers have been served
var current_order = ""
var order_sprite: Sprite2D = null

# Timing
var patience_timer = 15.0  # 15 seconds to serve
var max_patience = 15.0

# Movement
var target_position: Vector2
var walk_speed = 100.0
var counter_position: Vector2
var spawn_position: Vector2
var exit_position: Vector2

# References
var lobby_room: Node2D
var animated_sprite: AnimatedSprite2D  # Reference to the animated sprite child

func _ready():
	lobby_room = get_parent()
	
	# Get reference to AnimatedSprite2D child
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		print("WARNING: No AnimatedSprite2D child found on customer!")
	
	# Use the positions you set in your scene
	var spawn_node = lobby_room.get_node_or_null("CustomerSpawn")
	var serving_node = lobby_room.get_node_or_null("ServingPosition")
	
	if spawn_node:
		spawn_position = spawn_node.global_position
		print("Using spawn position from scene: ", spawn_position)
	else:
		spawn_position = Vector2(200, 450)  # Fallback
		print("CustomerSpawn node not found, using fallback")
		
	if serving_node:
		counter_position = serving_node.global_position
		print("Using serving position from scene: ", counter_position)
	else:
		counter_position = Vector2(400, 400)  # Fallback
		print("ServingPosition node not found, using fallback")
	
	# FIXED: Exit position should be back to spawn, not to the right
	exit_position = spawn_position  # Go back to where they came from
	
	# Start in gone state
	state = CustomerState.GONE
	global_position = spawn_position
	visible = false
	
	# Auto-spawn first customer after a brief delay
	await get_tree().create_timer(1.0).timeout
	spawn_new_customer()

func spawn_new_customer():
	"""Call this to spawn a new customer"""
	if state != CustomerState.GONE:
		return  # Customer already active
	
	print("=== SPAWNING NEW CUSTOMER ===")
	
	# Determine order based on customer count (alternating)
	customer_count += 1
	if customer_count % 2 == 1:
		# Odd customers (1st, 3rd, 5th...) want waffle
		current_order = "waffle_plate"
		print("Customer #" + str(customer_count) + " wants: WAFFLE PLATE")
	else:
		# Even customers (2nd, 4th, 6th...) want hotdog
		current_order = "hotdog_plate"
		print("Customer #" + str(customer_count) + " wants: HOTDOG PLATE")
	
	# Reset state and start walking to counter
	state = CustomerState.WALKING_TO_COUNTER
	target_position = counter_position
	patience_timer = max_patience
	visible = true
	global_position = spawn_position
	
	# FIXED: Reset animation state for first customer
	if animated_sprite:
		animated_sprite.stop()  # Stop any current animation
		animated_sprite.play("idle_down")  # Start with a clean state
	
	# DON'T show order bubble yet - wait until they reach the counter

func show_order_bubble():
	"""Display what the customer wants - FIXED SIZE AND POSITION"""
	if order_sprite:
		order_sprite.queue_free()
	
	order_sprite = Sprite2D.new()
	add_child(order_sprite)
	
	# Load the appropriate order image
	if current_order == "waffle_plate":
		order_sprite.texture = load("res://102_waffle_dish.png")
	elif current_order == "hotdog_plate":
		order_sprite.texture = load("res://food assets/3_hotdog_bread_sausage_plate.png")
	
	# FIXED: Better position and size for the bubble - closer to customer
	order_sprite.position = Vector2(30, -20)  # Much closer to customer head
	order_sprite.scale = Vector2(1.0, 1.0)  # Normal size
	order_sprite.z_index = 20

func _physics_process(delta):
	# Clean state machine using your scene positions
	match state:
		CustomerState.WALKING_TO_COUNTER:
			walk_to_target(delta)
			if global_position.distance_to(target_position) < 10:
				state = CustomerState.WAITING_FOR_ORDER
				# FIXED: Use your exact idle animation name
				if animated_sprite:
					animated_sprite.play("idle_down")
				# FIXED: Show order bubble only when reaching the counter
				show_order_bubble()
				print("Customer reached counter, now waiting for " + current_order)
		
		CustomerState.WAITING_FOR_ORDER:
			# Customer should stay in idle while waiting
			patience_timer -= delta
			if patience_timer <= 0:
				print("Customer ran out of patience!")
				customer_leaves_angry()
		
		CustomerState.WALKING_AWAY:
			walk_to_target(delta)
			if global_position.distance_to(target_position) < 10:
				customer_gone()

func walk_to_target(delta):
	"""Move towards target position with proper animation"""
	var direction = (target_position - global_position).normalized()
	velocity = direction * walk_speed
	move_and_slide()
	
	# FIXED: Use your exact animation names based on movement direction
	if animated_sprite:
		var new_animation = ""
		
		if abs(direction.x) > abs(direction.y):
			# Moving more horizontally
			if direction.x > 0:
				new_animation = "walk_right"
			else:
				new_animation = "walk_left"
		else:
			# Moving more vertically
			if direction.y > 0:
				new_animation = "walk_down"
			else:
				new_animation = "walk_up"
		
		# Only change animation if it's different from current one
		if animated_sprite.get_animation() != new_animation:
			animated_sprite.play(new_animation)

func serve_customer(item_name: String) -> bool:
	"""
	Try to serve the customer with given item.
	Returns true if customer accepts, false if they reject it.
	"""
	if state != CustomerState.WAITING_FOR_ORDER:
		print("Customer is not ready to be served!")
		return false
	
	print("Customer checking item: " + item_name + " (wants: " + current_order + ")")
	
	if item_name == current_order:
		# Correct order!
		print("Customer is happy! Correct order received.")
		customer_leaves_happy()
		return true
	else:
		# Wrong order - customer rejects it
		print("Customer says: 'This is not what I ordered! I want " + current_order + "'")
		show_rejection_indicator()
		return false

func show_rejection_indicator():
	"""Show a visual indicator that customer rejected the item"""
	if order_sprite:
		var original_color = order_sprite.modulate
		order_sprite.modulate = Color.RED
		
		# Return to normal color after a brief moment
		await get_tree().create_timer(0.5).timeout
		if order_sprite:  # Check if still exists
			order_sprite.modulate = original_color

func customer_leaves_happy():
	"""Customer got correct order and leaves happily"""
	print("Customer leaving happy!")
	state = CustomerState.WALKING_AWAY
	target_position = exit_position
	
	# Hide order bubble
	if order_sprite:
		order_sprite.queue_free()
		order_sprite = null
	
	# Schedule next customer
	if lobby_room:
		lobby_room.schedule_new_customer()

func customer_leaves_angry():
	"""Customer ran out of patience and leaves angry"""
	print("Customer leaving angry - no tip!")
	state = CustomerState.WALKING_AWAY
	target_position = exit_position
	
	# Hide order bubble
	if order_sprite:
		order_sprite.queue_free()
		order_sprite = null
	
	# Maybe change customer color to red briefly
	modulate = Color.RED
	await get_tree().create_timer(1.0).timeout
	modulate = Color.WHITE
	
	# Schedule next customer
	if lobby_room:
		lobby_room.schedule_new_customer()

func customer_gone():
	"""Customer has left the scene"""
	state = CustomerState.GONE
	visible = false
	modulate = Color.WHITE  # Reset color
	global_position = spawn_position  # Reset to spawn position
	print("Customer has left the building")

func reset_customer():
	"""Reset customer for next order - called by lobby room"""
	spawn_new_customer()

# Debug function
func get_debug_info() -> String:
	return "State: " + str(state) + ", Order: " + current_order + ", Patience: " + str(patience_timer)
