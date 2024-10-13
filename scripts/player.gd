extends CharacterBody2D

class_name Player

@onready var camera_2d = $Camera2D
@onready var level_manager = $"../LevelManager"
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var power_jump = $PowerJump
@onready var power_jump_gradient = $PowerJump/PowerJumpGradient
@onready var power_jump_indicator = $PowerJump/PowerJumpIndicator

var gravity = 800
var move_speed = 150
var min_jump_force = -200
var max_jump_force = -400

var is_jumping = false
var is_charging_jump = false
var charge_time = 0.0
var max_charge_time = 2
var move_direction = 0

func _ready():
	# adjust the camera size
	var viewport_size = get_viewport_rect().size
	var tilemap_size = level_manager.get_child(0).get_used_rect().size*16
	camera_2d.zoom = Vector2(viewport_size.x/tilemap_size.x, viewport_size.x/tilemap_size.x)
	# offset the camera so that it starts at the bottom of the tile map
	power_jump.hide()
	
func _physics_process(delta):
	# if not on floor (jumping) handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity when not on the ground
	# otherwise if on floor, reset velocity x
	else:
		velocity.x = 0
	
	detect_collisions_from_layer()
	
	# logic for moving left and right
	if is_on_floor() and not is_jumping and not Input.is_action_pressed("jump"):
		if Input.is_action_pressed("move_left"):
			velocity.x = -move_speed
			animated_sprite_2d.flip_h = false
		elif Input.is_action_pressed("move_right"):
			velocity.x = move_speed
			animated_sprite_2d.flip_h = true			
		
	handle_jump(delta)

	# Move the player with the velocity vector
	move_and_slide()

	# Reset jumping state when back on the ground
	if is_on_floor():
		is_jumping = false
		animated_sprite_2d.play("idle")

func handle_jump(delta):
	# charging jump logic
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			is_charging_jump = true
			charge_time = 0.0
		elif Input.is_action_pressed("jump") and is_charging_jump:
			charge_time += delta
			charge_time = min(charge_time, max_charge_time)
			power_jump.show()
			handle_show_power(charge_time / max_charge_time)
		elif Input.is_action_just_released("jump") and is_charging_jump:
			power_jump.hide()
			power_jump_indicator.position.y = -11
			var jump_force = lerp(min_jump_force, max_jump_force, charge_time / max_charge_time)
			velocity.y = jump_force
			velocity.x = move_speed * move_direction
			move_direction = 0
			is_charging_jump = false
			is_jumping = true
			animated_sprite_2d.play("jumping")
			
	# projectile motion logic
	if Input.is_action_just_pressed("move_left"):
		move_direction = -1
		animated_sprite_2d.flip_h = false
	elif Input.is_action_just_pressed("move_right"):
		move_direction = 1
		animated_sprite_2d.flip_h = true
	
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
			if normal.x != 0 and is_jumping:  # If the collision was horizontal (wall)
				velocity.x = 1.2*move_speed*normal.x  # Reverse the x velocity for bouncing
				if normal.x == -1:
					animated_sprite_2d.flip_h = false
				else:
					animated_sprite_2d.flip_h = true

func handle_show_power(charge_ratio):
	if (power_jump_indicator.position.y > -24):
		power_jump_indicator.position.y = lerp(-13, -24, charge_ratio)
