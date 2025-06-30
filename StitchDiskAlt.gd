extends Node3D


@export var sliceList = [] #contains list of slices that are in the disk at the beginning of the scene
@export var defaultSlices = [] #slices that are visible by default
@export var hiddenSlices = [] #slices that should be hidden by default

var visibleArray = []
var directionSignal #signal to let us know when user is turning or not

#variable to choose which slice to start adding additional slices next to, and which slice to finish 
#with adding slices
var startEnd

#reference to the goal game objects - suggest where the player is turning to
var goalCube
var goalCylinder

var zeroTurnCount = 0; #counts how many extra zero turns we've had so far

var user #reference to the player/vr headset - contains position info
var logger #keeps track of the log file script
var visNote #ref to Visibility handler that keeps track of which nodes are currently seen by the player
var firstTurn = 1 #is this the first turn? (will skip feedback for this)
var firstHiddenSliceIndex = -1
var lastDir = 0 #the direction of the last turn
var stopAdding = 0 #index of the slice we should stop adding slices to after

#the time when the user started the turn (counts up from when the application first started running)
var startTurnMilliseconds
#the amount (in radians) that the user had to turn in the given direction to complete the turn
var additionalTurnAmountA = 0

#Questionnaires - reference to the UI element that asks about each turn
var questionnaire
var q2

#Doesn't allow slice addition until the last rotation has cleared the previously added slices
var lastRotationCleared = true
#temp variable to have something only happen once - used for debugging so only a specific amount of turns happen
var first = true

#a variable that skips the next rotation start
#used when the game unpauses to stop it choosing a direction based on the head position directly before and after the pause
var skipNext = false

#the last slice that was hidden in the turn
var lastHidden = -1


#saves the goal slice currently facing and the 'end' slice which is the last slice the user can see before
#they start turning
var currFacingGoal = -1
var currFacingEnd = -1
var nextGoal = -1

#variable that keeps track of if we passed the goal slice this turn or not
var pastOriGoal = false

#possible amounts of slices to add
var possibleRadianAmounts = [1, 2, 3, 4,-1, -2, -3, -4,1, 2, 3, 4,-1, -2, -3, -4, 0, 0] #-1, -2, -3, -4, -5, -6, #-1, -2, -3, -4, -5, -6,
							
#these will be prioritised if its possible to use these on a turn
var specialTurnAmounts = [5,-5,5,-5,-6,6,-6,6]

#fall back zeros when the user can only turn 0
var backupZeroes = [0,0]

#stops slices turning after the user turns away from the original goal slice when a negative amount is selected
var chosenNegative = false

var player_vars #singleton ref

var numTurnPauses = -1 #how many mid-turn pauses their were

# Called when the node enters the scene tree for the first time.
#populates the slice list with the slices already in the scene (aka 'original slices')
#preloads the assets (extra slices) we will be adding later
#sets up the signal that lets us know when the user has started or stopped turning
#sets up our two goals and a reference to the user for future use
func _ready():
	#an example of calling a method in another script
	#var x = $SliceList/Segment34.returnNodeRadians() #get_child(1)
	player_vars = get_node("/root/GlobalVariable")
	push_warning("in stitch disk alt player_vars: ", player_vars)
	push_error(self)
	#adds the different slices to the various lists to keep track of them
	for segment in self.get_children():
		sliceList.append(segment)
		#push_warning("Slice: ", segment, " euler angles: ", segment.transform.basis.get_euler()[1], " rotation degrees: ", segment.rotation_degrees)
	for segment in self.get_children():
		if(segment.is_visible()):
			defaultSlices.append(segment)
		else:
			hiddenSlices.append(segment)
			
	#sets up the signal that notifies us when the player starts/stops turning
	directionSignal = get_parent().get_child(0).isRotating
	directionSignal.connect(addSlicesTest)
	visibleArray = printVisibleArray()
	#references to the goal objects, player, logger and visibility handler (keeps track which slices are
	#visible/invisible currently), questionnaire UI game objects
	goalCube = self.find_child("GoalCube", true)
	goalCylinder = self.find_child("GoalCylinder", true)
	user = get_parent().get_child(0)
	logger = get_parent().get_child(-1)
	visNote = get_parent().get_child(1)
	visNote.createCurrSeen(sliceList.size())
	questionnaire = find_child("forest_5_6").find_child("q1")
	q2 = find_child("forest_5_18").find_child("q2")
	questionnaire.show()
	get_tree().paused = true
	
	#print("VIS NOTE ", visNote)
	#addSlicesTest(1)
	
