extends Node3D


@export var sliceList = [] #contains list of slices that are in the disk at the beginning of the scene
var count = 1
var scene = [3,2,1]
# 3 slice = 0.59 radians ~ 33 degrees, 2 slice = 0.392 radians ~ 22 degrees, 1 slice = 0.195 radians ~ 11 degrees
var sliceRadians = [0.5876, 0.392, 0.208] #0.58, 0.195
var directionSignal #signal to let us know when user is turning or not
var extraSlices = []

#keeps track of where in the circle the starting slice is (ie the offset in radians of segment33)
var startOffset = 0

##variable to choose which slice to start adding additional slices next to, and which slice to finish with adding slices
#var startSlice = 1
#var endSlice = 7
var startEnd
var goalCube
var goalCylinder

var user
var logger #keeps track of the log file script
var visNote #ref to Visibility handler that keeps track of which nodes are visible/invisible in the slices
var firstTurn = 0
var firstHiddenSliceIndex = -1
var lastDir = 0
var stopAdding = 0

#Doesn't allow slice addition until the last rotation has cleared the previously added slices
var lastRotationCleared = true

#the time when the user started the turn (counts up from when the application first started running)
var startTurnMilliseconds
#the amount (in radians) that the user had to turn in the given direction to complete the turn
var additionalTurnAmountA

# Called when the node enters the scene tree for the first time.
#populates the slice list with the slices already in the scene (aka 'original slices')
#preloads the assets (extra slices) we will be adding later
#sets up the signal that lets us know when the user has started or stopped turning
#sets up our two goals and a reference to the user for future use
func _ready():
	var sliceCount = 0
	#an example of calling a method in another script
	#var x = $SliceList/Segment34.returnNodeRadians() #get_child(1)
	push_error(self)
	for segment in self.get_children():
		sliceList.append(segment)
		sliceCount+=1
	scene[0] = preload("res://StitchDiskScenes/TestSlices/segment33.tscn")
	scene[1] = preload("res://StitchDiskScenes/TestSlices/segment22.tscn")
	scene[2] = preload("res://StitchDiskScenes/TestSlices/segment11.tscn")
	directionSignal = get_parent().get_child(0).isRotating
	directionSignal.connect(addSlicesTest)
	goalCube = self.find_child("LookAtCube", true)
	goalCylinder = self.find_child("LookAtCylinder", true)
	#print(goalCube, " ", goalCylinder)
	user = get_parent().get_child(0)
	logger = get_parent().get_child(-1)
	visNote = get_parent().get_child(1)
	visNote.createCurrSeen(sliceList.size())
	#print("VIS NOTE ", visNote)
	#addSlicesTest(1)
	
#test function that just adds smaller slices between every single existing slice	
func addSlicesTest(direction):
	
	#if the user has started a rotation...
	if((direction == -1 or direction == 1) and firstTurn > 1 and lastRotationCleared): # and firstTurn <= 4):
		logger.addToLog("Started Rotation | " + str(direction) + " | ------------------------------------------------------------------------------------------------------------------\n" )
		startTurnMilliseconds = Time.get_ticks_msec()
		lastDir = direction
		lastRotationCleared = false
		#grab the first and last slice they can see as well as their goal slice
		startEnd = findSliceUserCanSeeAlt(direction)
		push_error("Start: ", startEnd[0], " Goal: ", startEnd[1], " End: ", startEnd[2])
		
		if(startEnd[0] != startEnd[1]):
			var totalMove = moveOverAddRelative(startEnd[0], sliceRadians[2], startEnd[1], direction)
			stopAdding = arrayRotation(startEnd[1], startEnd[1],-direction)
			moveOver(startEnd[1],startEnd[2], direction) #first input: startEnd[1]-direction

	if(direction == 0 and lastDir != 0):
		#check if turn complete or close to it (can see goal slice)
		#if so remove slices
		var goalSlice = sliceList[startEnd[1]].get_child(1)
		var xy = user.check_if_facing(goalSlice,0.85) #0.8
		if(xy):
			lastRotationCleared = true
			removeSliceFromList()
			var turnAmount = arrayRotation(startEnd[2], startEnd[2], -lastDir) 
			var returned = unhideSlices(lastDir)
			if( returned != -1):
				turnAmount = returned
				print("last unhidden slice used as input index: ", turnAmount)
			else:
				print("slice past no turn slice used as starting index ", turnAmount)
			print("about to enter rotation with ", turnAmount)
			rotateAllSlices(lastDir, turnAmount, stopAdding)
			var turnTime = Time.get_ticks_msec() - startTurnMilliseconds
			var averageTurnSpeed = (PI + additionalTurnAmountA)/ (float(turnTime)/1000)
			logger.addToLog("Completed Rotation | " + str(lastDir) + " | Total Turn time: " + str(turnTime/1000)
			+ "seconds | Average turn speed: " 
			+ str(snapped(averageTurnSpeed, 0.001)) + "radians/second | ------------------------------------------------------------------------------------------------------------------\n" )
			lastDir = 0
		else:
			logger.addToLog("Paused Mid-rotation | " + str(visNote.currSeen) + " | Direction: " + str(lastDir) 
			+ " | Goal: " + str(startEnd[1]) + " | Angle to 2: " + str(user.checkAngleBetween(goalCube))
			+ " | Angle to 8: " + str(user.checkAngleBetween(goalCylinder)))
		#B
		#check for slices out of view, remove those and only those
		#not quite working - unhiding seems to work ok, mover over not so much
		#and also multiple move overs before turn completes add to the mess
		#needs proper debugging but might be better to do a different day/time
