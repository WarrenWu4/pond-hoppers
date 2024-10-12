extends CharacterBody2D

class_name Player

var gravity = 800
var min_jump_force = -200
var max_jump_force = -400
var move_speed = 200

var is_jumping = false
var is_charging_jump = false
var charge_time = 0.0
var max_charge_time = 2

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity when not on the ground

	handle_jump(delta)

	# Move the player with the velocity vector
	move_and_slide()

	# Reset jumping state when back on the ground
	if is_on_floor():
		is_jumping = false

func handle_jump(delta):
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			is_charging_jump = true
			charge_time = 0.0
		elif Input.is_action_pressed("jump") and is_charging_jump:
			charge_time += delta
			charge_time = min(charge_time, max_charge_time)
		elif Input.is_action_just_released("jump") and is_charging_jump:
			var jump_force = lerp(min_jump_force, max_jump_force, charge_time / max_charge_time)
			print(jump_force)
			velocity.y = jump_force
			is_charging_jump = false
	
# linear interpolation between 2 values to scale the jump force
func lerp(a, b, t):
	return a + (b-a) * t
	

	
