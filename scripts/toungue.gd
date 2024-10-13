extends Node2D

@onready var player = $"../Player"  # Adjust to match your scene structure
@onready var line = $Line2D
@onready var collision_area = $Area2D  # Reference to the Area2D at the tongue's tip
@onready var search_area = $"../Player/SearchArea/" # Adjust path to match your scene structure


# Variables
var is_retracting = false
var retract_when_hit = false
var extending = false
var retraction_speed = 300  # Adjust as needed
var extension_speed = 400  # Speed at which the tongue extends
var target_position = null 

# Called every frame
func _process(delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_retracting and not extending:
		collision_area.position = player.global_position
		find_nearest_target()
		collision_area.position = player.global_position
	elif retract_when_hit:
		retract_when_hit_fn(delta)
	elif is_retracting:
		retract(delta)
	elif extending:
		extend_incrementally(delta)

func extend_incrementally(delta):
	if target_position:
		var player_pos = line.to_local(player.global_position)
		line.set_point_position(0, player_pos)
		# Calculate the direction towards the target position
		var current_end = line.get_point_position(1)
		var direction = (target_position - current_end).normalized()
		var new_end_point = current_end + direction * extension_speed * delta
		
		# Update the line's endpoint position
		line.set_point_position(1, new_end_point)
		
		# Update the collision area to follow the tongue's tip
		collision_area.position = line.get_point_position(1)
		
		# Stop extending if we reach the target position
		if (new_end_point - target_position).length() <= extension_speed * delta:
			extending = false
			is_retracting = true  # Start retracting after reaching the target

#
## Function to retract the line from the start point towards the end point
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
	#("Retracting collision position:", collision_area.position)

	# Check if the new start point has reached the end point
	if (new_start_point - end_point).length() <= retraction_speed * delta:
		# Snap the start point to the end point and stop retracting
		line.set_point_position(0, end_point)
		player.global_position = line.to_global(end_point)
		is_retracting = false  # Disable retraction once the endpoint is reached

#func retract(delta):
	#if line.points.size() < 2:
		#return  # Ensure there are two points to retract between
#
	#var start_point = line.get_point_position(0)
	#var end_point = line.get_point_position(1)
	#var direction = (end_point - start_point).normalized()
	#var new_start_point = start_point + direction * retraction_speed * delta
#
	## Only update the player's position at the beginning of retraction
	#if not is_retracting:
		#player.global_position = line.to_global(new_start_point)
	#
	#line.set_point_position(0, new_start_point)
	#collision_area.position = line.get_point_position(1)  # Keep the collision at the end point
#
	#if (new_start_point - end_point).length() <= retraction_speed * delta:
		#line.set_point_position(0, end_point)
		#player.global_position = line.to_global(end_point)
		#is_retracting = false  # Stop retracting once the endpoint is reached

func retract_when_hit_fn(delta):
	print('hit')
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
	line.set_point_position(0, player.global_position)
	# Update the player's position to follow the retracting start point
	# player.global_position = line.to_global(start_point)
	
	# Check if the endpoint has reached the start point
	if (new_end_point - start_point).length() <= retraction_speed * delta:
		# Snap the end point to the start point and stop retracting
		line.set_point_position(1, start_point)
		retract_when_hit = false


# Function to find the nearest target block within the search radius
func find_nearest_target():
	var nearest_block = null
	var shortest_distance = INF

	# Iterate over all bodies overlapping the search area
	for body in search_area.get_overlapping_bodies():
		# Check if the body is in the "target_blocks" group
		if body.is_in_group("target_blocks"):
			var distance = player.global_position.distance_to(body.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_block = body

	# If a target block is found, set its position as the target
	if nearest_block:
		target_position = line.to_local(nearest_block.global_position)
		extend_to_target()

# Function to start extending the tongue to the target position
func extend_to_target():
	is_retracting = false
	retract_when_hit = false
	extending = true
	
	# Set the starting point of the line to the player's position
	var player_pos = line.to_local(player.global_position)
	if line.points.size() < 2:
		line.points = [player_pos, player_pos]
	else:
		line.set_point_position(0, player_pos)
		line.set_point_position(1, player_pos) 
		

	# Set the collision area to the player's position
	collision_area.position = player_pos
	
# Collision signal function to start retraction
func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if not retract_when_hit:
		extending = false
		retract_when_hit = true  # Begin retraction upon collision

func process_target(area: Area2D):
	target_position = line.to_local(area.global_position)
	extend_to_target()