#		else:
#			print("Entered into stopped turn else")
#			var startEndInter = findSliceUserCanSeeAlt(lastDir)
#			var turnAmount = arrayRotation(startEndInter[2], startEndInter[2], -lastDir) 
#			var returned = unhideSlices(lastDir)
#			if( returned != -1):
#				turnAmount = returned
#			moveOver(turnAmount,startEndInter[2],lastDir) #startEndInter
#			print("StartEndInter: ", startEndInter, " turnAmount: ", turnAmount, " returned: ", returned)

		
	firstTurn += 1

#adding/removing slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
#creates a new slice to put in between the other slices	
func addSliceToList(sliceType, index, lastSlice, dir):
	#create a new slice
	var instancedScene = scene[sliceType].instantiate()
	#make it a child of the node this script is attached to (stitchDisk)
	add_child(instancedScene)
	#set it to be just below the regular slices (less awful patterns when they overlap, too little to be noticed)
	#rotate it to fit into the gap left
	instancedScene.transform.basis = lastSlice.transform.basis
	if(dir == 1):
		instancedScene.rotate_y((sliceRadians[0]))
	else:
		instancedScene.rotate_y(-0.195)
	instancedScene.transform.origin = Vector3(0,-1.5,0) #-0.502
	#add the width of this slice to the amount we want to rotate in future
	#print("total radians after slice list: ", totalRadians)
	#add slice to sliceList (does seem to work now - called segment11, Node3D@6, Node3D@7)
	#sliceList.insert(index, instancedScene)
	#add it to the list of extra slices
	extraSlices.append(instancedScene)
	
func removeSliceFromList():
	count = 0
	while(extraSlices.size() > count):
		#print(slice.get_child(0).get_child(1))
		var slice = extraSlices[count]
		if(!user.check_if_facing(slice.get_child(0).get_child(1),0.85)):
			extraSlices.erase(slice)
			slice.queue_free()
		else:
			count+=1

			
func moveOverAddRelative(index, addedSliceAmount, stopMoving, dir):
	var count = 1
	if(index != stopMoving):
		var currSlice = index #arrayRotation(index, index, dir) #index #
		var prevSlice =  arrayRotation(index, index, -dir) #index #
		var stopMoving2 = stopMoving #arrayRotation(stopMoving, stopMoving, dir)
		while(currSlice != stopMoving2 && currSlice != -1 && count <= 4):
			if(dir == -1):
				addSliceToList(2, prevSlice, sliceList[prevSlice],dir)
			elif(dir == 1):
				addSliceToList(2, currSlice, sliceList[arrayRotation(currSlice, currSlice, -1)], dir)
			sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
			sliceList[currSlice].rotate_y((0.5876 + 0.195) * dir)
			#sliceList[currSlice].transform.origin.y += 6
			prevSlice = currSlice
			currSlice = arrayRotation(index, currSlice, dir)
			count+=1
		additionalTurnAmountA = (0.195 * (count))
		logger.addToLog("Start Addition slice: " + str(index) + " | Stop moving slice: " 
		+ str(stopMoving) + " | Last slice added after: " + str(prevSlice) + " | Number slices added: " + str(count)
		+ " | Added Rotation Radians: " + str(additionalTurnAmountA) + " | Added Rotation Degrees: " + 
		str(rad_to_deg(additionalTurnAmountA)) + " | Total Rotation Radians: " + str(PI + additionalTurnAmountA))
		if(count == 5): #5
			return arrayRotation(stopMoving, stopMoving, dir)
	return stopMoving

