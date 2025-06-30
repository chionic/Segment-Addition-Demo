extends XROrigin3D


var headset_space #keeps track of the transform attached to the camera that is the virtual representation of the headset
var prev_position #keeps track of the relevant part of the transform (bais.x - turning left/right) from the previous frame

#var turning_sphere #for debugging purposes only - a blue sphere that appears in the center of the users vision when they are currently turning
const refVector = Vector3(0,-1,0) #used to check cross product result against (decided if cw/ccw)
var isTurning #bool value true if user is currently turning, false if not
var endTurn #counter that counts up how many frames in a row the user rotation has been less than the rotation threshold
	
var rotation_threshold = 0.9999# the threshold number for how much rotation counts as 'turning' (see comment below for details) - basically
#the more 9s the more sensitive to smaller changes in head direction the rotation threshold is
	#hard to say which is better here - 0.9999 gives a near constant sphere when the player is actually turning
	#0.999 gives a flickery sphere when turning (both pick up on tiny head movements, so slight I wouldn't necessarily even call it a turn
	#- when focussing on an object, the sphere doesn't show up)
	#0.99 gives very consistent turn direction at the cost of fewer events overall - if someone is turning slowly enough may not register at all
	# with the new system - 0.9999 recognises most turns of moderate to high speed
	# slow turns aren't registered though - might want to calibrate for average turn speed of players here
var player_vars #singleton ref

var turnEndedThreshold = 15 #how many frames in a row the user has to stay still/not reach the turn threshold for the turn to be considered done
var first = true
#logging system reference
var logger
var questionnaire
var q2
var goalCube
var goalCylinder
var cube
var cylinder
##var uiHookCy
#var uiHookCu
var cu = false
var cy = false
var dir = 0

var chosenRotationAmount = 1.5
var testTurn = true #set when a new turn is started, so that only once a turn is finished do the cylinder/cube move again
var second = 0
#var testObject #remove after use

#the time when the user started the turn (counts up from when the application first started running)
var startTurnMilliseconds

var possibleRadianAmounts = [0.19548, 0.39096, 0.58644, 0.78192, 0.9774, 1.17288,
							0.19548, 0.39096, 0.58644, 0.78192, 0.9774, 1.17288,
							-0.19548, -0.39096, -0.58644, -0.78192, -0.9774, -1.17288,
							-0.19548, -0.39096, -0.58644, -0.78192, -0.9774, -1.17288, 0 ,0 ,0 ,0]
							
var numTurnPauses = -1

var shouldEnd = false #a final turn scenario

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize() #sets up the randomizer which chooses which turn amount to present the user with next
	endTurn = 0
	isTurning = false
	#turning_sphere = $XRCamera3D/turning_sphere
	
	#setting up initial variables
	headset_space = $XRCamera3D
	player_vars = get_node("/root/GlobalVariable")
	goalCube = get_parent().find_child("Rotator", true).find_child("CentreCube", true).find_child("GoalCube", true)
	goalCylinder = get_parent().find_child("Rotator", true).find_child("CentreCylinder", true).find_child("GoalCylinder", true)
	cube = get_parent().find_child("Rotator", true).find_child("CentreCube", true)
	cylinder = get_parent().find_child("Rotator", true).find_child("CentreCylinder", true)
	prev_position = headset_space.transform.basis.x
	logger = get_parent().get_child(-1)
	questionnaire = cylinder.find_child("Questionnaire")
	q2 = cube.find_child("Questionnaire2")
	get_tree().paused = true #pauses the scene while the menu is open.


