extends Node2D

func _ready():
	# Position player at spawn point
	var player = $Player
	var spawn_point = get_node_or_null("PlayerSpawnPoint")
	if spawn_point and player:
		player.global_position = spawn_point.global_position
	
	# Simple fade in - find and remove any black overlay
	remove_fade_overlay()

func remove_fade_overlay():
	# Find and remove any ColorRect overlays
	var root = get_tree().root
	for child in root.get_children():
		if child is ColorRect and child.color == Color.BLACK:
			var tween = create_tween()
			tween.tween_property(child, "color:a", 0.0, 0.5)
			await tween.finished
			child.queue_free()
			break