#moves the remaining slices over until the stopping point is reached (the point at which the player can see the world)
#if any of the slices would intersect with the space the player can see, the slice is hidden
#might want to add a 'filler slice' down the road
func moveOver(index, stoppingPoint, dir):
	push_warning("Index: ", index, " stopping point: ", stoppingPoint, " direction: ", dir)
	var goalSlice = index;
	if(index != stoppingPoint):
		var isOverlapping = false
		var firstSlice = true
		#print("entered move over ", amount, " index ", index, " stoppingPoint ", stoppingPoint)
		var currSlice = index
		var prevSlice = arrayRotation(index,index, -dir)
		firstHiddenSliceIndex = arrayRotation(stoppingPoint, stoppingPoint, dir)
		while(currSlice != -1  and currSlice != stoppingPoint):
			push_warning("curr Slice: ", currSlice, " stoppingPoint: ", stoppingPoint, " direction: ", dir)
			sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
			sliceList[currSlice].rotate_y(0.5876*dir)
			#sliceList[currSlice].transform.origin.y += 0.1
			#sliceList[currSlice].addToAngle(amount)
			if(isOverlapping): # and index != goalSlice):
				sliceList[currSlice].hide()
				push_error("Hidden slice: ", currSlice)
				#sliceList[currSlice].transform.origin.y += 6
			elif(isPastBoundary(stoppingPoint, currSlice, dir)):
				#print("ENTERED INTO OVERLAP currSlice: ", currSlice, " stopping point: ", stoppingPoint)
				push_error("First Hidden slice: ", currSlice)
				sliceList[currSlice].hide()
				firstHiddenSliceIndex = currSlice
				#sliceList[currSlice].transform.origin.y += 6
				isOverlapping = true
			prevSlice = currSlice
			currSlice = arrayRotation(stoppingPoint, currSlice, dir)

#makes all slices visible if any were invisible, then gives the index of the last hidden slice that was unhidden		
func unhideSlices(direction):
	var temp = firstHiddenSliceIndex
	var lastRotation = -1
	print(temp)
	while(firstHiddenSliceIndex != -1 and !sliceList[firstHiddenSliceIndex].is_visible()):
		#print("entered if")
		sliceList[firstHiddenSliceIndex].show()
		#sliceList[firstHiddenSliceIndex].transform.origin.y += 0.05 #used for debugging to show which slice is up
		lastRotation = firstHiddenSliceIndex
		firstHiddenSliceIndex = arrayRotation(temp, firstHiddenSliceIndex, direction)
#	if(lastRotation == -1):
#		lastRotation = firstHiddenSliceIndex
#		print("entered scenario where no slices were hidden. The starting turn slice angle is ", lastRotation,
#		"the index of the 'hidden' slice is ", firstHiddenSliceIndex)
	return lastRotation
	
#Note: between two moved slices this works pretty well
#issues arise near the beginning where slices don't seem to rotate properly after the last unhidden slice
#leading to the area not being covered properly (ie being a 3 slice short) or moving the first three slice too much
func rotateSlice(currSlice, direction, lastSlice):
	#print("entered rotate slice with currSlice ", currSlice, " direction ", direction, " and lastSlice ", lastSlice)
	if(currSlice != -1 and lastSlice != -1):
		sliceList[currSlice].transform.basis = sliceList[lastSlice].transform.basis
		sliceList[currSlice].rotate_y(sliceRadians[0] * direction) #0.59 if you want slight gap for debugging
		#sliceList[currSlice].transform.origin.y += 3 + c #used for debugging
		
func rotateAllSlices(direction, firstCorrectlyRotatedSlice, stoppingSlice):
	#var count = 0 # used for debugging - makes each consecutive slice a little higher up
	#print("started all slice rotation")
	var index = arrayRotation(firstCorrectlyRotatedSlice, firstCorrectlyRotatedSlice, direction)
	while(index != stoppingSlice and index != -1):
		rotateSlice(index, direction, firstCorrectlyRotatedSlice)
		firstCorrectlyRotatedSlice = index
		index = arrayRotation(stoppingSlice, index, direction)
		#count += 0.5 # used for debugging - makes each consecutive slice slightly higher up
	#print("ended all slice rotation")
	
func rotatePartialSlices(direction, firstCorrectlyRotatedSlice, stoppingSlice):
	var index = arrayRotation(firstCorrectlyRotatedSlice, firstCorrectlyRotatedSlice, direction)
	while(index != stoppingSlice and index != -1):
		rotateSlice(index, direction, firstCorrectlyRotatedSlice)
		firstCorrectlyRotatedSlice = index
		index = arrayRotation(stoppingSlice, index, direction)
	
	

