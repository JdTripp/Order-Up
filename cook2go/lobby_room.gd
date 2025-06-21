# lobby_room.gd - FIXED VERSION - Single item holding system
extends Node2D

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
var near_wardrobe = false

# NEW: Hot Dog equipment detection
var near_hd_fridge = false
var near_stove = false  
var near_bread_station = false

# UNIFIED ITEM SYSTEM - Player can only hold ONE item at a time
enum ItemType { NONE, WAFFLE, PLATE, WAFFLE_PLATE, RAW_SAUSAGE, GRILLED_SAUSAGE, BREAD, BREAD_SAUSAGE, PLATED_HOTDOG }
var player_item = ItemType.NONE
var held_item_sprite: Sprite2D = null

# Stove cooking system (automatic 5-second cooking)
var stove_item = ItemType.NONE
var stove_sprite: Sprite2D = null
var stove_timer = 0.0
var stove_cook_time = 5.0
var is_stove_cooking = false

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
	connect_wardrobe_area()
	connect_hotdog_areas()

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
	var door_area = get_node_or_null("DoorArea")
	if door_area:
		door_area.body_entered.connect(_on_door_entered)
		door_area.body_exited.connect(_on_door_exited)
		print("Connected to door Area2D")

func connect_wardrobe_area():
	var wardrobe = get_node_or_null("Wardrobe")
	if wardrobe:
		var wardrobe_area = wardrobe.get_node_or_null("Area2D")
		if wardrobe_area:
			wardrobe_area.body_entered.connect(_on_wardrobe_entered)
			wardrobe_area.body_exited.connect(_on_wardrobe_exited)
			print("Connected to wardrobe Area2D")

func connect_hotdog_areas():
	print("Connecting hot dog equipment areas...")
	
	# Connect HD Fridge
	var hd_fridge = get_node_or_null("HDFridge")
	if hd_fridge:
		var hd_fridge_area = hd_fridge.get_node_or_null("Area2D")
		if hd_fridge_area:
			hd_fridge_area.body_entered.connect(_on_hd_fridge_entered)
			hd_fridge_area.body_exited.connect(_on_hd_fridge_exited)
			print("Connected HD Fridge Area2D")
	
	# Connect Stove
	var stove = get_node_or_null("Stove")
	if stove:
		var stove_area = stove.get_node_or_null("Area2D")
		if stove_area:
			stove_area.body_entered.connect(_on_stove_entered)
			stove_area.body_exited.connect(_on_stove_exited)
			print("Connected Stove Area2D")
	
	# Connect Bread Station
	var bread = get_node_or_null("Bread")
	if bread:
		var bread_area = bread.get_node_or_null("Area2D")
		if bread_area:
			bread_area.body_entered.connect(_on_bread_entered)
			bread_area.body_exited.connect(_on_bread_exited)
			print("Connected Bread Area2D")

# Area entry/exit functions
func _on_wardrobe_entered(body):
	if body == player:
		near_wardrobe = true
		print("Near wardrobe - Press SPACE to customize character")

func _on_wardrobe_exited(body):
	if body == player:
		near_wardrobe = false

func _on_hd_fridge_entered(body):
	if body == player:
		near_hd_fridge = true
		print("Near HD Fridge - Press SPACE to get raw sausage")

func _on_hd_fridge_exited(body):
	if body == player:
		near_hd_fridge = false

func _on_stove_entered(body):
	if body == player:
		near_stove = true
		if player_item == ItemType.RAW_SAUSAGE:
			print("Near Stove - Press SPACE to cook sausage")
		elif stove_item == ItemType.RAW_SAUSAGE:
			print("Near Stove - Sausage is cooking...")
		elif stove_item == ItemType.GRILLED_SAUSAGE:
			print("Near Stove - Press SPACE to pick up grilled sausage")
		else:
			print("Near Stove - Need raw sausage to cook")

func _on_stove_exited(body):
	if body == player:
		near_stove = false

func _on_bread_entered(body):
	if body == player:
		near_bread_station = true
		print("Near Bread Station - Press SPACE to get bread")

