extends CharacterBody2D

class_name Player

@onready var camera_2d = $Camera2D
@onready var level_manager = $"../LevelManager"
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var power_jump = $PowerJump
@onready var power_jump_gradient = $PowerJump/PowerJumpGradient
@onready var power_jump_indicator = $PowerJump/PowerJumpIndicator
@onready var http_request = $HTTPRequest
@onready var label = $Label

var gravity = 800
var move_speed = 125
var min_jump_force = -200
var max_jump_force = -400

var is_jumping = false
var is_charging_jump = false
var charge_time = 0.0
var max_charge_time = 1.2
var move_direction = 0
var jump_power_multiplier = 1

var allow_movement = true

@onready var toungue = $"../Toungue"
@onready var search_area = $SearchArea

func _ready():
	# add player to the player ground
	add_to_group("player")
	# adjust the camera size
	var viewport_size = get_viewport_rect().size
	var tilemap_size = level_manager.get_child(1).get_used_rect().size*16
	camera_2d.zoom = Vector2(viewport_size.x/tilemap_size.x, viewport_size.x/tilemap_size.x)
	
	# hide the power meter initially and death label
	power_jump.hide()
	label.hide()
	
	# get game manager node
	var game_manager = get_parent()
	game_manager.gc_signal.connect(_on_game_complete)
	game_manager.curr_temp.connect(_handle_temp)

func _physics_process(delta):
	# if not on floor (jumping) handle gravity
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity when not on the ground
	# otherwise if on floor, reset velocity x
	else:
		velocity.x = 0
		
	if Input.is_action_just_pressed("use_tongue"):
		find_nearest_target()
	
	detect_collisions_from_layer()
	
	# logic for moving left and right
	if allow_movement and is_on_floor() and not is_jumping and not Input.is_action_pressed("jump"):
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
	if allow_movement and is_on_floor():
		is_jumping = false
		animated_sprite_2d.play("idle")

func handle_jump(delta):
	if not allow_movement:
		return
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
			velocity.y = jump_force * jump_power_multiplier
			velocity.x = move_speed * move_direction * jump_power_multiplier
			move_direction = 0
			is_charging_jump = false
			is_jumping = true
			animated_sprite_2d.play("jumping")
			
	# projectile motion logic
	if Input.is_action_pressed("move_left"):
		move_direction = -1
		animated_sprite_2d.flip_h = false
	elif Input.is_action_pressed("move_right"):
		move_direction = 1
		animated_sprite_2d.flip_h = true
	else:
		move_direction = 0
	
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

func store_time(name, time):
	# make an http post request to backend to update leaderboard
	var url = "http://localhost:8080/receive_time"
	var headers = ["Content-Type: application/json"]
	var body = {
		"name": name,
		"time": time
	}
	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST, 
		JSON.stringify(body)
	)
	
	if error != OK:
		print("error occurred:", error)

func _on_http_request_request_completed(result, response_code, headers, body):
	print("request completed")

func _on_game_complete(data):
	var curr_username = GameData.username
	store_time(curr_username, data)
	allow_movement = false
	animated_sprite_2d.hide()
	
func _handle_temp(data):
	var temp = data
	if (temp >= 350):
		# initiate death
		allow_movement = false
		animated_sprite_2d.play("DEATH")
		label.show()
	var multiplier_ratio = clamp(0, temp-100, 300)
	jump_power_multiplier = min(1 - 0.5 * multiplier_ratio/300, 1)

func restart_game():
	var current_scene = get_tree().current_scene
	var current_scene_file = current_scene.scene_file_path
	get_tree().change_scene_to_file(current_scene_file)


func _on_animated_sprite_2d_animation_finished():
	if (animated_sprite_2d.animation == "DEATH"):
		restart_game()
		
func find_nearest_target():
	var nearest_block = null
	var shortest_distance = INF
	
	# Iterate over all areas overlapping the search area
	for area in search_area.get_overlapping_areas():
		# Check if the area is in the "target_blocks" group
		if area.is_in_group("target_blocks"):
			var distance = global_position.distance_to(area.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_block = area

	# If a target block is found, call process_target on the tongue
	if nearest_block:
		toungue.process_target(nearest_block)
