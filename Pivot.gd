extends Node3D

var goal_rotation = Vector3(0, 30, 0)
var current_rotation
var max_extra_turn = 4 #can change this - how much the position of the object can change within a single turn of the player
var turnDirection = 0 #1 - positive, -1 negative, 0 no turn
var lastBasis
var threshold_difference = 0.00001 #how much a user has to rotate since the last frame for it to be considered a rotation
var counter_reset = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	current_rotation = get_node("../PlayerPC").global_transform.basis.x
	lastBasis = current_rotation
	print(current_rotation)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	current_rotation = get_node("../PlayerPC").global_transform.basis.x
	#if the player started a new turn
	if(current_rotation != lastBasis): # and ((abs(current_rotation.dot(lastBasis)) < 1-threshold_difference) or (abs(current_rotation.dot(lastBasis)) > 1 + threshold_difference))):
		print("in turn")
		counter_reset -= 1
		#basic idea - if it's a new turn, the flag is reset and the goal post moved, if it's part of an existing turn
		#then we should do nothing here until a new turn is started
		#will need to add the headset turning to get this 100% accurate for the actual headset situation
		if(counter_reset > 5):
			counter_reset = 0
			print("reset turn")
			rotate(Vector3(0, 1, 0), TAU/max_extra_turn)
	elif(current_rotation == lastBasis):
		print("same as last frame")
		counter_reset += 1

	
	
	#compute the new position to turn to
	#turn to position decided
	
	#rotate_y(0.01)
	lastBasis = current_rotation
	pass
