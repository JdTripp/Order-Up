# player.gd - CORRECTED VERSION
extends CharacterBody2D

@export var speed = 300.0

# Sprite layer references
@onready var body_sprite = $BodySprite
@onready var outfit_sprite = $OutfitSprite  
@onready var hair_sprite = $HairSprite
@onready var eyes_sprite = $EyesSprite

var last_direction = "down"

# Customization data
var character_data = {
	"body": 0,      # Only one body option (0)
	"outfit": 0,    # Only one outfit option (0)
	"hair": 0,      # Only one hair option (0)  
	"eyes": 0       # 4 eye color options (0-3)
}

# Available options - EXACTLY matching your files
var body_options = ["free_character_nude"]  
var outfit_options = ["male_outfit_original"]  
var hair_options = ["male_hair_orange", "female_hair_lightblue", "female_hair_purple"]  
var eye_options = ["male_eyes_blue", "male_eyes_green", "male_eyes_lightblue", "male_eyes_yellow"]

func _ready():
	print("PLAYER ARRAYS:")
	print("Body options:", body_options.size(), body_options)
	print("Outfit options:", outfit_options.size(), outfit_options) 
	print("Hair options:", hair_options.size(), hair_options)
	print("Eye options:", eye_options.size(), eye_options)
	
	load_character_data()  # Load saved data
	setup_default_appearance()

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
		play_animation("walk_" + last_direction)
	else:
		velocity = Vector2.ZERO
		play_animation("idle_" + last_direction)
	
	move_and_slide()

func play_animation(animation_name: String):
	# Sync all sprite layers to the same animation
	if body_sprite and body_sprite.sprite_frames:
		body_sprite.play(animation_name)
	if outfit_sprite and outfit_sprite.sprite_frames:
		outfit_sprite.play(animation_name)
	if hair_sprite and hair_sprite.sprite_frames:
		hair_sprite.play(animation_name)
	if eyes_sprite and eyes_sprite.sprite_frames:
		eyes_sprite.play(animation_name)

func setup_default_appearance():
	# Ensure character data has valid indices
	character_data = {
		"body": 0,    # Valid: 0 (free_character_nude)
		"outfit": 0,  # Valid: 0 (male_outfit_original)
		"hair": 0,    # Valid: 0 (male_hair_orange)
		"eyes": 0     # Valid: 0 (male_eyes_blue)
	}
	update_character_appearance()

func update_character_appearance():
	# Validate indices before using them
	if character_data.body >= body_options.size():
		character_data.body = 0
	if character_data.outfit >= outfit_options.size():
		character_data.outfit = 0
	if character_data.hair >= hair_options.size():
		character_data.hair = 0
	if character_data.eyes >= eye_options.size():
		character_data.eyes = 0
	
	# Load the appropriate sprite frames for each layer
	var body_path = "res://character assets CUSTOMIZE/" + body_options[character_data.body] + "_frames.tres"
	var outfit_path = "res://character assets CUSTOMIZE/outfit/" + outfit_options[character_data.outfit] + "_frames.tres"
	var hair_path = "res://character assets CUSTOMIZE/hair/" + hair_options[character_data.hair] + "_frames.tres"
	var eyes_path = "res://character assets CUSTOMIZE/eyes/" + eye_options[character_data.eyes] + "_frames.tres"
	
	print("Loading paths:")
	print("Body:", body_path)
	print("Outfit:", outfit_path)
	print("Hair:", hair_path)
	print("Eyes:", eyes_path)
	
	# Apply the sprite frames
	if ResourceLoader.exists(body_path):
		body_sprite.sprite_frames = load(body_path)
		print("Loaded body successfully")
	else:
		print("Body resource not found: ", body_path)
		
	if ResourceLoader.exists(outfit_path):
		outfit_sprite.sprite_frames = load(outfit_path)
		print("Loaded outfit successfully")
	else:
		print("Outfit resource not found: ", outfit_path)
		
	if ResourceLoader.exists(hair_path):
		hair_sprite.sprite_frames = load(hair_path)
		print("Loaded hair successfully")
	else:
		print("Hair resource not found: ", hair_path)
		
	if ResourceLoader.exists(eyes_path):
		eyes_sprite.sprite_frames = load(eyes_path)
		print("Loaded eyes successfully")
	else:
		print("Eyes resource not found: ", eyes_path)
	
	# Make sure all sprites play the same animation
	play_animation("idle_" + last_direction)
	print("Character appearance updated: ", character_data)

func change_body(index: int):
	if index >= 0 and index < body_options.size():
		character_data.body = index
		update_character_appearance()

func change_outfit(index: int):
	if index >= 0 and index < outfit_options.size():
		character_data.outfit = index
		update_character_appearance()

func change_hair(index: int):
	if index >= 0 and index < hair_options.size():
		character_data.hair = index
		update_character_appearance()

func change_eyes(index: int):
	if index >= 0 and index < eye_options.size():
		character_data.eyes = index
		update_character_appearance()

# Save/load customization data
func save_character_data():
	var save_file = FileAccess.open("user://character_data.save", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(character_data))
		save_file.close()
		print("Character data saved: ", character_data)

func load_character_data():
	if FileAccess.file_exists("user://character_data.save"):
		var save_file = FileAccess.open("user://character_data.save", FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var loaded_data = json.data
				# Validate loaded data
				if loaded_data.has("body") and loaded_data.body < body_options.size():
					character_data.body = loaded_data.body
				if loaded_data.has("outfit") and loaded_data.outfit < outfit_options.size():
					character_data.outfit = loaded_data.outfit
				if loaded_data.has("hair") and loaded_data.hair < hair_options.size():
					character_data.hair = loaded_data.hair
				if loaded_data.has("eyes") and loaded_data.eyes < eye_options.size():
					character_data.eyes = loaded_data.eyes
				print("Character data loaded: ", character_data)
			else:
				print("Failed to parse character data")
	else:
		print("No saved character data found")
