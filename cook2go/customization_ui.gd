# CustomizationUI.gd - COMPLETE VERSION with Arrow Rotation
extends Control

# References to UI elements
@onready var preview_body = $PreviewPanel/PreviewCharacter/BodySprite
@onready var preview_outfit = $PreviewPanel/PreviewCharacter/OutfitSprite
@onready var preview_hair = $PreviewPanel/PreviewCharacter/HairSprite
@onready var preview_eyes = $PreviewPanel/PreviewCharacter/EyesSprite

# Category buttons (the 4 squares at bottom showing current selections)
@onready var body_category_btn = $CategoryPanel/BodyCategoryButton
@onready var hair_category_btn = $CategoryPanel/HairCategoryButton
@onready var outfit_category_btn = $CategoryPanel/OutfitCategoryButton
@onready var eyes_category_btn = $CategoryPanel/EyesCategoryButton

# Arrow buttons for character rotation
@onready var left_arrow = $LeftArrow
@onready var right_arrow = $RightArrow

# Options panel (RIGHT side - shows available options when category is selected)
@onready var options_panel = $OptionsPanel
@onready var options_grid = $OptionsPanel/ScrollContainer/OptionsGrid
@onready var category_title = $OptionsPanel/CategoryTitle

# Control buttons
@onready var confirm_btn = $OptionsPanel/ConfirmButton
@onready var cancel_btn = $OptionsPanel/CancelButton

# Reference to player
var player: CharacterBody2D
var temp_character_data: Dictionary
var current_category = ""

# Current character direction
var current_direction = "down"  # Start with idle_down
var directions = ["down", "right", "up", "left"]  # Rotation order

# Display names for UI
var body_options = ["Nude Base"]
var outfit_options = ["Original Outfit", "Green Outfit"]
var hair_options = ["Orange Hair", "Long LightBlue Hair", "Long Purple Hair"]
var eye_options = ["Blue Eyes", "Green Eyes", "Light Blue Eyes", "Yellow Eyes"]

func _ready():
	print("CustomizationUI _ready() called")
	
	# Connect category button signals - these show the options panel
	if body_category_btn:
		body_category_btn.pressed.connect(func(): show_category_options("body"))
	if hair_category_btn:
		hair_category_btn.pressed.connect(func(): show_category_options("hair"))
	if outfit_category_btn:
		outfit_category_btn.pressed.connect(func(): show_category_options("outfit"))
	if eyes_category_btn:
		eyes_category_btn.pressed.connect(func(): show_category_options("eyes"))
	
	# Connect arrow buttons
	if left_arrow:
		left_arrow.pressed.connect(_on_left_arrow)
		print("Connected left arrow")
	if right_arrow:
		right_arrow.pressed.connect(_on_right_arrow)
		print("Connected right arrow")
	
	# Connect control buttons
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm)
		print("Connected confirm button")
	else:
		print("Confirm button not found!")
		
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel)
		print("Connected cancel button")
	else:
		print("Cancel button not found!")
	
	# Hide UI initially
	visible = false
	
	# Hide options panel initially
	if options_panel:
		options_panel.visible = false

func open_customization(player_ref: CharacterBody2D):
	print("=== OPENING CUSTOMIZATION UI ===")
	
	player = player_ref
	if not player:
		print("ERROR: No player reference!")
		return
	
	# Copy current character data for editing
	temp_character_data = player.character_data.duplicate()
	print("Current character data:", temp_character_data)
	
	# Validate temp data
	if temp_character_data.body >= body_options.size():
		temp_character_data.body = 0
	if temp_character_data.outfit >= outfit_options.size():
		temp_character_data.outfit = 0
	if temp_character_data.hair >= hair_options.size():
		temp_character_data.hair = 0
	if temp_character_data.eyes >= eye_options.size():
		temp_character_data.eyes = 0
	
	# Reset to down direction when opening
	current_direction = "down"
	
	# Update preview and category buttons
	update_preview()
	update_category_buttons()
	
	# Show UI and pause game
	visible = true
	get_tree().paused = true
	print("UI visible, game paused")