func _on_bread_exited(body):
	if body == player:
		near_bread_station = false

func _on_door_entered(body):
	if body == player:
		near_door = true
		print("Near door - Press SPACE to go outside")

func _on_door_exited(body):
	if body == player:
		near_door = false

func _on_fridge_entered(body):
	if body == player:
		near_fridge = true
		print("FRIDGE: Entered area")

func _on_fridge_exited(body):
	if body == player:
		near_fridge = false

func _on_drawer_entered(body):
	if body == player:
		near_drawer = true
		print("DRAWER: Entered area")

func _on_drawer_exited(body):
	if body == player:
		near_drawer = false

func _process(delta):
	# Make held item follow player
	if held_item_sprite != null:
		held_item_sprite.global_position = player.global_position + Vector2(30, -20)
	
	# Handle stove cooking timer
	if is_stove_cooking:
		stove_timer += delta
		
		# Print cooking progress every second
		var seconds_left = stove_cook_time - stove_timer
		if int(seconds_left) != int(seconds_left + delta) and seconds_left > 0:
			print("Cooking... ", int(seconds_left + 1), " seconds left")
		
		# When cooking is done
		if stove_timer >= stove_cook_time:
			finish_cooking()

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
	print("=== HANDLE INTERACTION CALLED ===")
	print("Current item:", ItemType.keys()[player_item])
	
	# HOT DOG INTERACTIONS - Check these FIRST (highest priority)
	if near_hd_fridge:
		interact_with_hd_fridge()
		return
	
	if near_stove:
		interact_with_stove()
		return
	
	if near_bread_station:
		interact_with_bread_station()
		return
	
	# WARDROBE INTERACTION
	if near_wardrobe:
		print("Opening character customization...")
		if customization_ui:
			customization_ui.open_customization(player)
		return
	
	# DOOR INTERACTION
	if near_door:
		print("Going outside...")
		fade_to_scene("res://outside_road.tscn")
		return
	
	# CUSTOMER INTERACTION
	var customer = get_node_or_null("Customer")
	if customer and player_item != ItemType.NONE:
		var distance = player.global_position.distance_to(customer.global_position)
		if distance < 150:
			var item_name = get_item_name(player_item)
			print("Serving customer with " + item_name)
			customer.serve_customer(item_name)
			# Note: You'll need to update customer script to handle new item names
			return
	
	# FRIDGE - Get waffles
	if near_fridge and near_desk == -1:
		print("FRIDGE: Interaction triggered!")
		if player_item == ItemType.NONE:
			give_item_to_player(ItemType.WAFFLE)
			print("Got waffle from fridge!")
		else:
			print("Already holding something!")
		return
	
	# DRAWER - Get plates
	if near_drawer and near_desk == -1:
		print("DRAWER: Interaction triggered!")
		if player_item == ItemType.NONE:
			give_item_to_player(ItemType.PLATE)
			print("Got plate from drawer!")
		else:
			print("Already holding something!")
		return
	
	# DESK INTERACTION
	if near_desk != -1:
		interact_with_desk()
		return

# NEW: Unified item giving function
func give_item_to_player(item_type: ItemType):
	player_item = item_type
	
	# Create sprite for the item
	held_item_sprite = Sprite2D.new()
	add_child(held_item_sprite)
	held_item_sprite.texture = get_item_texture(item_type)
	held_item_sprite.scale = Vector2(1.5, 1.5)
	held_item_sprite.z_index = 10

# NEW: Get texture for any item type
func get_item_texture(item_type: ItemType) -> Texture2D:
	match item_type:
		ItemType.WAFFLE:
			return load("res://101_waffle.png")
		ItemType.PLATE:
			return load("res://02_dish_2.png")
		ItemType.WAFFLE_PLATE:
			return load("res://102_waffle_dish.png")
		ItemType.RAW_SAUSAGE:
			return load("res://food assets/0_hotdog_rawsausage.png")
		ItemType.GRILLED_SAUSAGE:
			return load("res://food assets/1_hotdog_sausage.png")
		ItemType.BREAD:
			return load("res://food assets/4_hotdog_bread.png")
		ItemType.BREAD_SAUSAGE:
			return load("res://food assets/2_hotdog_bread_sausage.png")
		ItemType.PLATED_HOTDOG:
			return load("res://food assets/3_hotdog_bread_sausage_plate.png")
		_:
			return null

