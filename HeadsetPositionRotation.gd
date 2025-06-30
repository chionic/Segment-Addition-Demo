extends XROrigin3D

var headset_space #keeps track of the transform attached to the camera that is the virtual representation of the headset
var prev_position #keeps track of the relevant part of the transform (bais.x - turning left/right) from the previous frame

#var turning_sphere #for debugging purposes only - a blue sphere that appears in the center of the users vision when they are currently turning
const refVector = Vector3(0,-1,0) #used to check cross product result against (decided if cw/ccw)
var isTurning #bool value true if user is currently turning, false if not
var endTurn #counter that counts up how many frames in a row the user rotation has been less than the rotation threshold
	
var rotation_threshold = 0.9999 #alter this to change the 'sensitivity' level of the turn
#should be 0.9999, lowered for testing purposes
# the threshold number for how much rotation counts as 'turning' (see comment below for details) - basically
#the more 9s the more sensitive to smaller changes in head direction the rotation threshold is
	#0.9999 gives a near constant sphere when the player is actually turning
	#0.999 gives a flickery sphere when turning (both pick up on tiny head movements, so slight I wouldn't necessarily even call it a turn
	#- when focussing on an object, the sphere doesn't show up)
	#0.99 gives very consistent turn direction at the cost of fewer events overall - if someone is turning slowly enough may not register at all
	# with the new system - 0.9999 recognises most turns of moderate to high speed
	# slow turns aren't registered though - might want to calibrate for average turn speed of players here

var turnEndedThreshold = 15 #how many frames in a row the user has to stay still/not reach the turn threshold for the turn to be considered done
var first = true
signal isRotating #a signal (see observer pattern) that lets other scripts know when the user starts (and possibly stops) rotating
		# 1 = CW turn, -1 = CCW turn, 0 = not turning/turn ended

var ray
var ray2


#logging system reference
var logger
var goalCube
var goalCylinder
#var testObject #remove after use

# Called when the node enters the scene tree for the first time.
func _ready():
	endTurn = 0
	isTurning = false
	#turning_sphere = $XRCamera3D/isTurning
	headset_space = $XRCamera3D
	
	goalCube = get_parent().find_child("StitchDisk", true).find_child("forest_5_6").find_child("GoalCube", true)
	goalCylinder = get_parent().find_child("StitchDisk", true).find_child("forest_5_18").find_child("GoalCylinder", true)
	prev_position = headset_space.transform.basis.x
	logger = get_parent().get_child(-1)
	pass # Replace with function body.


#checks if the user has rotated in the x axis since the last frame and emits signals when the user starts/stops rotating
func _process(_delta):
	if(first):
		first = !first
		prev_position = headset_space.transform.basis.x
	#gets the relevant rotation axis of the headset in the current frame, ie which way left/right the headset is currently facing
	var rot = headset_space.transform.basis.x 
	logger.logB("Change in position: " + str(prev_position.dot(rot)) + " | Angle to Cube: " + str(snapped(checkAngleBetween(goalCube), 0.01))
	+" | Angle to Cylinder: " + str(snapped(checkAngleBetween(goalCylinder), 0.01)) + " | Transform: " + str(headset_space.transform))
	#the dot product gives us a numeric representation of the difference between two vectors
	#1 = they are facing the same direction, 0 = they are 90 degees separate from each other
	#this line checks if the user has rotated more than the rotation_threshold since the last frame
	if(prev_position.dot(rot) < rotation_threshold):
		#if the user has begun rotating, we want to reset the counter to be the start of a turn (or simply if there was a very small pause
		#in the rotation, that it doesn't count as a new rotation)
		endTurn = 0 
		#push_warning(endTurn)
		if(!isTurning): #if we're not already in a turn then we want to emit a signal to say that the turn started and which direction moving
			logger.logB("Started or resumed turn")
			var cross_product = prev_position.cross(rot)
			var direction = refVector.dot(cross_product)
			if(direction < 0):
				#turning in ccw direction (want to emit positive cus we want other object to rotate in OPPOSITE direction of turn)
				isRotating.emit(1)
			elif(direction > 0):
				#turning in cw direction (want to emit negative cus we want other object to rotate in OPPOSITE direction of turn)
				isRotating.emit(-1)
			#debugging line - a blue sphere shows up to let me know when I'm turning in vr - turn this off before any actual builds
			#turning_sphere.show()
			isTurning = true
	else:
		#adds one to endTurn for each frame the user is NOT rotating
		endTurn+=1
		#push_warning(endTurn)
		
	#if the user hasn't turned for turnEndedThreshold frames in a row (right now 15), and the user was turning before,
	# stop the turn	
	if(endTurn > turnEndedThreshold and isTurning):
		#push_warning("end turn threshold reached")
		logger.logB("Paused or ended turn | Angle to Cube: " + str(snapped(checkAngleBetween(goalCube), 0.01)) 
		+" | Angle to Cylinder: " + str(snapped(checkAngleBetween(goalCylinder), 0.01)) + " | Transform: " + str(headset_space.transform))
		isTurning = false
		#signal to say turn ended, useful for changing the location of objects after the user has completed their turn
		isRotating.emit(0)
		#debugging line - remove this for actual builds
		#turning_sphere.hide()
	prev_position = rot
	pass
	