#checks if the user has rotated in the x axis since the last frame and emits signals when the user starts/stops rotating
func _process(_delta):
	#print(Engine.get_frames_per_second())
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
	if(prev_position.dot(rot) < rotation_threshold and second >= 2):
		#print(prev_position, (rot))
		#if the user has begun rotating, we want to reset the counter to be the start of a turn (or simply if there was a very small pause
		#in the rotation, that it doesn't count as a new rotation)
		endTurn = 0 
		#push_warning(endTurn)
		if(!isTurning): #if we're not already in a turn then we want to emit a signal to say that the turn started and which direction moving
			logger.addToLog("Started or resumed turn")
			startTurnMilliseconds = Time.get_ticks_msec()
			var cross_product = prev_position.cross(rot)
			var direction = refVector.dot(cross_product)
			#push_warning(direction)
			if(direction < 0 and testTurn): #
				#push_warning("entered dir <0")
				dir = 1
				if(possibleRadianAmounts.size() > 0):
					var i = randi_range(0,possibleRadianAmounts.size()-1)
					chosenRotationAmount = possibleRadianAmounts[i]
					possibleRadianAmounts.remove_at(i)
				else:
					chosenRotationAmount = 0
					shouldEnd = true
				#push_warning("random choice: ", chosenRotationAmount) 
				testTurn = false
				#turning in ccw direction (want to emit positive cus we want other object to rotate in OPPOSITE direction of turn)
				#isRotating.emit(1)
				#find the current goal of the user
				if(find_goal(goalCube, 1)):
					#turning_sphere.get_child(0).mesh.material.albedo_color = Color.ANTIQUE_WHITE
					cylinder.rotateChild(1, chosenRotationAmount)
					cu = true
					#push_error("Entered turn with Cube: ", direction, " and ", chosenRotationAmount, "   ",checkAngleBetweenTwo(cube, cylinder))
					logger.addToLog("Started Turn | Can see: Cube | Angle Cube to Headset: "+ str(direction)+ " | Direction: "+ str(dir)+
								" | Goal Cylinder rotated by: "+ str(chosenRotationAmount)+ " | Angle between goals: "+
								str(checkAngleBetweenTwo(cube, cylinder)))
				elif(find_goal(goalCylinder, 1)):
					#turning_sphere.get_child(0).mesh.material.albedo_color = Color.ANTIQUE_WHITE
					cube.rotateChild(1, chosenRotationAmount)
					cy = true
					#push_error("Entered turn with Cylinder: ", direction, " and ", chosenRotationAmount,"   ", checkAngleBetweenTwo(cube, cylinder))					
					logger.addToLog("Started Turn | Can see: Cylinder | Angle Cylinder to Headset: "+ str(direction)+ " | Direction: "+ str(dir)+
								" | Goal Cube rotated by: "+ str(chosenRotationAmount)+ " | Angle between goals: "+
								str(checkAngleBetweenTwo(cube, cylinder)))
				#rotate the goal further away 
			
			elif(direction > 0 and testTurn): # 
				testTurn = false
				#push_warning("entered dir >0")
				dir = -1
				if(possibleRadianAmounts.size() > 0):
					var i = randi_range(0,possibleRadianAmounts.size()-1)
					chosenRotationAmount = possibleRadianAmounts[i]
					possibleRadianAmounts.remove_at(i)
				else:
					chosenRotationAmount = 0
					shouldEnd = true
				#startTurnMilliseconds = Time.get_ticks_msec()
				#turning in cw direction (want to emit negative cus we want other object to rotate in OPPOSITE direction of turn)
				if(find_goal(goalCube, -1)):
					#turning_sphere.get_child(0).mesh.material.albedo_color = Color.BLACK
					cylinder.rotateChild(-1, chosenRotationAmount)
					cu = true
					#push_error("Entered turn with Cube: ", direction, " and ", chosenRotationAmount,"   ",checkAngleBetweenTwo(cube, cylinder))
					logger.addToLog("Started Turn | Can see: Cube | Angle Cube to Headset: "+ str(direction)+ " | Direction: "+ str(dir)+
								" | Goal Cylinder rotated by: "+ str(chosenRotationAmount)+ " | Angle between goals: "+
								str(checkAngleBetweenTwo(cube, cylinder)))
				elif(find_goal(goalCylinder, -1)):
					#turning_sphere.get_child(0).mesh.material.albedo_color = Color.BLACK
					cube.rotateChild(-1, chosenRotationAmount)
					cy = true
					#push_error("Entered turn with Cylinder: ", direction, " and ", chosenRotationAmount, "   ",checkAngleBetweenTwo(cube, cylinder))
					logger.addToLog("Started Turn | Can see: Cylinder | Angle Cylinder to Headset: "+ str(direction)+ " | Direction: "+ str(dir)+
								" | Goal Cube rotated by: "+ str(chosenRotationAmount)+ " | Angle between goals: "+
								str(checkAngleBetweenTwo(cube, cylinder)))
			#debugging line - a blue sphere shows up to let me know when tI'm turning in vr - turn this off before any actual builds
			#turning_sphere.show()
			isTurning = true
	else:
		#adds one to endTurn for each frame the user is NOT rotating
		endTurn+=1
		#push_warning(endTurn)
		
	#if the user hasn't turned for turnEndedThreshold frames in a row (right now 15), and the user was turning before,
	# stop the turn	
	if(endTurn > turnEndedThreshold and isTurning):
		logger.addToLog("Paused or ended turn")
		numTurnPauses += 1
		isTurning = false
		if(cu and check_if_facing(goalCylinder, 0.85)):
			cu = false
			cube.rotateChild(dir, chosenRotationAmount)
			questionnaire.show()
			second = 0
			var turnTime = Time.get_ticks_msec() - startTurnMilliseconds
			var rotationAmount = PI + chosenRotationAmount
			var averageTurnSpeed = (rotationAmount)/ (float(turnTime)/1000)
			#turning_sphere.get_child(0).mesh.material.albedo_color = Color.BLUE_VIOLET
			logger.addToLog("Ended Turn | Facing Goal : Cylinder | Angle between goals: " + str(checkAngleBetweenTwo(cube, cylinder)) +  " | Total Turn time: " + str(turnTime)
			+ " milliseconds | Rotation Amount: " + str(rotationAmount) + " | Average turn speed: " + str(averageTurnSpeed) + " radians/second | Number of times the turn was paused: " + str(numTurnPauses))
			numTurnPauses = -1
			get_tree().paused = true
			#print("entered cube, rotate cylinder, ", checkAngleBetweenTwo(cube, cylinder))
			testTurn = true

		elif(cy and check_if_facing(goalCube, 0.85)):
			cy = false
			cylinder.rotateChild(dir, chosenRotationAmount)
			q2.show()
			second = 0
			#turning_sphere.get_child(0).mesh.material.albedo_color = Color.SKY_BLUE
			var turnTime = float(Time.get_ticks_msec()) - float(startTurnMilliseconds)
			var rotationAmount = PI + chosenRotationAmount
			var averageTurnSpeed = (rotationAmount)/ (float(turnTime)/1000)
			#turning_sphere.get_child(0).mesh.material.albedo_color = Color.BLUE_VIOLET
			logger.addToLog("Ended Turn | Facing Goal : Cube | Angle between goals: " + str(checkAngleBetweenTwo(cube, cylinder)) +  " | Total Turn time: " + str(turnTime)
			+ " milliseconds | Rotation Amount: " + str(rotationAmount) + " | Average turn speed: " + str(averageTurnSpeed) + " radians/second | Number of times the turn was paused: " + str(numTurnPauses))
			numTurnPauses = -1
			get_tree().paused = true
			#push_error("entered cylinder, rotate cube, ", checkAngleBetweenTwo(cube, cylinder))
			testTurn = true
		#debugging lines - remove this for actual builds
		#turning_sphere.hide()
		#push_error("Turn ended ")
	if(possibleRadianAmounts.size() <= 0 && shouldEnd):
		#push_error("went through all turns")
		var turnTime = float(Time.get_ticks_msec()) - float(startTurnMilliseconds)
		var rotationAmount = PI + chosenRotationAmount
		var averageTurnSpeed = (rotationAmount)/ (float(turnTime)/1000)
		#turning_sphere.get_child(0).mesh.material.albedo_color = Color.BLUE_VIOLET
		logger.addToLog("Ended Turn | Facing Goal : Cube | Angle between goals: " + str(checkAngleBetweenTwo(cube, cylinder)) +  " | Total Turn time: " + str(turnTime)
			+ " milliseconds | Rotation Amount: " + str(rotationAmount) + " | Average turn speed: " + str(averageTurnSpeed) + " radians/second | Number of times the turn was paused: " + str(numTurnPauses))
		numTurnPauses = -1
		questionnaire.show()
		q2.show()
		get_tree().paused = true
		player_vars.setEnd()
		#get_tree().quit()
	prev_position = rot
	second += 1
	pass
	
