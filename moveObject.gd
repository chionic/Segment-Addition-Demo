extends MeshInstance3D

var directionSignal #signal to let us know when user is turning or not
var maxRotationInRadians = 0.53 #1 Radian = 57.2958 degrees, 0.5 radians = 28.6479, how much object rotates each turn
var orientAfter = false #decides if object should change position once a turn is complete to keep it's relative position to the other objects
var lastDirection #keeps track of the previous amount the OTHER objects were rotated in and which way this object should move to compensate
var correction = 0 #if this object is visible for multiple turns, stores all the lastDirections as a single final correction to do

# Called when the node enters the scene tree for the first time.
func _ready():
	directionSignal = get_parent().get_parent().get_child(0).isRotating
	directionSignal.connect(moveObject)
	#push_error(directionSignal)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	#rotates object quickly in a circle around central rotator (point 0,0,0)
	#get_parent().rotate(Vector3(0,1,0), 0.1)
	pass

#when a signal is received should do the following:
#if the player has this object as a goal:

	#find where this obstacle is in relation to the player
	#rotate around the player by max degrees in the direction of the players rotation
#if the player has another object as a goal:
	#once this object is outside the players viewport either reset the object to it's original ideal location or to it's correct position relative to the other obstacles
	#(still need to decide which is better for it) - if not implemented
	
#Function that moves the objects around the origin as the player rotates
#if the player can see the object at the start of the turn, it doesn't move
#if the player CAN'T see the object at the start of the turn, it is moved to increase the angular distance between it and the other objects
#in the direction the user is turning
#orientAfter, lastDirection and correction are used to orient all the objects relative to each other accurately again after the turn has been completed
func moveObject(input):
	var canSee = get_parent().get_parent().get_child(0).canSeeObject(self)
	if(canSee):
		if (input == 0 && orientAfter == true):
			correction += lastDirection
		else:
			orientAfter = true
			lastDirection = input * maxRotationInRadians
		#push_warning(self, " NOT rotated")
		# the player is facing the object, shouldn't move it
		#get_parent().rotate(Vector3(0,1,0), 0.5 * input)
		pass
	else:
		if(input == 0 && orientAfter == true):
			#turn completed, want to move object to be opposite current other object
			push_warning(self, " rotation correction")
			get_parent().rotate(Vector3(0,1,0), correction)
			correction = 0
			orientAfter = false
			pass
		
		#the player is not facing the object, it should be moved
		elif(input != 0):
			push_warning(self, " rotated")
			get_parent().rotate(Vector3(0,1,0), maxRotationInRadians * input)
		pass
	
#method to test if signals works, assumes one input but you can change it to multiple as needed.	
func testMethod(input):
	push_warning(input, " received signal")
	pass
		
	
