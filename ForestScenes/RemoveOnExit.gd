extends VisibleOnScreenNotifier3D

var pastTurn = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#if the node is not currently part of the current turn, remove it as soon as it goes off screen
func _on_screen_exited():
	#print("entered on screen exited ", self, "   ", pastTurn)
	if(pastTurn):
		#print("entered past turn ", self, "  ", pastTurn)
		self.get_parent().queue_free()
	pass # Replace with function body.