#checks the relative position of the goal object (TO THE ORIGIN!) and the headset z rotation axis
#threshold gives a rough estimate of how much either side of the object the user can see before it is considered outside of fov
func check_if_facing(ob, threshold):
	var dire = ob.global_transform.origin.normalized()
	var z = dire.dot(-headset_space.transform.basis.z.normalized())
	#var a = dir.signed_angle_to(-headset_space.transform.basis.z.normalized(), Vector3.UP)
	#print("signed angle between the two vectors: ", a, "    ", rad_to_deg(a))
	#ray.target_position = ob.global_transform.origin - headset_space.global_transform.origin#Vector3(ob.global_transform.origin.x, 0.2, ob.global_transform.origin.z)
	#ray.target_position = Vector3(dir.x, 0.2, dir.z)
	#ray2.target_position = Vector3(-headset_space.transform.basis.z.x, 0.2, -headset_space.transform.basis.z.z)
	#push_warning("ran check if facing ", threshold, z)
	if(z >= threshold):
		#print(dir, z, " ", ob)
		return true
	else:
		#print(dir, z, " ", ob)
		return false
		
func checkAngleBetween(ob):
	var dir = ob.global_transform.origin.normalized()
	var a = dir.signed_angle_to(-headset_space.transform.basis.z.normalized(), Vector3.UP)
	#specifically for debugging cube/cylinder where the two things face the same direction, 
	#think of it as adding 180 degrees
	a = a * -1 
	return rad_to_deg(a)
	#print("signed angle between the two vectors: ", a, "    ", rad_to_deg(a))
	