#End adding removing slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Finding Slice ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~      
#returns a list of the last slice the user can see, the goal slice and the first slice the user can see given the direction of their turn      
func findSliceUserCanSee(dir):
	#finds our goals slices - helps narrow down where to start searching for slices we can see
	var startOb = getGoal(dir)
	var prevSlice = startOb[0] #the slice we are currently closer to facing of the two goal slices
	#push_error("started prevSlice with ", startOb[0])
	#grab a slice the user can see
	while(prevSlice != -1 and !user.check_if_facing(sliceList[prevSlice].get_child(1),0.8)):
		prevSlice = arrayRotation(startOb[0], prevSlice, dir)
	if(prevSlice == -1):
		push_error("REACHED -1 - NO SLICE SEEN APPARENTLY")
		push_error("Goal slice currently closer to: ", startOb[0], " goal slice heading towards ideally: ", startOb[1])
		prevSlice = startOb[0]
	var baseSlice = prevSlice
	prevSlice = (prevSlice + dir) % sliceList.size()
	if(prevSlice == -1):
		prevSlice = sliceList.size()-1
#    push_error("found baseSlice ", baseSlice, " prevSlice is ", prevSlice)
	#go from this slice towards our goal based on the direction given, until we can't see the slice anymore
	while(user.check_if_facing(sliceList[prevSlice].get_child(1),0.8) ):
#        push_error(prevSlice, " in find end of known slices")
		if(prevSlice == -1):
			push_error("PREVSLICE IS -1 AS INPUT!!!!!!!! when finding the end of known slices")
			return [0,0,0]
		prevSlice = arrayRotation(baseSlice, prevSlice, dir)
	var canMoveSlice = prevSlice
	push_warning(canMoveSlice)
	#go from the slice we definitely can see away from our goal slice based on the direction given, until we can't see the slice anymore
	prevSlice = (baseSlice - dir) % sliceList.size()
	if(prevSlice == -1):
		prevSlice = sliceList.size() -1
	while(user.check_if_facing(sliceList[prevSlice].get_child(1),0.8) ):
		if(prevSlice == -1):
			push_error("PREVSLICE IS -1 AS INPUT!!!!!!!! when finding the beginning of known slices")
			return [0,0,0]
		prevSlice = arrayRotation(baseSlice, prevSlice, -dir)
	#push_error("start moving slice: ", canMoveSlice, " goal slice ", startOb[1], " don't rotate slice: ", prevSlice, " direction", dir)
	#push_error("SIGNALS: firstSlice ", visNote.firstSeen, " lastSlice ", 
	#			visNote.lastSeen, " backupFirst ", visNote.backupFirst, " backupLast ", visNote.backupLast)
	#push_error("SIGNALS: ", visNote.findVisible())
	#push_error("SIGNALS: ", visNote.currSeen)
	if(prevSlice == -1):
		push_error("PREVSLICE IS -1 AS INPUT!!!!!!!! after trying to find beginning slice")
		return [0,0,0]
	return [canMoveSlice, startOb[1], prevSlice]
	
#alternate way of finding slices that relies on signals rather than loops
func findSliceUserCanSeeAlt(dir):
	var start
	var end
	var startOb = getGoal(dir)
	var startEnd = visNote.findVisible()
	if(dir == 1):
		start = startEnd[1]
		end = startEnd[0] - dir
		push_warning("entered 1 start", start, " end", end)
		if(start < end or abs(start - end) > 5):
			push_warning("entered ", start, " < ", end)
			start = startEnd[0]
			end = startEnd[1] - dir
	else:
		start = startEnd[0]
		end = startEnd[1] - dir
		push_warning("entered -1 start", start, " end", end)
		#hard coding values.... 5 slices is the abs max users should be seeing
		if(end < start or abs(end - start) > 5 ):
			push_warning("entered ", end, " < ", start)
			start = startEnd[1]
			end = startEnd[0] - dir
	if(end < 0):
		end = 10
	if(end > 10):
		end = 0
	var temp = [start, startOb[1], end]
	logger.addToLog("The slices are: " + str(temp) + " | Visible slices: " 
	+ str(visNote.currSeen) + " | direction: " + str(dir))
	return temp
		

	
