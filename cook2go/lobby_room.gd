# lobby_room.gd - Complete version with wardrobe
extends Node2D

var player_holding = null
var held_item_sprite = null
var player = null

# Track all desks and their contents
var desks = []
var desk_contents = {}  # desk_id -> item_type
var desk_sprites = {}   # desk_id -> actual sprite on that desk

# Customer spawning system
var can_spawn_customer = true

# Simple interaction flags
var near_desk = -1  # Which desk player is near (-1 = none)
var near_fridge = false
var near_drawer = false
var near_door = false
var near_wardrobe = false  # NEW: wardrobe detection

# NEW: Reference to customization UI
@onready var customization_ui = $CanvasLayer/CustomizationUI

func _ready():
	player = $Player
	
	# Set up desks (EXACTLY like before - this works!)
	desks = [$Desk1, $Desk2, $Desk3]
	
	# Initialize desk contents
	desk_contents[0] = null  # Desk1 empty
	desk_contents[1] = "waffle"  # Desk2 has waffle
	desk_contents[2] = "plate"   # Desk3 has plate
	
	# Track which sprites are on which desks
	desk_sprites[0] = null  # Desk1 empty
	desk_sprites[1] = $Waffle  # Desk2 has the original waffle
	desk_sprites[2] = $Plate   # Desk3 has the original plate
	
	# Position items on their starting desks
	$Waffle.global_position = $Desk2.global_position + Vector2(0, -30)
	$Plate.global_position = $Desk3.global_position + Vector2(0, -30)
	$PlateWaffle.visible = false
	
	# Add interaction areas to all desks (EXACTLY like before - this works!)
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
	
	# Connect to manually created Area2D nodes in the editor
	connect_furniture_areas()
	connect_door_area()
	connect_wardrobe_area()  # NEW: connect wardrobe

func connect_furniture_areas():
	# Connect to existing Area2D nodes you create in the editor
	var fridge = $Fridge
	var fridge_area = fridge.get_node_or_null("Area2D")
	if fridge_area:
		fridge_area.body_entered.connect(_on_fridge_entered)
		fridge_area.body_exited.connect(_on_fridge_exited)
		print("Connected to manually created fridge Area2D")
	
	var drawer = $PlateDrawer  
	var drawer_area = drawer.get_node_or_null("Area2D")
	if drawer_area:
		drawer_area.body_entered.connect(_on_drawer_entered)
		drawer_area.body_exited.connect(_on_drawer_exited)
		print("Connected to manually created drawer Area2D")

func connect_door_area():
	# Connect to door Area2D (you'll create this in the editor)
	var door_area = get_node_or_null("DoorArea")  # Or wherever you put the door Area2D
	if door_area:
		door_area.body_entered.connect(_on_door_entered)
		door_area.body_exited.connect(_on_door_exited)
		print("Connected to door Area2D")

# NEW: Connect wardrobe area
func connect_wardrobe_area():
	# You'll need to create a Wardrobe sprite with Area2D in your scene
	var wardrobe = get_node_or_null("Wardrobe")
	if wardrobe:
		var wardrobe_area = wardrobe.get_node_or_null("Area2D")
		if wardrobe_area:
			wardrobe_area.body_entered.connect(_on_wardrobe_entered)
			wardrobe_area.body_exited.connect(_on_wardrobe_exited)
			print("Connected to wardrobe Area2D")
	else:
		print("No Wardrobe node found - you need to add one to your scene")

# NEW: Wardrobe interaction functions
func _on_wardrobe_entered(body):
	if body == player:
		near_wardrobe = true
		print("Near wardrobe - Press SPACE to customize character")

func _on_wardrobe_exited(body):
	if body == player:
		near_wardrobe = false

func _on_door_entered(body):
	if body == player:
		near_door = true
		print("Near door - Press SPACE to go outside")

func _on_door_exited(body):
	if body == player:
		near_door = false

# Simple furniture detection (SAME pattern as desks)
func _on_fridge_entered(body):
	if body == player:
		near_fridge = true
		print("FRIDGE: Entered area")

func _on_fridge_exited(body):
	if body == player:
		near_fridge = false
		print("FRIDGE: Exited area")

func _on_drawer_entered(body):
	if body == player:
		near_drawer = true
		print("DRAWER: Entered area")

func _on_drawer_exited(body):
	if body == player:
		near_drawer = false
		print("DRAWER: Exited area")

func _process(delta):
	# Make held item follow player
	if held_item_sprite != null:
		held_item_sprite.global_position = player.global_position + Vector2(30, -20)

func _on_desk_area_entered(desk_id, body):
	if body == player:
		near_desk = desk_id

func _on_desk_area_exited(desk_id, body):
	if body == player:
		near_desk = -1

func _input(event):
	if event.is_action_pressed("ui_select"):
		handle_interaction()