func checkAngleBetweenTwo(ob, ob2):
	#vector from origin to cube
	var ob1dir = ob.get_global_transform().basis.z  #ob.global_transform.origin - Vector3(0,0,0)
	#vector from origin to cylinder
	var ob2dir = ob2.get_global_transform().basis.z #ob2.global_transform.origin - Vector3(0,0,0)
	var a = ob2dir.normalized().dot(ob1dir.normalized())
	#var dir = ob1dir.normalized()
	#var a = dir.signed_angle_to(-ob2dir.basis.z.normalized(), Vector3.UP)
	return a #0 = 90degrees, -1 = 180 degrees, 1 = 0 degrees

#checks the relative position of the goal object (TO THE ORIGIN!) and the headset z rotation axis
#the signed angle is used along with the direction to choose when the goal is the right amount away
# (see drawings for reference)
func find_goal(ob, direction):
	var player_dir = ob.global_transform.origin.normalized()
	var a = player_dir.signed_angle_to(-headset_space.transform.basis.z.normalized(), Vector3.UP)
	#push_warning("signed angle between the two vectors: ", a, "    ", rad_to_deg(a))
	#push_warning("direction: ", direction, " angle: ", a, " object checking on: ", ob)
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
	
func find_goal_2(ob1, ob2, direction):
	if(check_if_facing(ob1, 0.7)):
		return ob1
	elif(check_if_facing(ob2, 0.7)):
		return ob2