# NEW: Get item name for customer service
func get_item_name(item_type: ItemType) -> String:
	match item_type:
		ItemType.WAFFLE:
			return "waffle"
		ItemType.PLATE:
			return "plate"
		ItemType.WAFFLE_PLATE:
			return "waffle_plate"
		ItemType.RAW_SAUSAGE:
			return "raw_sausage"
		ItemType.GRILLED_SAUSAGE:
			return "grilled_sausage"
		ItemType.BREAD:
			return "bread"
		ItemType.BREAD_SAUSAGE:
			return "bread_sausage"
		ItemType.PLATED_HOTDOG:
			return "hotdog_plate"
		_:
			return "none"

# HD Fridge interaction
func interact_with_hd_fridge():
	print("HD FRIDGE: Interaction triggered!")
	
	if player_item == ItemType.NONE:
		give_item_to_player(ItemType.RAW_SAUSAGE)
		print("Got raw sausage from HD fridge!")
	else:
		print("Already holding something! Can't get raw sausage.")

# Stove interaction - FIXED: Automatic cooking system
func interact_with_stove():
	print("STOVE: Interaction triggered!")
	
	if player_item == ItemType.RAW_SAUSAGE and stove_item == ItemType.NONE:
		# Place raw sausage on stove and start cooking
		place_item_on_stove(ItemType.RAW_SAUSAGE)
		clear_player_item()
		start_cooking()
		print("Placed raw sausage on stove. Cooking will take 5 seconds...")
		
	elif stove_item == ItemType.GRILLED_SAUSAGE and player_item == ItemType.NONE:
		# Pick up grilled sausage from stove
		give_item_to_player(ItemType.GRILLED_SAUSAGE)
		clear_stove()
		print("Picked up grilled sausage from stove!")
		
	elif is_stove_cooking:
		print("Sausage is still cooking! Wait a moment...")
		
	else:
		print("Need raw sausage to use stove, or already holding something!")

# Bread station interaction
func interact_with_bread_station():
	print("BREAD: Interaction triggered!")
	
	if player_item == ItemType.NONE:
		give_item_to_player(ItemType.BREAD)
		print("Got bread!")
		
	elif player_item == ItemType.GRILLED_SAUSAGE:
		# Combine grilled sausage + bread
		player_item = ItemType.BREAD_SAUSAGE
		if held_item_sprite:
			held_item_sprite.texture = get_item_texture(ItemType.BREAD_SAUSAGE)
		print("Combined grilled sausage and bread!")
		
	else:
		print("Already holding something or incompatible item!")

# NEW: Stove cooking functions
func place_item_on_stove(item_type: ItemType):
	stove_item = item_type
	
	# Create sprite on stove
	stove_sprite = Sprite2D.new()
	add_child(stove_sprite)
	stove_sprite.texture = get_item_texture(item_type)
	stove_sprite.scale = Vector2(1.5, 1.5)
	stove_sprite.global_position = $Stove.global_position + Vector2(0, -20)
	stove_sprite.z_index = 5

func start_cooking():
	is_stove_cooking = true
	stove_timer = 0.0
	print("=== COOKING STARTED ===")

func finish_cooking():
	print("=== COOKING FINISHED! ===")
	is_stove_cooking = false
	
	# Convert raw sausage to grilled sausage
	stove_item = ItemType.GRILLED_SAUSAGE
	if stove_sprite:
		stove_sprite.texture = get_item_texture(ItemType.GRILLED_SAUSAGE)
	
	print("Sausage is ready! Press SPACE near stove to pick it up.")

