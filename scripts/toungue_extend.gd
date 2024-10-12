extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var line  = $Line2D
	line.points = [Vector2.ZERO, Vector2(50, 0)]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
