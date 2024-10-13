extends Node

@onready var hud = $HUD
@onready var sprite_2d = $Area2D/Sprite2D

var elapsed_time = 0.0
var game_complete = false

signal gc_signal(data)

func _process(delta):
	# get time in min and sec
	if not game_complete:
		elapsed_time += delta
		var minutes = int(elapsed_time)/60
		var seconds = int(elapsed_time)%60
		hud.update_timer(minutes, seconds)
	
func _on_area_2d_body_entered(body):
	if (body.is_in_group("player")):
		game_complete = true
		var froggy_ship = load("res://assets/frog/frogInRocket.png")
		sprite_2d.texture = froggy_ship
		emit_signal("gc_signal", elapsed_time)