#test function that just adds smaller slices between every single existing slice	
func addSlicesTest(direction):

	#if the user has started a rotation...
	#push_warning("dir: ", direction, " first turn: ", firstTurn, " lastRotationCleared: ", lastRotationCleared)
	if((direction == -1 or direction == 1) and firstTurn > 0 and lastRotationCleared): # and firstTurn < 20
		#push_warning("direction 1 or -1 called")
		if(skipNext): #lskipNext): 
			skipNext = false
			user.isTurning = false
			user.endTurn = 50
			#push_warning("skipNext set to false", " is turning: ", user.isTurning, " end turn: ", user.endTurn)
		else:
			#push_warning("started rotation")
			#push_error("Started rotation, the turn number is ", firstTurn)
			lastRotationCleared = false
			first = true
			logger.addToLog("Started Rotation | Direction: " + str(direction) + " | Visible Slices: " 
			+str(visibleArray) + " | --------------------------------------------------------------------------------------------" )
			startTurnMilliseconds = Time.get_ticks_msec()
			lastDir = direction
			#grab the first and last slice they can see as well as their goal slice
			startEnd = findSliceUserCanSeeAlt(direction)
			nextGoal = startEnd[1]
			#push_error("Start: ", startEnd[0], " Goal: ", startEnd[1], " End: ", startEnd[2], "direction: ", direction)
			
			if(startEnd[0] != startEnd[1]):
				var totalMove = -1
				var chosenExtra = chooseFromList(startEnd[0], currFacingGoal)	
				var maxExtra = maxAddition(startEnd[0], currFacingGoal)
				#push_error("Max slice ", maxExtra , " chosen slice: ", chosenExtra)
				if(chosenExtra >= 0):
					chosenNegative = false
					totalMove = moverOverUnhide(startEnd[0], startEnd[1], direction,chosenExtra)
					#first input: totalMove
					
				elif(chosenExtra < 0):
					chosenNegative = true
					totalMove = moverOverHide(startEnd[0], startEnd[1], direction,-chosenExtra)
				#logger.addToLog(str(visibleArray))
				#push_error("ran moverOverUnhide between slice: ", startEnd[0], " and ", startEnd[1], "total move was: ", totalMove, "and direction ", direction)
				#stopAdding = arrayRotation(totalMove, totalMove,-direction)
				#var totalMove = startEnd[1]
				moveOverAlt(totalMove,startEnd[2], direction, startEnd[1])
				#push_warning("ran totalMove between slices: ", totalMove, " and ", startEnd[2])
				#push_error(printVisibleArray())
				logger.addToLog("Started Rotation | Direction: " + str(direction) + " | Goal Slice: " + str(startEnd[1])
				+ " | start moving slice: " + str(startEnd[0]) + " | stop moving slice: " + str(startEnd[2]) + " | added slice amount: "
				+ str(chosenExtra) + " | max possible addition: " + str(maxExtra) + " | Visible Slices: " + str(visibleArray))

	if(direction == 0 and lastDir != 0):
		#push_warning("direction 0 called")
		#check if turn complete or close to it (can see goal slice)
		#if so remove slices

		# 1. Check if the goal is in view for the player
		var goalSlice = sliceList[startEnd[1]].get_child(2)
		#print("Entered turn pause, GOAL SLICE IS: ", goalSlice, "________________________________________________")
		var xy = user.check_if_facing(goalSlice,0.92) #0.8

		#if it is...
		if(xy and first):
			#setup for next turn
			pastOriGoal = false
			currFacingGoal = -1
			currFacingEnd = -1
			nextGoal = -1
			#push_error("stopped rotation")
			first = false
			lastRotationCleared = true #setup for the next rotation
