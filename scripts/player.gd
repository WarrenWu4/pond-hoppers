extends CharacterBody2D

class_name Player

var gravity = 800
var move_speed = 200
var min_jump_force = -200
var max_jump_force = -400

var is_jumping = false
var is_charging_jump = false
var charge_time = 0.0
var max_charge_time = 2
var move_direction = 0

func _physics_process(delta):
	# if not on floor (jumping) handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity when not on the ground
	# otherwise if on floor, reset velocity x
	else:
		velocity.x = 0
	
	detect_collisions_from_layer()
		
	handle_jump(delta)

	# Move the player with the velocity vector
	move_and_slide()

	# Reset jumping state when back on the ground
	if is_on_floor():
		is_jumping = false

func handle_jump(delta):
	# charging jump logic
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			is_charging_jump = true
			charge_time = 0.0
		elif Input.is_action_pressed("jump") and is_charging_jump:
			charge_time += delta
			charge_time = min(charge_time, max_charge_time)
		elif Input.is_action_just_released("jump") and is_charging_jump:
			var jump_force = lerp(min_jump_force, max_jump_force, charge_time / max_charge_time)
			velocity.y = jump_force
			velocity.x = move_speed * move_direction
			move_direction = 0
			is_charging_jump = false
	# projectile motion logic
	if Input.is_action_just_pressed("move_left"):
		move_direction = -1
	elif Input.is_action_just_pressed("move_right"):
		move_direction = 1
	
# linear interpolation between 2 values to scale the jump force
func lerp(a, b, t):
	return a + (b-a) * t

var bounce_force = 1.2
func detect_collisions_from_layer():
	# Loop through all collisions detected in the current frame
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision:
			var normal = collision.get_normal()  # The normal vector of the surface
			#print(normal)
		 	# add some sort of threshold for collision b/c
			# might hit an object horizontally that's not a wall
			if normal.x != 0:  # If the collision was horizontal (wall)
				velocity.x = 1.2*move_speed  # Reverse the x velocity for bouncing