func handle_interaction():
	# WARDROBE INTERACTION - NEW: Check this FIRST (highest priority)
	if near_wardrobe:
		print("Opening character customization...")
		if customization_ui:
			customization_ui.open_customization(player)
		else:
			print("CustomizationUI not found!")
		return
	
	# DOOR INTERACTION - Second priority
	if near_door:
		print("Going outside...")
		fade_to_scene("res://outside_road.tscn")
		return
	
	# CUSTOMER INTERACTION - Check this THIRD (high priority)
	var customer = get_node_or_null("Customer")
	if customer and player_holding != null:
		var distance = player.global_position.distance_to(customer.global_position)
		if distance < 150:
			print("Serving customer with " + str(player_holding))
			customer.serve_customer(player_holding)
			if player_holding == customer.order_item:
				if held_item_sprite:
					held_item_sprite.queue_free()
				player_holding = null
				held_item_sprite = null
			return  # Exit early so we don't hit other interactions
	
	# FRIDGE - Check if near fridge (priority: wardrobe > door > customer > fridge > drawer > desk)
	if near_fridge and near_desk == -1:
		print("FRIDGE: Interaction triggered! Player holding:", player_holding)
		if player_holding == null:
			# Get waffle
			player_holding = "waffle"
			held_item_sprite = Sprite2D.new()
			add_child(held_item_sprite)
			held_item_sprite.texture = load("res://101_waffle.png")
			held_item_sprite.scale = Vector2(1.5, 1.5)
			held_item_sprite.z_index = 10
			print("Got waffle from fridge!")
		else:
			# Discard item
			if held_item_sprite:
				held_item_sprite.queue_free()
			player_holding = null
			held_item_sprite = null
			print("Discarded item at fridge")
		return
	
	# DRAWER - Check if near drawer (lower priority than fridge)
	if near_drawer and near_desk == -1:
		print("DRAWER: Interaction triggered! Player holding:", player_holding)
		if player_holding == null:
			# Get plate
			player_holding = "plate"
			held_item_sprite = Sprite2D.new()
			add_child(held_item_sprite)
			held_item_sprite.texture = load("res://02_dish_2.png")
			held_item_sprite.scale = Vector2(1.5, 1.5)
			held_item_sprite.z_index = 10
			print("Got plate from drawer!")
		else:
			# Discard item
			if held_item_sprite:
				held_item_sprite.queue_free()
			player_holding = null
			held_item_sprite = null
			print("Discarded item at drawer")
		return
	
	# DESK INTERACTION
	if near_desk != -1:
		var desk_item = desk_contents[near_desk]
		var desk_pos = desks[near_desk].global_position + Vector2(0, -30)
		
		if player_holding == null and desk_item != null:
			pickup_item(desk_item, near_desk)
		elif player_holding != null and desk_item == null:
			place_item(player_holding, near_desk, desk_pos)
		elif (player_holding == "waffle" and desk_item == "plate") or (player_holding == "plate" and desk_item == "waffle"):
			combine_items(near_desk, desk_pos)
		return

func pickup_item(item_type, desk_id):
	player_holding = item_type
	desk_contents[desk_id] = null
	
	var sprite_on_desk = desk_sprites[desk_id]
	if sprite_on_desk:
		held_item_sprite = sprite_on_desk
		sprite_on_desk.visible = true
		sprite_on_desk.z_index = 10
		desk_sprites[desk_id] = null
	
	print("Picked up " + item_type + " from desk " + str(desk_id))

func place_item(item_type, desk_id, position):
	desk_contents[desk_id] = item_type
	
	if held_item_sprite:
		held_item_sprite.global_position = position
		held_item_sprite.visible = true
		held_item_sprite.z_index = 4
		desk_sprites[desk_id] = held_item_sprite
	
	player_holding = null
	held_item_sprite = null
	print("Placed " + item_type + " on desk " + str(desk_id))

func combine_items(desk_id, position):
	desk_contents[desk_id] = "waffle_plate"
	
	if held_item_sprite:
		held_item_sprite.queue_free()
	
	var sprite_on_desk = desk_sprites[desk_id]
	if sprite_on_desk:
		sprite_on_desk.queue_free()
	
	var combined_sprite = Sprite2D.new()
	add_child(combined_sprite)
	combined_sprite.texture = load("res://102_waffle_dish.png")
	combined_sprite.scale = Vector2(1.5, 1.5)
	combined_sprite.global_position = position
	combined_sprite.z_index = 4
	
	desk_sprites[desk_id] = combined_sprite
	
	player_holding = null
	held_item_sprite = null
	print("Combined waffle and plate on desk " + str(desk_id))

func schedule_new_customer():
	if not can_spawn_customer:
		return
	can_spawn_customer = false
	await get_tree().create_timer(5.0).timeout
	spawn_new_customer()

func spawn_new_customer():
	var customer = get_node_or_null("Customer")
	if customer:
		customer.reset_customer()
		can_spawn_customer = true

func create_new_customer():
	can_spawn_customer = true

func fade_to_scene(scene_path):
	# Create a black overlay for fading
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 0.0  # Start transparent
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(fade_overlay)
	
	# Create fade out tween
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)  # Fade to black over 0.5 seconds
	
	# When fade out is complete, change scene and fade in
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
	
	# Note: The fade in will happen in the new scene