#			#attempt to make addition slices work better - would need to fundamentally change
#			#how slices addition works to do this however
			removeSliceFromList()
			#push_warning("ran remove slice from list")
			var turnAmount = arrayRotation(startEnd[2], startEnd[2], -lastDir) 
			#push_warning("turn Amount set to: ", turnAmount)
			var lastSeenSlice = visNote.findVisibleEdgeCase2(startEnd[1], lastDir)
			var returned = unhideSliceAlt2(lastDir, lastSeenSlice[0], lastSeenSlice[1])
			if(goalSlice == goalCube):
				#push_warning("Q1 called")
				questionnaire.show()
			else:
				#push_warning("Q2 called")
				q2.show()
			skipNext = true
			#push_warning("skipNext set to true: ")
			get_tree().paused = true
			var turnTime = Time.get_ticks_msec() - startTurnMilliseconds
			var averageTurnSpeed = (PI + additionalTurnAmountA)/ (float(turnTime)/1000)
			logger.addToLog("Completed Rotation | " + str(lastDir) + " | Total Turn time: " + str(float(turnTime)/1000)
			+ "seconds | Average turn speed: " + str(snapped(averageTurnSpeed, 0.001)) + "radians/second |
			num turn pauses: " + str(numTurnPauses) + " |---------------------------------------------------------------------\n\n" )
			numTurnPauses = -1
			lastDir = 0
#		#if the user is not facing the goal slice, log the stop in the middle of the turn
		else:
			numTurnPauses += 1
			logger.addToLog("Paused Mid-rotation | " + str(visNote.currSeen) + " | Direction: " + str(lastDir) 
			+ " | Goal: " + str(startEnd[1]) + " | Angle to Cube: " + str(user.checkAngleBetween(goalCube))
			+ " | Angle to Cylinder: " + str(user.checkAngleBetween(goalCylinder)))
		
	firstTurn += 1

#adding/removing slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~       
func removeSliceFromList():
	#push_warning("entered remove slice from list")
	#goes through the slicees in the hidden slices list (ie those that are meant to be hidden by default
	for slice in hiddenSlices:
		#print(slice.get_child(1))
		#if the slice is currently visible (ie it's possible to see the mesh)
		#But not on screen (ie the player is not currently seeing the mesh)
		if(slice.is_visible() && !slice.get_child(1).is_on_screen()):
			slice.hide() #hide the slice to make it invisible.
			var currSlice = sliceList.find(slice)
			visibleArray[currSlice] = 'H'	
			#push_warning("hid slice ", slice)	
#		elif(slice.get_child(1).is_on_screen()):
#			push_warning("slice ", slice, " was visible on screen and stays unhidden")
#		elif(slice.is_visible()):
#			push_warning(slice, " is visible but not on screen...")


#checks if a given input slice overlaps the goal slice, should be triggered when a slice exits the screen
#should only consider slices between the two goal slices on the slimming side
#and should only consider it if we are currently in a turning phase not a stop phase
func checkOverlapGoal(inputSlice):
	if(chosenNegative):
		return #if slices have been taken away there is no need to change the overlap slices
	#if we are currently in a turning phase and not a stopped phase
	if(!pastOriGoal and !skipNext and !lastRotationCleared):
		#push_warning("currently in turn process ", inputSlice)
		#if between end slice and originally facing goal slice
		if(currFacingGoal != -1 and currFacingEnd != -1):
			if(inputSlice == currFacingGoal):
				#run the second half of the goal slice stuff
				pastOriGoal = true #stop checking for further slices
				#push_error("hit originally facing goal slice")
				if(currFacingGoal != currFacingEnd): #if the last slice we saw was the goal, there is no need to hide that
					sliceList[currFacingEnd].hide()
					visibleArray[currFacingEnd] = 'H'
				#run move over between one slice past our goal slice and the goal slice the user was originally facing
				var totalMove = arrayRotation(startEnd[1], startEnd[1], lastDir)
				#push_error("going to run move over alt with inputs: totalMove - ", totalMove, " currFacingGoal - ", currFacingGoal, " lastsDir - ", lastDir, " and ", startEnd[1])
				moveOverReplace(totalMove,currFacingGoal, lastDir)
				logger.addToLog("Ran OverlapGoal | Visible slices: " +str(visibleArray))
			elif((inputSlice < currFacingGoal and inputSlice > currFacingEnd) or
			(inputSlice > currFacingGoal and inputSlice < currFacingEnd)):
				#push_warning("between curr facing goal ", currFacingGoal, " and curr facing end ", currFacingEnd, " input slice: ", inputSlice)
				sliceList[inputSlice].hide()
				visibleArray[inputSlice] = 'H'
			#check if it overlaps the goal
				#if it does, hide it
	pass
	
# startSlice = startEnd[0], goalsSlice = startEnd[1]	
func moverOverUnhide(startSlice, goalSlice, dir, extraCount):
	#push_warning("Entered mover over unhide")
	var count = 0 #debugging variable
	var unhiddenCount = 0
	if(startSlice != goalSlice):
		#find first hidden slice after startSlice
		var currSlice = findHidden(startSlice, goalSlice, dir)
		#push_warning("the first slice that was hidden is: ", currSlice)
		if(currSlice == goalSlice):
			return goalSlice
		#grab the slice that was just behind it
		var prevSlice = arrayRotation(currSlice, currSlice, -dir)
		#until we reach goal slice, keep unhiding slices and rotating
		while(currSlice != goalSlice && currSlice != -1):
			#push_warning("ran rotate with currslice: ", currSlice)
			if(!sliceList[currSlice].is_visible() and unhiddenCount < extraCount and !sliceList[currSlice].defaultNode):
				sliceList[currSlice].show()
				visibleArray[currSlice] = 'V'
				unhiddenCount+=1
				#push_warning("unhid a hidden slice ", unhiddenCount, " goal count: ", extraCount)
			elif(!sliceList[currSlice].is_visible() and sliceList[currSlice].defaultNode):
				sliceList[currSlice].show()
				visibleArray[currSlice] = 'V'
				#push_warning("unhid default slice, no change to additional amount")
			if(sliceList[currSlice].is_visible()):
				sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
				if(dir == 1):
					sliceList[currSlice].rotate_y(sliceList[prevSlice].returnNodeRadians())
					#print("Last slice index: ", prevSlice, " radians: ", sliceList[prevSlice].returnNodeRadians())
				else:
					sliceList[currSlice].rotate_y(-sliceList[prevSlice].returnNodeRadians())
					#print("Last slice index: ", prevSlice, " radians: ", -sliceList[prevSlice].returnNodeRadians())
				sliceList[currSlice].transform.origin = Vector3(0,count,0) #count
				#count += 0.1
				prevSlice = currSlice
			currSlice = arrayRotation(currSlice, currSlice, dir)
		additionalTurnAmountA = (sliceList[prevSlice].returnNodeRadians() * (unhiddenCount))
		logger.addToLog("Last slice added after: " + str(prevSlice) + " | Number slices added: " + str(unhiddenCount)
			+ " | Added Rotation Radians: " + str(additionalTurnAmountA) + " | Added Rotation Degrees: " + 
			str(rad_to_deg(additionalTurnAmountA)) + " | Total Rotation Radians: " + str(PI + additionalTurnAmountA))
		return prevSlice
	else:
		logger.addToLog("Last slice added after: None | Number slices added: 0 "
			+ " | Added Rotation Radians: 0 | Added Rotation Degrees: 0 | Total Rotation Radians: " + str(PI + additionalTurnAmountA))
		return goalSlice
		#unhide it and shuffle the next slice over (return the shuffled slice index)
		#repeat until goalSlice reached

#hides slices between the two goals...	
func moverOverHide(startSlice, goalSlice, dir, extraCount):
	#push_warning("Entered mover over HIDE")
	var count = 0 #debugging variable
	var unhiddenCount = 0
	var currSlice = startSlice
	if(startSlice != goalSlice):
		#currSlice is already the next slice we want to hide
		if(currSlice == goalSlice):
			return goalSlice
		#grab the slice that was just behind it
		var prevSlice = startSlice
		currSlice = arrayRotation(currSlice, currSlice, dir)
		#until we reach goal slice, keep unhiding slices and rotating
		while(currSlice != goalSlice && currSlice != -1):
			#push_warning("ran rotate hide with currslice: ", currSlice)
			if(sliceList[currSlice].is_visible() and unhiddenCount < extraCount and sliceList[currSlice].defaultNode):
				sliceList[currSlice].hide()
				visibleArray[currSlice] = 'H'
				unhiddenCount+=1
				#push_warning("hid a default slice ", unhiddenCount, " goal count: ", extraCount)
			elif(sliceList[currSlice].is_visible() and !sliceList[currSlice].defaultNode):
				sliceList[currSlice].hide()
				visibleArray[currSlice] = 'H'
				#push_warning("hid extra slice, no additional slice counted")
			if(sliceList[currSlice].is_visible()):
				#push_warning("entered into rotate based on previous slice. CurrSlice: ", currSlice, " prev Slice: ", prevSlice)
				sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
				if(dir == 1):
					sliceList[currSlice].rotate_y(sliceList[prevSlice].returnNodeRadians())
					#print("Last slice index: ", prevSlice, " radians: ", sliceList[prevSlice].returnNodeRadians())
				else:
					#clunky af, just this one edge case causing issues tho, so tried to hard code a fix
					#just to get this done
					if((startSlice == 27  and prevSlice == 27) or (startSlice == 9  and prevSlice == 9)):
						sliceList[currSlice].rotate_y(-sliceList[currSlice].returnNodeRadians())
					else:
						sliceList[currSlice].rotate_y(-sliceList[prevSlice].returnNodeRadians())
					#print("Last slice index: ", prevSlice, " radians: ", -sliceList[prevSlice].returnNodeRadians())
				sliceList[currSlice].transform.origin = Vector3(0,count,0) #count
				#count += 0.1
				prevSlice = currSlice
			currSlice = arrayRotation(currSlice, currSlice, dir)
		additionalTurnAmountA = (sliceList[prevSlice].returnNodeRadians() * (unhiddenCount))
		logger.addToLog("Last slice added after: " + str(prevSlice) + " | Number slices subtracted: " + str(unhiddenCount)
			+ " | Subtracted Rotation Radians: " + str(additionalTurnAmountA) + " | Subtracted Rotation Degrees: " + 
			str(rad_to_deg(additionalTurnAmountA)) + " | Total Rotation Radians: " + str(PI - additionalTurnAmountA))
		return prevSlice
	else:
		logger.addToLog("Last slice subtracted after: None | Number slices subtracted: 0 "
			+ " | Subtracted Rotation Radians: 0 | Subtracted Rotation Degrees: 0 | Total Rotation Radians: " + str(PI))
		return goalSlice
		
#move slices between the next goal slice and the end of the seen slices over,
#hiding them if they overlap/are past with the last seen slice
#edge case still remains where the last slice is one of the two goalslices
#and the overlap is near the end of the slice so not caught as overlap
func moveOverAlt(start, end, dir, goalSliceA):
	#push_warning("Running move over alt")
	#var count = 0.5 #used to debug - makes each moved slice a little lower
	var goalSlice = start;
	firstHiddenSliceIndex = -1
	if(start != end):
		var isOverlapping = false
		var firstSlice = true
		#print("entered move over ", amount, " index ", index, " stoppingPoint ", stoppingPoint)
		var currSlice = start
		var prevSlice = arrayRotation(start,start, -dir)
		#firstHiddenSliceIndex = arrayRotation(end, end, dir)
		while(currSlice != -1  and currSlice != end):
			#push_warning("curr Slice: ", currSlice, " stoppingPoint: ", end, " direction: ", dir)
			if(sliceList[currSlice].is_visible() and sliceList[currSlice].defaultNode):
				sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
				if(dir == 1):
					sliceList[currSlice].rotate_y(sliceList[prevSlice].returnNodeRadians()*dir)
				elif(dir == -1):
					sliceList[currSlice].rotate_y(sliceList[currSlice].returnNodeRadians()*dir) #currSlice
				#sliceList[currSlice].transform.origin.y -= count
				#count+=0.1
				#sliceList[currSlice].addToAngle(amount)
				if(isOverlapping and currSlice != goalSliceA): #currSlice != goalSlice
					sliceList[currSlice].hide()
					visibleArray[currSlice] = 'H'
					lastHidden = currSlice
					#push_error("Hidden slice: ", currSlice)
					#sliceList[currSlice].transform.origin.y += 6
				elif(isPastBoundary(end, currSlice, dir) and currSlice != goalSliceA):
					#print("ENTERED INTO OVERLAP currSlice: ", currSlice, " stopping point: ", end)
					#push_error("First Hidden slice: ", currSlice)
					sliceList[currSlice].hide()
					visibleArray[currSlice] = 'H'
					firstHiddenSliceIndex = currSlice
					#sliceList[currSlice].transform.origin.y += 6
					isOverlapping = true
				prevSlice = currSlice
				currSlice = arrayRotation(end, currSlice, dir)
			else:
				sliceList[currSlice].hide()
				visibleArray[currSlice] = 'H'
				currSlice = arrayRotation(end, currSlice, dir)
	return firstHiddenSliceIndex
	
#moves the slices behind the player over as required
#specifically between the goal slice and the original goal slice the player was facing
# start = the goalSlice the player is turning towards
# end = the goalSlice the player was originally facing
# dir = the direction the player is turning in
func moveOverReplace(start, end, dir):
	#push_warning("Running move over replace")
	#var count = 0.5 #used to debug - makes each moved slice a little lower
	var goalSlice = start;
	firstHiddenSliceIndex = -1
	if(start != end):
		var isOverlapping = false
		var firstSlice = true
		#print("entered move over ", amount, " index ", index, " stoppingPoint ", stoppingPoint)
		var currSlice = start
		var prevSlice = arrayRotation(start,start, -dir)
		#firstHiddenSliceIndex = arrayRotation(end, end, dir)
		while(currSlice != -1  and currSlice != end):
			#push_warning("curr Slice: ", currSlice, " stoppingPoint: ", end, " direction: ", dir, " for moveOverReplace")
			if(sliceList[currSlice].defaultNode):
				sliceList[currSlice].show()
				visibleArray[currSlice] = 'V'
				sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
				if(dir == 1):
					sliceList[currSlice].rotate_y(sliceList[prevSlice].returnNodeRadians()*dir)
				elif(dir == -1):
					sliceList[currSlice].rotate_y(sliceList[currSlice].returnNodeRadians()*dir) #currSlice
				
				
				if(isPastBoundary(end, currSlice, dir) and currSlice != end):
					#print("ENTERED INTO OVERLAP currSlice: ", currSlice, " stopping point: ", end, " for moveOverReplace")
					#push_error("First Hidden slice: ", currSlice)
					sliceList[currSlice].hide()
					visibleArray[currSlice] = 'H'
					firstHiddenSliceIndex = currSlice
					#sliceList[currSlice].transform.origin.y += 6
					isOverlapping = true
					return
				prevSlice = currSlice
			currSlice = arrayRotation(end, currSlice, dir)
	return

#makes all slices visible if any were invisible, then gives the index of the last hidden slice that was unhidden			
func unhideSliceAlt2(direction, startSlice, lastSeenSlice):
	#push_warning("entered unhide slice alt with inputs: ", direction, " ", startSlice, " ", lastSeenSlice)
	#var debugCount = 0.5
	var prevSlice = startSlice
	var isOverlapping = false
	var currSlice = arrayRotation(startSlice, startSlice, direction)
	#stop moving over when we reached the edge of the users view or back at the slice we began with
	while(currSlice != -1 and currSlice != lastSeenSlice): 
		#push_warning("currSlice: ", currSlice, " prev slice: ", prevSlice)
		#if the next slice is visible or should be visible (ie a default node)
		if(sliceList[currSlice].is_visible() or sliceList[currSlice].defaultNode): 
			#push_warning("currSlice is visible or meant to be visible: ", currSlice)
			#check if it's supposed to be visible # just made this an assumption for now
			#if so, rotate past last slice and set as the next slice to base turning off
			sliceList[currSlice].show()
			visibleArray[currSlice] = 'V'
			sliceList[currSlice].transform.basis = sliceList[prevSlice].transform.basis
			if(direction == 1):
				sliceList[currSlice].rotate_y(sliceList[prevSlice].returnNodeRadians()*direction)
			elif(direction == -1):
				sliceList[currSlice].rotate_y(sliceList[currSlice].returnNodeRadians()*direction)
			#sliceList[currSlice].transform.origin.y += debugCount
			prevSlice = currSlice 
#			if(isOverlapping): # and index != goalSlice):
#				sliceList[currSlice].hide()
#				push_error("Hidden slice: ", currSlice)
#					#sliceList[currSlice].transform.origin.y += 6
#			elif(overlappingAlt(lastSeenSlice, currSlice, -direction)):
#				print("ENTERED INTO OVERLAP currSlice: ", currSlice, " stopping point: ", lastSeenSlice)
#				push_warning("lastSeenSlice: ", lastSeenSlice, " array: ", visNote.currSeen)
#				push_warning("First Hidden slice on unhide procedure: ", currSlice)
#				sliceList[currSlice].hide()
#				firstHiddenSliceIndex = currSlice
#					#sliceList[currSlice].transform.origin.y += 6
#				isOverlapping = true
		currSlice = arrayRotation(startSlice, currSlice, direction)
		#debugCount += 0.1
			
			#if not, make the slice invsible and move onto the next slice.
			
#End adding removing slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# Finding Slice ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~      
#alternate way of finding slices that relies on signals rather than loops
func findSliceUserCanSeeAlt(dir):
	var start
	var end
	var startOb = getGoal(dir)
	#push_error("curr facing goal: ", startOb[0], " next goal: ", startOb[1])
	currFacingGoal = startOb[0]
	var startEn = visNote.findVisible()
	#var startEn = visNote.findVisibleFromGoal(startOb[0], dir)
	#push_error("entered findSliceUserCanSeeAlt with key variables: ", startEn, " dir ", dir, " ", visNote.currSeen)
	if(dir == 1):
		start = startEn[1]
		end = startEn[0]  #- dir			
		if(start < end or abs(start - end) >= (sliceList.size()/2)): #1.9 before, see if this causes errors. New distance is 18 slices
			#push_warning("entered ", start, " < ", end, " direction: ", dir)
			start = startEn[0]
			end = startEn[1] #- dir
	else:
		start = startEn[0]
		end = startEn[1] #- dir
		if(end < start or abs(start - end) >= (sliceList.size()/2) ):
			#push_warning("entered ", end, " < ", start, " direction: ", dir)
			start = startEn[1]
			end = startEn[0] #- dir
	if(end < 0):
		end = sliceList.size()-1
	if(end >= sliceList.size()):
		end = 0
	var temp = [start, startOb[1], end]
	currFacingEnd = end
	logger.addToLog("The slices are: " + str(temp) + " | Visible slices: " 
	+ str(visNote.currSeen) + " | Shown Slices: " + str(visibleArray))
	#push_error(visNote.currSeen)
	return temp
		
func findHidden(startSlice, goalSlice, dir):
	var currSlice = startSlice
	while(currSlice != -1):
		if(currSlice == goalSlice):
			return goalSlice
		if(!sliceList[currSlice].is_visible()):
			return currSlice
		currSlice = arrayRotation(startSlice, currSlice, dir)
	return -1
	
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
		#push_error("NO GOAL SLICE FOUND, DEFAULTING TO GOALCYLINDER SCENARIO")
		return [sliceList.find(goalCylinder.get_parent()), sliceList.find(goalCube.get_parent())]
	pass
#end finding slices methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#array rotation methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#gets the next index in an array rotation based on the current index, the starting index and the direction
#currValue is the one that changes are based on
#startValue gives the stopping condition
func arrayRotation(startValue, currValue, direction):
#    push_warning("array rotation ran with inputs ", startValue, " dir ", direction, " curr value", currValue)
	if(direction == 1):
		if(startValue -1  == currValue or (startValue == 0 and currValue >= sliceList.size() - 1)):
			#push_warning("rotated to end of array -1  ", startValue, "    ", currValue, "   ", direction)
			return -1
		currValue += 1
		if(currValue >= sliceList.size()):
			currValue = 0
	elif(direction == -1):
		if(startValue +1  == currValue):
			#push_warning("rotated to end of array -1  ", startValue, "    ", currValue, "   ", direction)
			return -1
		currValue -= 1
		if(currValue < 0):
#            push_error("entered if")
			currValue = sliceList.size() - 1
	#push_warning("array rotation ran with output ",currValue)
	#push_warning(currValue)
	return currValue
	
#checks if the current slice overlaps or nearly overlaps with the boundary slice (generally the last slice the user can see)
#if it does, sends back message to hide that slice.
func isPastBoundary(testSlice, inputSlice, dir):
	#push_error("Euler angles inputSlice: ", sliceList[inputSlice].transform.basis.get_euler()[1], " rotation degrees: ", sliceList[inputSlice].rotation_degrees)
	#push_error("Euler angles testSlice: ", sliceList[testSlice].transform.basis.get_euler()[1], " rotation degrees: ", sliceList[testSlice].rotation_degrees)
	if(dir == 1):
		var upperBound = (sliceList[inputSlice].transform.basis.get_euler()[1] + 0.2)
		var lowerBound = sliceList[inputSlice].transform.basis.get_euler()[1] - 0.2
		#push_error("Upper bound: ", upperBound, " LowerBound: ",lowerBound, "testSlice angle: ", sliceList[testSlice].transform.basis.get_euler()[1])
		if((testSlice > 2.7 and upperBound < -2.7) or (testSlice < -2.7 and lowerBound > 2.7)):
			#push_warning("hit edge case ", -testSlice, " = -testSlice and upprbound =", upperBound)
			if(-sliceList[testSlice].transform.basis.get_euler()[1] < upperBound and 
			-sliceList[testSlice].transform.basis.get_euler()[1] > lowerBound):
				return true
		elif(sliceList[testSlice].transform.basis.get_euler()[1] < upperBound and 
		sliceList[testSlice].transform.basis.get_euler()[1] > lowerBound):
			#push_error("ran opposite direction ie > upperBound and <lowerBound")
			return true
		elif(lowerBound > upperBound and (sliceList[testSlice].transform.basis.get_euler()[1] > lowerBound or 
		sliceList[testSlice].transform.basis.get_euler()[1] < upperBound)):
			#push_error("reached isPastBoundary edge case condition 1")
			return true
		return false
	elif(dir == -1):
		var upperBound = (sliceList[testSlice].transform.basis.get_euler()[1] + 0.2)
#		if(upperBound > 2*PI):
#			upperBound -= (2*PI)
		var lowerBound = sliceList[testSlice].transform.basis.get_euler()[1] - 0.2
#		if(lowerBound < 0):
#			lowerBound = lowerBound + (2*PI)
		#push_error("Upper bound: ", upperBound, " LowerBound: ",lowerBound, "inputSlice angle: ", sliceList[inputSlice].transform.basis.get_euler()[1])
		if((inputSlice > 2.7 and upperBound < -2.7) or (inputSlice < -2.7 and lowerBound > 2.7)):
			#push_warning("hit edge case ", -testSlice, " = -testSlice and upprbound =", upperBound)
			if(-sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound and 
			-sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound):
				return true
		
		elif(sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound and 
		sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound):
			#push_error("ran opposite direction ie > upperBound and <lowerBound")
			return true
			
		elif(sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound and 
		sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound):
			return true
		#edge case
		elif(sliceList[inputSlice].transform.basis.get_euler()[1] > upperBound and 
		sliceList[inputSlice].transform.basis.get_euler()[1] < lowerBound):
			#push_error("ran opposite direction ie > upperBound and <lowerBound")
			return true
		elif(lowerBound > upperBound and (sliceList[inputSlice].transform.basis.get_euler()[1] > lowerBound or 
		sliceList[inputSlice].transform.basis.get_euler()[1] < upperBound)):
			#push_error("reached isPastBoundary edge case condition -1")
			return true
		return false
	return false
	
#End Array rotation methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Helper methods for choosing segments~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#these are closer to hard coded as this specific use is based on the experiment
#that is currently being run
func printVisibleArray():
	for slice in sliceList:
		if(slice.is_visible()):
			visibleArray.append("V")
		else:
			visibleArray.append("H")
	return visibleArray

#choose number of slices to add to the turn
#if it is 5 or 6 and those options have not been exhausted yet, choose them
#otherwise select randomly from the other options	
func maxAddition(startSlice, seenGoal):
	#returns the maximum number of slices that could be added/subtracted into the turn
	#ideally we want to keep the two slices next to the goal slice in tact
	#so removing slices should happen between the edge of the users view and as far away from the goal slice as possible
	if(startSlice > seenGoal - 3 and startSlice < seenGoal + 3):
		return 6
	elif(startSlice > seenGoal - 5 and startSlice < seenGoal + 5):
		return 5
	elif(startSlice > seenGoal - 7 and startSlice < seenGoal + 7):
		return 4
	elif(startSlice > seenGoal - 9 and startSlice < seenGoal + 9):
		return 3
	elif(startSlice > seenGoal - 11 and startSlice < seenGoal + 11):
		return 2
	elif(startSlice > seenGoal - 13 and startSlice < seenGoal + 13):
		return 1
	else:
		return 0

#randomly selects an element from a list of slice additions/subtractions that is smaller/equal than the max			
func reroll(constraint):
	var i = 0
	var temp = 7
	var randomStop = 0 #on the off chance that there is no nice number left in the array
						#based on our constraints
	while(temp > constraint and randomStop < 50):
		i = randi_range(0,possibleRadianAmounts.size()-1)
		temp = abs(possibleRadianAmounts[i])
		randomStop += 1
	if(randomStop >= 50):
		if(backupZeroes.size() > 0):
			return backupZeroes.pop_back()
		return 0
	temp = possibleRadianAmounts[i]
	possibleRadianAmounts.remove_at(i)
	return temp
	
#chooses the numbers of slices that should be added/subtracted from the turn
func chooseFromList(startSlice, seenGoal):
	
	var max = maxAddition(startSlice, seenGoal) #max slices that can be added
	if(max == 6 and specialTurnAmounts.size() > 0): #if it's 6, choose from 6/-6 list, if no 6s left will choose 5s
		return specialTurnAmounts.pop_back()
	elif(max == 5 and (specialTurnAmounts.has(-5) or specialTurnAmounts.has(5))): #if it's 5, and there are still 5 turns available, choose those
		return specialTurnAmounts.pop_front()
	elif(max == 0): #if we can't add/subtract choose a 0 from either the 0s list or from the general list
		if(possibleRadianAmounts.has(0)):
			var index = possibleRadianAmounts.rfind(0)
			possibleRadianAmounts.remove_at(index)
		elif(backupZeroes.size() > 0):
			return backupZeroes.pop_back()
		return 0
	else: #if max slices is 1/2/3/4
		if(possibleRadianAmounts.size() <= 0): #if the primary list is empty
			if(backupZeroes.size() > 0): #choose a backup zero if that is not empty
				return backupZeroes.pop_back()
			elif(specialTurnAmounts.size() > 0 and zeroTurnCount < 5): #if there are still 6/5 turns return 0s until a 5/6 turn can be selected
				zeroTurnCount+=1
				return 0 #keep the user turning until they hit a nice 5/6 start as left in the array
			questionnaire.show()
			q2.show()
			get_tree().paused = true
			player_vars.setEnd()
			#get_tree().quit() #otherwise stop the game
			return -10 #stop the game once this is returned
		else:
			return reroll(max) #otherwise, if there is still 1/2/3/4/0s available, randomly select one
		
#End helper methods~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