#checks if the user can see an object in space - assumes 180 degree fov across
#change the angle_to to change the min direction the user has to face to be considered as seeing the object
#returns if the user can (true) or can't (false) see the object
func canSeeObject(ob):
	#https://docs.godotengine.org/en/stable/tutorials/3d/using_transforms.html
	var direction = ob.transform.origin - headset_space.transform.origin
	direction = direction.normalized()
	var angle_to = direction.dot(headset_space.transform.basis.z)
	#Because direction was normalized, angle_to will be between 1.0 (dead ahead) and -1.0 (180 degrees, directly behind). 
	if angle_to > 0:
		#push_warning("NOT facing ", ob, angle_to)
		return false
		
	else:
		#push_warning("facing ", ob, angle_to)
		return true
		

#checks the relative position of the goal object (TO THE ORIGIN!) and the headset z rotation axis
#threshold gives a rough estimate of how much either side of the object the user can see before it is considered outside of fov
func check_if_facing(ob, threshold):
	var dir = ob.global_transform.origin.normalized()
	var z = dir.dot(-headset_space.transform.basis.z.normalized())
	if(z >= threshold):
		#print(dir, z, " ", ob)
		return true
	else:
		#print(dir, z, " ", ob)
		return false
	
#finds the angle between the direction the user is facing and the object given into the method	
func checkAngleBetween(ob):
	var dir = ob.global_transform.origin.normalized()
	var a = dir.signed_angle_to(-headset_space.transform.basis.z.normalized(), Vector3.UP)
	return rad_to_deg(a)
	#print("signed angle between the two vectors: ", a, "    ", rad_to_deg(a))

#checks the relative position of the goal object (TO THE ORIGIN!) and the headset z rotation axis
#the signed angle is used along with the direction to choose when the goal is the right amount away
# (see drawings for reference)
func find_goal(ob, direction):
	var player_dir = ob.global_transform.origin.normalized()
	var a = player_dir.signed_angle_to(-headset_space.transform.basis.z.normalized(), Vector3.UP)
	if(direction == 1):
		if((a > 0 and a <= 2.4) or (a <0 and a>-0.9)):
			#push_warning("returned true for inputs ", direction, " ", ob," ", a)
			return true
		else:
			#push_warning("returned false for inputs ", direction, " ", ob, " ", a)
			return false
	elif(direction == -1):
		if((a < 0 and a >= -2.4) or (a > 0 and a<0.9)):
			#push_warning("returned true for inputs ", direction, " ", ob, " ", a)
			return true
		else:
			#push_warning("returned false for inputs ", direction, " ", ob," ", a)
			return false
	return false