func update_preview():
	if not player:
		return
		
	# Update the preview character to match temp data
	var body_path = "res://character assets CUSTOMIZE/" + player.body_options[temp_character_data.body] + "_frames.tres"
	var outfit_path = "res://character assets CUSTOMIZE/outfit/" + player.outfit_options[temp_character_data.outfit] + "_frames.tres"
	var hair_path = "res://character assets CUSTOMIZE/hair/" + player.hair_options[temp_character_data.hair] + "_frames.tres"
	var eyes_path = "res://character assets CUSTOMIZE/eyes/" + player.eye_options[temp_character_data.eyes] + "_frames.tres"
	
	# Load and apply sprite frames
	if ResourceLoader.exists(body_path) and preview_body:
		preview_body.sprite_frames = load(body_path)
		preview_body.play("idle_" + current_direction)
		
	if ResourceLoader.exists(outfit_path) and preview_outfit:
		preview_outfit.sprite_frames = load(outfit_path)
		preview_outfit.play("idle_" + current_direction)
		
	if ResourceLoader.exists(hair_path) and preview_hair:
		preview_hair.sprite_frames = load(hair_path)
		preview_hair.play("idle_" + current_direction)
		
	if ResourceLoader.exists(eyes_path) and preview_eyes:
		preview_eyes.sprite_frames = load(eyes_path)
		preview_eyes.play("idle_" + current_direction)

# Update the 4 category buttons to show current selections
func update_category_buttons():
	print("Updating category buttons to show current selections...")
	
	if body_category_btn:
		set_category_button_preview(body_category_btn, "body", temp_character_data.body)
	if hair_category_btn:
		set_category_button_preview(hair_category_btn, "hair", temp_character_data.hair)
	if outfit_category_btn:
		set_category_button_preview(outfit_category_btn, "outfit", temp_character_data.outfit)
	if eyes_category_btn:
		set_category_button_preview(eyes_category_btn, "eyes", temp_character_data.eyes)

# Set a category button to show a small preview of the current selection
func set_category_button_preview(button: TextureButton, category: String, index: int):
	print("Setting button preview for ", category, " index ", index)
	
	# Reset button to original color/texture
	button.modulate = Color.WHITE
	
	# Remove any existing character sprite child
	for child in button.get_children():
		if child.name == "CharacterPreview":
			child.queue_free()
	
	# Create a small character sprite to show on top of the button
	var preview_sprite = AnimatedSprite2D.new()
	preview_sprite.name = "CharacterPreview"
	preview_sprite.scale = Vector2(1, 1)
	preview_sprite.position = Vector2(33, 21)  # Centered on the button
	preview_sprite.z_index = 10
	
	# Load the appropriate sprite frames for this category
	var sprite_frames_path = ""
	match category:
		"body":
			if index < player.body_options.size():
				sprite_frames_path = "res://character assets CUSTOMIZE/" + player.body_options[index] + "_frames.tres"
		"hair":
			if index < player.hair_options.size():
				sprite_frames_path = "res://character assets CUSTOMIZE/hair/" + player.hair_options[index] + "_frames.tres"
		"outfit":
			if index < player.outfit_options.size():
				sprite_frames_path = "res://character assets CUSTOMIZE/outfit/" + player.outfit_options[index] + "_frames.tres"
		"eyes":
			if index < player.eye_options.size():
				sprite_frames_path = "res://character assets CUSTOMIZE/eyes/" + player.eye_options[index] + "_frames.tres"
	
	# Load and apply the sprite frames
	if ResourceLoader.exists(sprite_frames_path):
		preview_sprite.sprite_frames = load(sprite_frames_path)
		preview_sprite.play("idle_down")  # Category buttons always show idle_down
		button.add_child(preview_sprite)
		print("Added ", category, " preview sprite to button")
	else:
		print("Could not find sprite frames: ", sprite_frames_path)
	
	print("=== End button preview setup ===")

# Show options panel on the RIGHT with all available options for the selected category
func show_category_options(category: String):
	current_category = category
	print("=== SHOWING OPTIONS FOR: ", category, " ===")
	
	# Show the options panel
	if options_panel:
		options_panel.visible = true
		print("Options panel made visible")
	
	# Set category title
	if category_title:
		category_title.text = category.capitalize() + " Options"
	
	# Clear existing options
	if options_grid:
		# Set grid to 2 columns
		options_grid.columns = 2
		
		for child in options_grid.get_children():
			child.queue_free()
		
		await get_tree().process_frame
		
		# Populate options based on category
		match category:
			"body":
				create_option_buttons(body_options, temp_character_data.body, "body")
			"hair":
				create_option_buttons(hair_options, temp_character_data.hair, "hair")
			"outfit":
				create_option_buttons(outfit_options, temp_character_data.outfit, "outfit")
			"eyes":
				create_option_buttons(eye_options, temp_character_data.eyes, "eyes")

