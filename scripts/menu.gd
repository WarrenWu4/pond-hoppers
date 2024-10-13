extends CanvasLayer

@onready var game_node = get_parent()
@onready var game_manager_scene = preload("res://scenes/game_manager.tscn")

@onready var background = $Background
@onready var button = $Button
@onready var rich_text_label = $RichTextLabel
@onready var text_edit = $TextEdit
@onready var button_2 = $Button2

func _ready():
	# hide username prompting
	text_edit.hide()
	button_2.hide()

func _on_button_pressed():
	# show username prompting
	text_edit.show()
	button_2.show()
	# hide other elements
	background.hide()
	button.hide()
	rich_text_label.hide()

func _on_button_2_pressed():
	# store username somewhere
	GameData.username = text_edit.get_text()
	# add the game manager as a node 
	var game_manager_instance = game_manager_scene.instantiate()
	game_node.add_child(game_manager_instance)
	# make the menu disappear
	queue_free()
