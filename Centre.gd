extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

func rotateChild(dir, amount):
	#push_warning("direction asked to turn: ", dir, " amount to turn: ", amount)
	rotate_y(dir * amount)
