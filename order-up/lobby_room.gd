extends Node2D

var player_holding = null
var held_item_sprite = null
var player = null

# Track all desks and their contents
var desks = []
var desk_contents = {}  # desk_id -> item_type

# Customer spawning system
var can_spawn_customer = true

func _ready():
	player = $Player
	
	# Set up desks
	desks = [$Desk1, $Desk2, $Desk3]
	
	# Initialize desk contents
	desk_contents[0] = null  # Desk1 empty
	desk_contents[1] = "waffle"  # Desk2 has waffle
	desk_contents[2] = "plate"   # Desk3 has plate
	
	# Position items on their starting desks
	$Waffle.global_position = $Desk2.global_position + Vector2(0, -30)
	$Plate.global_position = $Desk3.global_position + Vector2(0, -30)
	$PlateWaffle.visible = false
	
	# Add interaction areas to all desks
	for i in range(desks.size()):
		var desk = desks[i]
		var area = Area2D.new()
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(80, 80)
		collision.shape = shape
		area.add_child(collision)
		desk.add_child(area)
		
		# Connect signals with proper syntax
		area.body_entered.connect(func(body): _on_desk_area_entered(i, body))
		area.body_exited.connect(func(body): _on_desk_area_exited(i, body))

var near_desk = -1  # Which desk player is near (-1 = none)

func _process(delta):
	# Make held item follow player
	if held_item_sprite != null:
		held_item_sprite.global_position = player.global_position + Vector2(30, -20)

func _on_desk_area_entered(desk_id, body):
	if body == player:
		near_desk = desk_id
		update_interaction_prompt()

func _on_desk_area_exited(desk_id, body):
	if body == player:
		near_desk = -1

func update_interaction_prompt():
	if near_desk == -1:
		return
		
	var desk_item = desk_contents[near_desk]
	
	if player_holding == null and desk_item != null:
		print("Press SPACE to pickup " + str(desk_item))
	elif player_holding != null and desk_item == null:
		print("Press SPACE to place " + str(player_holding))
	elif player_holding == "waffle" and desk_item == "plate":
		print("Press SPACE to combine waffle with plate")
	elif player_holding == "plate" and desk_item == "waffle":
		print("Press SPACE to combine plate with waffle")

func _input(event):
	if event.is_action_pressed("ui_select"):
		handle_interaction()

func handle_interaction():
	if near_desk == -1:
		# Check if near customer for serving
		check_customer_serving()
		return
		
	var desk_item = desk_contents[near_desk]
	var desk_pos = desks[near_desk].global_position + Vector2(0, -30)
	
	if player_holding == null and desk_item != null:
		# Pick up item from desk
		pickup_item(desk_item, near_desk)
		
	elif player_holding != null and desk_item == null:
		# Place item on empty desk
		place_item(player_holding, near_desk, desk_pos)
		
	elif (player_holding == "waffle" and desk_item == "plate") or (player_holding == "plate" and desk_item == "waffle"):
		# Combine items
		combine_items(near_desk, desk_pos)

func check_customer_serving():
	var customer = get_node_or_null("Customer")
	if customer and player_holding != null:
		var distance = player.global_position.distance_to(customer.global_position)
		if distance < 60:  # Close enough to serve
			customer.serve_customer(player_holding)
			if player_holding == customer.order_item:
				# Successfully served - remove item from player AND hide it
				if held_item_sprite:
					held_item_sprite.visible = false
				player_holding = null
				held_item_sprite = null

func pickup_item(item_type, desk_id):
	player_holding = item_type
	desk_contents[desk_id] = null
	
	if item_type == "waffle":
		held_item_sprite = $Waffle
	elif item_type == "plate":
		held_item_sprite = $Plate
	elif item_type == "waffle_plate":
		held_item_sprite = $PlateWaffle
	
	print("Picked up " + item_type)

func place_item(item_type, desk_id, position):
	player_holding = null
	held_item_sprite = null
	desk_contents[desk_id] = item_type
	
	if item_type == "waffle":
		$Waffle.global_position = position
	elif item_type == "plate":
		$Plate.global_position = position
	elif item_type == "waffle_plate":
		$PlateWaffle.global_position = position
	
	print("Placed " + item_type)

func combine_items(desk_id, position):
	player_holding = null
	held_item_sprite = null
	desk_contents[desk_id] = "waffle_plate"
	
	# Hide individual items
	$Waffle.visible = false
	$Plate.visible = false
	
	# Show combined item
	$PlateWaffle.visible = true
	$PlateWaffle.global_position = position
	
	print("Combined waffle and plate!")

func schedule_new_customer():
	if can_spawn_customer:
		can_spawn_customer = false
		await get_tree().create_timer(5.0).timeout
		spawn_new_customer()

func spawn_new_customer():
	# Create new customer from scratch
	var new_customer = CharacterBody2D.new()
	new_customer.name = "Customer"
	add_child(new_customer)
	
	# Add AnimatedSprite2D
	var animated_sprite = AnimatedSprite2D.new()
	new_customer.add_child(animated_sprite)
	animated_sprite.name = "AnimatedSprite2D"
	
	# Copy the sprite frames from the original customer setup
	# You'll need to set up the blue character animations here
	animated_sprite.sprite_frames = load("res://customer_spriteframes.tres") # We'll need to save this
	
	# Add CollisionShape2D
	var collision = CollisionShape2D.new()
	new_customer.add_child(collision)
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48)
	collision.shape = shape
	
	# Add the customer script
	var customer_script = load("res://customer.gd")
	new_customer.set_script(customer_script)
	
	# Position at spawn
	new_customer.global_position = $CustomerSpawn.global_position
	
	can_spawn_customer = true
	print("New customer spawned!")
