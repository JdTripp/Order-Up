# CustomizationUI.gd - CORRECTED VERSION
extends Control

# References to UI elements
@onready var preview_body = $PreviewPanel/PreviewCharacter/BodySprite
@onready var preview_outfit = $PreviewPanel/PreviewCharacter/OutfitSprite
@onready var preview_hair = $PreviewPanel/PreviewCharacter/HairSprite
@onready var preview_eyes = $PreviewPanel/PreviewCharacter/EyesSprite

# Option buttons
@onready var body_prev_btn = $OptionsPanel/BodyRow/PrevButton
@onready var body_next_btn = $OptionsPanel/BodyRow/NextButton
@onready var body_label = $OptionsPanel/BodyRow/Label

@onready var outfit_prev_btn = $OptionsPanel/OutfitRow/PrevButton
@onready var outfit_next_btn = $OptionsPanel/OutfitRow/NextButton
@onready var outfit_label = $OptionsPanel/OutfitRow/Label

@onready var hair_prev_btn = $OptionsPanel/HairRow/PrevButton
@onready var hair_next_btn = $OptionsPanel/HairRow/NextButton
@onready var hair_label = $OptionsPanel/HairRow/Label

@onready var eyes_prev_btn = $OptionsPanel/EyesRow/PrevButton
@onready var eyes_next_btn = $OptionsPanel/EyesRow/NextButton
@onready var eyes_label = $OptionsPanel/EyesRow/Label

@onready var confirm_btn = $ConfirmButton
@onready var cancel_btn = $CancelButton

# Reference to player
var player: CharacterBody2D
var temp_character_data: Dictionary

# Display names for UI - MUST match player array sizes exactly
var body_options = ["Nude Base"]  # 1 item
var outfit_options = ["Original Outfit"]  # 1 item
var hair_options = ["Orange Hair", "Long LightBlue Hair", "Long Purple Hair"]  # 1 item  
var eye_options = ["Blue Eyes", "Green Eyes", "Light Blue Eyes", "Yellow Eyes"]  # 4 items

func _ready():
	print("CustomizationUI _ready() called")
	print("UI Array sizes - Body:", body_options.size(), "Outfit:", outfit_options.size(), "Hair:", hair_options.size(), "Eyes:", eye_options.size())
	
	# Connect button signals
	if body_prev_btn:
		body_prev_btn.pressed.connect(_on_body_prev)
	if body_next_btn:
		body_next_btn.pressed.connect(_on_body_next)
	if outfit_prev_btn:
		outfit_prev_btn.pressed.connect(_on_outfit_prev)
	if outfit_next_btn:
		outfit_next_btn.pressed.connect(_on_outfit_next)
	if hair_prev_btn:
		hair_prev_btn.pressed.connect(_on_hair_prev)
	if hair_next_btn:
		hair_next_btn.pressed.connect(_on_hair_next)
	if eyes_prev_btn:
		eyes_prev_btn.pressed.connect(_on_eyes_prev)
	if eyes_next_btn:
		eyes_next_btn.pressed.connect(_on_eyes_next)
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm)
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel)
	
	# Hide UI initially
	visible = false
	print("CustomizationUI setup complete")

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
	
	# Update preview and labels
	update_preview()
	update_labels()
	
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
		preview_body.play("idle_down")
		
	if ResourceLoader.exists(outfit_path) and preview_outfit:
		preview_outfit.sprite_frames = load(outfit_path)
		preview_outfit.play("idle_down")
		
	if ResourceLoader.exists(hair_path) and preview_hair:
		preview_hair.sprite_frames = load(hair_path)
		preview_hair.play("idle_down")
		
	if ResourceLoader.exists(eyes_path) and preview_eyes:
		preview_eyes.sprite_frames = load(eyes_path)
		preview_eyes.play("idle_down")

func update_labels():
	if body_label and temp_character_data.body < body_options.size():
		body_label.text = "Body: " + body_options[temp_character_data.body]
	if outfit_label and temp_character_data.outfit < outfit_options.size():
		outfit_label.text = "Outfit: " + outfit_options[temp_character_data.outfit]
	if hair_label and temp_character_data.hair < hair_options.size():
		hair_label.text = "Hair: " + hair_options[temp_character_data.hair]
	if eyes_label and temp_character_data.eyes < eye_options.size():
		eyes_label.text = "Eyes: " + eye_options[temp_character_data.eyes]

# Button callbacks - SAFE VERSION
func _on_body_prev():
	if body_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.body = (temp_character_data.body - 1) % body_options.size()
		if temp_character_data.body < 0:
			temp_character_data.body = body_options.size() - 1
		update_preview()
		update_labels()

func _on_body_next():
	if body_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.body = (temp_character_data.body + 1) % body_options.size()
		update_preview()
		update_labels()

func _on_outfit_prev():
	if outfit_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.outfit = (temp_character_data.outfit - 1) % outfit_options.size()
		if temp_character_data.outfit < 0:
			temp_character_data.outfit = outfit_options.size() - 1
		update_preview()
		update_labels()

func _on_outfit_next():
	if outfit_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.outfit = (temp_character_data.outfit + 1) % outfit_options.size()
		update_preview()
		update_labels()

func _on_hair_prev():
	if hair_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.hair = (temp_character_data.hair - 1) % hair_options.size()
		if temp_character_data.hair < 0:
			temp_character_data.hair = hair_options.size() - 1
		update_preview()
		update_labels()

func _on_hair_next():
	if hair_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.hair = (temp_character_data.hair + 1) % hair_options.size()
		update_preview()
		update_labels()

func _on_eyes_prev():
	if eye_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.eyes = (temp_character_data.eyes - 1) % eye_options.size()
		if temp_character_data.eyes < 0:
			temp_character_data.eyes = eye_options.size() - 1
		update_preview()
		update_labels()

func _on_eyes_next():
	if eye_options.size() > 1:  # Only allow changing if there are multiple options
		temp_character_data.eyes = (temp_character_data.eyes + 1) % eye_options.size()
		update_preview()
		update_labels()

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
	get_tree().paused = false
	print("UI closed, game resumed")
