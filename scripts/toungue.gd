extends Node2D


@onready var player = $"../Player"  # Adjust the path to match your scene structure
@onready var line = $Line2D

# Variables
var is_retracting = false
var retraction_speed = 300  # Adjust this speed as needed


# Called every frame
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_retracting:
		extend_to_mouse()
	elif is_retracting:
		retract(delta)

# Function to extend the line to the mouse click position
func extend_to_mouse():
	# Check if the Line2D and Player nodes exist
	if line and player:
		# Set the starting point of the line to the player's position
		var player_pos = line.to_local(player.global_position)
		
		# Ensure the Line2D has two points, setting the first to player position
		if line.points.size() < 2:
			line.points = [player_pos, Vector2.ZERO]
		else:
			line.set_point_position(0, player_pos)

		var mouse_pos = line.to_local(get_global_mouse_position())
		
		line.set_point_position(1, mouse_pos)
		
		is_retracting = true
# Function to retract the line from the start point towards the end point
func retract(delta):
	if line.points.size() < 2:
		return  # Ensure there are two points to retract between

	# Get the current start and end points
	var start_point = line.get_point_position(0)
	var end_point = line.get_point_position(1)
	
	# Calculate the direction from start to end
	var direction = (end_point - start_point).normalized()
	var new_start_point = start_point + direction * retraction_speed * delta
	
	# Move the player to follow the retracting start point
	player.global_position = line.to_global(new_start_point)
	
	# Check if the new start point has reached the end point
	if (new_start_point - end_point).length() <= retraction_speed * delta:
		# Snap the start point to the end point and stop retracting
		line.set_point_position(0, end_point)
		player.global_position = line.to_global(end_point)
		is_retracting = false
	else:
		# Update the start point to move closer to the end point
		line.set_point_position(0, new_start_point)