# Create clickable option buttons for the selected category
func create_option_buttons(option_names: Array, current_index: int, category: String):
	print("=== CREATING OPTIONS FOR: ", category, " ===")
	print("Option names: ", option_names)
	print("Number of options: ", option_names.size())
	
	for i in range(option_names.size()):
		print("Creating option ", i, ": ", option_names[i])
		
		# Create the main button with background from your UI sheet
		var option_button = TextureButton.new()
		option_button.custom_minimum_size = Vector2(120, 120)  # Bigger buttons
		
		# Load background texture from your UI asset sheet
		var background_atlas = AtlasTexture.new()
		background_atlas.atlas = load("res://assets UI/Modern_UI_Style_1.png")
		background_atlas.region = Rect2(100, 100, 32, 32)
		option_button.texture_normal = background_atlas
		
		# Create character preview sprite
		var preview_sprite = AnimatedSprite2D.new()
		preview_sprite.name = "CharacterPreview"
		preview_sprite.scale = Vector2(1.5, 1.5)  # Bigger sprite
		preview_sprite.position = Vector2(60, 60)  # Center on the 120x120 button
		preview_sprite.z_index = 10
		
		# Get the sprite frames path and check if it exists
		var sprite_frames_path = get_sprite_frames_path(category, i)
		print("Looking for sprite frames at: ", sprite_frames_path)
		print("File exists: ", ResourceLoader.exists(sprite_frames_path))
		
		# Load the sprite frames for this specific option
		if ResourceLoader.exists(sprite_frames_path):
			preview_sprite.sprite_frames = load(sprite_frames_path)
			preview_sprite.play("idle_down")  # Options always show idle_down
			option_button.add_child(preview_sprite)
		
		# Highlight current selection
		if i == current_index:
			option_button.modulate = Color.YELLOW
		
		# Connect button signal
		option_button.pressed.connect(func(): select_option(category, i))
		
		options_grid.add_child(option_button)
		print("Created option button ", i, " for ", category)

# Get sprite frames path for a category and index
func get_sprite_frames_path(category: String, index: int) -> String:
	match category:
		"body":
			if index < player.body_options.size():
				return "res://character assets CUSTOMIZE/" + player.body_options[index] + "_frames.tres"
		"hair":
			if index < player.hair_options.size():
				return "res://character assets CUSTOMIZE/hair/" + player.hair_options[index] + "_frames.tres"
		"outfit":
			if index < player.outfit_options.size():
				return "res://character assets CUSTOMIZE/outfit/" + player.outfit_options[index] + "_frames.tres"
		"eyes":
			if index < player.eye_options.size():
				return "res://character assets CUSTOMIZE/eyes/" + player.eye_options[index] + "_frames.tres"
	return ""

# When player clicks an option from the right panel
func select_option(category: String, index: int):
	print("Selected ", category, " option ", index)
	
	# Update the character data
	match category:
		"body":
			temp_character_data.body = index
		"hair":
			temp_character_data.hair = index
		"outfit":
			temp_character_data.outfit = index
		"eyes":
			temp_character_data.eyes = index
	
	# Update preview and category buttons
	update_preview()
	update_category_buttons()
	
	# Refresh the options panel to show new selection highlight
	show_category_options(current_category)

# Rotate character left (counter-clockwise)
func _on_left_arrow():
	var current_index = directions.find(current_direction)
	current_index = (current_index - 1) % directions.size()
	if current_index < 0:
		current_index = directions.size() - 1
	current_direction = directions[current_index]
	update_character_rotation()
	print("Rotated left to: ", current_direction)

# Rotate character right (clockwise) 
func _on_right_arrow():
	var current_index = directions.find(current_direction)
	current_index = (current_index + 1) % directions.size()
	current_direction = directions[current_index]
	update_character_rotation()
	print("Rotated right to: ", current_direction)

# Update all character sprites to show the new direction
func update_character_rotation():
	var animation_name = "idle_" + current_direction
	
	if preview_body and preview_body.sprite_frames:
		preview_body.play(animation_name)
	if preview_outfit and preview_outfit.sprite_frames:
		preview_outfit.play(animation_name)
	if preview_hair and preview_hair.sprite_frames:
		preview_hair.play(animation_name)
	if preview_eyes and preview_eyes.sprite_frames:
		preview_eyes.play(animation_name)
	
	print("Character rotated to: ", current_direction)

func _on_confirm():
	print("Confirming changes...")
	# Apply changes to player
	player.character_data = temp_character_data.duplicate()
	player.update_character_appearance()
	player.save_character_data()
	close_ui()

func _on_cancel():
	print("Cancelling changes...")
	close_ui()

func close_ui():
	visible = false
	if options_panel:
		options_panel.visible = false
	get_tree().paused = false
	print("UI closed, game resumed")