func clear_player_item():
	player_item = ItemType.NONE
	if held_item_sprite:
		held_item_sprite.queue_free()
		held_item_sprite = null

func clear_stove():
	stove_item = ItemType.NONE
	if stove_sprite:
		stove_sprite.queue_free()
		stove_sprite = null

# UPDATED: Desk interaction to work with new item system
func interact_with_desk():
	var desk_item = desk_contents[near_desk]
	var desk_pos = desks[near_desk].global_position + Vector2(0, -30)
	
	if player_item == ItemType.NONE and desk_item != null:
		# Pick up item from desk
		pickup_item_from_desk(desk_item, near_desk)
		
	elif player_item != ItemType.NONE and desk_item == null:
		# Place item on desk
		place_item_on_desk(player_item, near_desk, desk_pos)
		
	elif can_combine_items(player_item, desk_item):
		# Combine items
		combine_items_on_desk(near_desk, desk_pos)

func can_combine_items(held_item: ItemType, desk_item) -> bool:
	# Check if items can be combined
	if held_item == ItemType.WAFFLE and desk_item == "plate":
		return true
	elif held_item == ItemType.PLATE and desk_item == "waffle":
		return true
	elif held_item == ItemType.BREAD_SAUSAGE and desk_item == "plate":
		return true
	return false

func pickup_item_from_desk(item_name: String, desk_id: int):
	# Convert old string names to new ItemType
	var item_type = ItemType.NONE
	match item_name:
		"waffle":
			item_type = ItemType.WAFFLE
		"plate":
			item_type = ItemType.PLATE
		"waffle_plate":
			item_type = ItemType.WAFFLE_PLATE
	
	give_item_to_player(item_type)
	
	# Clear desk
	desk_contents[desk_id] = null
	var sprite_on_desk = desk_sprites[desk_id]
	if sprite_on_desk:
		sprite_on_desk.queue_free()
		desk_sprites[desk_id] = null
	
	print("Picked up " + item_name + " from desk " + str(desk_id))

func place_item_on_desk(item_type: ItemType, desk_id: int, position: Vector2):
	var item_name = get_item_name(item_type)
	desk_contents[desk_id] = item_name
	
	# Create sprite on desk
	var desk_sprite = Sprite2D.new()
	add_child(desk_sprite)
	desk_sprite.texture = get_item_texture(item_type)
	desk_sprite.scale = Vector2(1.5, 1.5)
	desk_sprite.global_position = position
	desk_sprite.z_index = 4
	desk_sprites[desk_id] = desk_sprite
	
	clear_player_item()
	print("Placed " + item_name + " on desk " + str(desk_id))

func combine_items_on_desk(desk_id: int, position: Vector2):
	var desk_item = desk_contents[desk_id]
	var result_item = ItemType.NONE
	var result_name = ""
	
	# Determine combination result
	if (player_item == ItemType.WAFFLE and desk_item == "plate") or (player_item == ItemType.PLATE and desk_item == "waffle"):
		result_item = ItemType.WAFFLE_PLATE
		result_name = "waffle_plate"
	elif player_item == ItemType.BREAD_SAUSAGE and desk_item == "plate":
		result_item = ItemType.PLATED_HOTDOG
		result_name = "hotdog_plate"
	
	if result_item != ItemType.NONE:
		# Remove old items
		clear_player_item()
		var sprite_on_desk = desk_sprites[desk_id]
		if sprite_on_desk:
			sprite_on_desk.queue_free()
		
		# Create combined item on desk
		desk_contents[desk_id] = result_name
		var combined_sprite = Sprite2D.new()
		add_child(combined_sprite)
		combined_sprite.texture = get_item_texture(result_item)
		combined_sprite.scale = Vector2(1.5, 1.5)
		combined_sprite.global_position = position
		combined_sprite.z_index = 4
		desk_sprites[desk_id] = combined_sprite
		
		print("Combined items into " + result_name + " on desk " + str(desk_id))

# Keep existing functions for customer system compatibility
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
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color.BLACK
	fade_overlay.color.a = 0.0
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(fade_overlay)
	
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
