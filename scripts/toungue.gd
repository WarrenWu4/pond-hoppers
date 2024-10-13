extends Node2D

@onready var player = $"../Player"  # Adjust to match your scene structure
@onready var line = $Line2D
@onready var collision_area = $Area2D  # Reference to the Area2D at the tongue's tip

# Variables
var is_retracting = false
var retract_when_hit = false
var retraction_speed = 300  # Adjust as needed

# Called every frame
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_retracting:
		extend_to_mouse()
	elif retract_when_hit:
		retract_when_hit_fn(delta)
	elif is_retracting:
		retract(delta)

		

# Function to extend the line to the mouse click position
func extend_to_mouse():
	is_retracting = false  # Ensure we're not retracting when extending
	
	# Set the starting point of the line to the player's position
	var player_pos = line.to_local(player.global_position)
	if line.points.size() < 2:
		line.points = [player_pos, Vector2.ZERO]
	else:
		line.set_point_position(0, player_pos)
	
	# Set the endpoint to the mouse position
	var mouse_pos = line.to_local(get_global_mouse_position())
	line.set_point_position(1, mouse_pos)
	
	# Move the collision area to the endpoint of the tongue
	collision_area.position = mouse_pos
	
	# Enable retraction after extending
	is_retracting = true
#
### Function to retract the line from the start point towards the end point
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
	
	# Update the line's starting position to retract toward the end
	line.set_point_position(0, new_start_point)
	
	# Update the collision area to follow the endpoint of the line
	collision_area.position = line.get_point_position(1)  # Keep the collision at the end point

	# Check if the new start point has reached the end point
	if (new_start_point - end_point).length() <= retraction_speed * delta:
		# Snap the start point to the end point and stop retracting
		line.set_point_position(0, end_point)
		player.global_position = line.to_global(end_point)
		is_retracting = false  # Disable retraction once the endpoint is reached
		
func retract_when_hit_fn(delta):
	if line.points.size() < 2:
		return  # Ensure there are two points to retract between

	# Get the current start and end points
	var start_point = line.get_point_position(0)
	var end_point = line.get_point_position(1)
	
	# Calculate the direction from end to start
	var direction = (start_point - end_point).normalized()
	var new_end_point = end_point + direction * retraction_speed * delta
	
	# Update the line's endpoint to move closer to the start point
	line.set_point_position(1, new_end_point)
	
	# Move the collision area to the new endpoint position
	collision_area.position = line.get_point_position(1)  # Keep the collision area at the end point
	
	# Update the player's position to follow the retracting start point
	player.global_position = line.to_global(start_point)
	
	# Check if the endpoint has reached the start point
	if (new_end_point - start_point).length() <= retraction_speed * delta:
		# Snap the end point to the start point and stop retracting
		line.set_point_position(1, start_point)
		player.global_position = line.to_global(start_point)
		retract_when_hit = false

# Collision signal function to start retraction
func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if not retract_when_hit:
		retract_when_hit = true  # Begin retraction upon collision