#check if user is facing either current goal slice - with a threshold of 0 set, it will guarantee one or the other goal slice
#returns first the slice of the goal we are currently closer to, then the presumed end point of the goal slice
#Edge case: Both slices are at exactly the edge of awareness, equal distance away. In that case b will be returned as it is considered first
#which is fine, since both could be valid goals at that point - this should never happen with the restrictions of the experiment anyway
func getGoal(direction):
	var a = user.find_goal(goalCube, direction)
	#push_warning("Can see goalCube: ", a, " ", direction)
	#print(goalCube.get_parent(), " ", a, goalCube.transform.basis)
	var b = user.find_goal(goalCylinder, direction)
	#push_warning("Can see goalCylinder: ", b, " ", direction)
	#print(goalCylinder, " ", b)
	if(b):
		#						currently facing goal
		#return [sliceList.find(goalCube.get_parent()), sliceList.find(goalCylinder.get_parent())]
		return [sliceList.find(goalCylinder.get_parent()), sliceList.find(goalCube.get_parent())]
	elif(a):
		#return [sliceList.find(goalCylinder.get_parent()), sliceList.find(goalCube.get_parent())]
		return [sliceList.find(goalCube.get_parent()), sliceList.find(goalCylinder.get_parent())]
	else:
		push_error("NO GOAL SLICE FOUND, DEFAULTING TO GOALCYLINDER SCENARIO")
		return [sliceList.find(goalCylinder.get_parent()), sliceList.find(goalCube.get_parent())]
	pass
#end finding slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#array rotation methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#gets the next index in an array rotation based on the current index, the starting index and the direction
func arrayRotation(startValue, currValue, direction):
#    push_warning("array rotation ran with inputs ", startValue, " dir ", direction, " curr value", currValue)
	if(direction == 1):
		if(startValue -1  == currValue or (startValue == 0 and currValue >= sliceList.size() - 1)):
			push_warning("rotated to end of array -1  ", startValue, "    ", currValue, "   ", direction)
			return -1
		currValue += 1
		if(currValue >= sliceList.size()):
			currValue = 0
	elif(direction == -1):
		if(startValue +1  == currValue):
			push_warning("rotated to end of array -1  ", startValue, "    ", currValue, "   ", direction)
			return -1
		currValue -= 1
		if(currValue < 0):
#            push_error("entered if")
			currValue = sliceList.size() - 1
	#push_warning("array rotation ran with output ",currValue)
	#push_warning(currValue)
	return currValue
	
#similar to array rotation above, except we can set a custom end value and step size    
func partialArrayRotation(startValue, endValue, currValue, direction, step):
	#push_warning("entered  partial rotation with currValue ", currValue)
	if(startValue > endValue):
		endValue += sliceList.size()
		#step method is only guaranteed to have an end point for steps of 1 and 2 currently
	if(endValue == currValue || endValue == currValue + 1):
		return -1
	elif(direction == 1):
		currValue += step
		if(currValue >= sliceList.size()):
			currValue = currValue % sliceList.size()
		return currValue
	elif(direction == -1):
		currValue -= step
		if(currValue < 0):
			currValue = sliceList.size() - step
	return currValue
	
func isPastBoundary(testSlice, inputSlice, dir):
	#push_error("Euler angles inputSlice: ", sliceList[inputSlice].transform.basis.get_euler()[1])
	#push_error("Euler angles testSlice: ", sliceList[testSlice].transform.basis.get_euler()[1])
	if(dir == 1):
		var upperBound = (sliceList[inputSlice].transform.basis.get_euler()[1] + 0.5)
		if(upperBound > 2*PI):
			upperBound -= (2*PI)
		var lowerBound = sliceList[inputSlice].transform.basis.get_euler()[1] - 0.3
		if(lowerBound < 0):
			lowerBound = lowerBound + (2*PI)
		if(sliceList[testSlice].transform.basis.get_euler()[1] < upperBound and 
		sliceList[testSlice].transform.basis.get_euler()[1] > lowerBound):
			return true
		elif(lowerBound > upperBound and (sliceList[testSlice].transform.basis.get_euler()[1] > lowerBound or 
		sliceList[testSlice].transform.basis.get_euler()[1] < upperBound)):
			return true
		return false
	elif(dir == -1):
		var upperBound = (sliceList[testSlice].transform.basis.get_euler()[1] + 0.3)
		if(upperBound > 2*PI):
			upperBound -= (2*PI)
		var lowerBound = sliceList[testSlice].transform.basis.get_euler()[1] - 0.5
		if(lowerBound < 0):
			lowerBound = lowerBound + (2*PI)
		if(sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound and 
		sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound):
			return true
		elif(lowerBound > upperBound and (sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound or 
		sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound)):
			return true
		return false
	return false
#End Array rotation methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
