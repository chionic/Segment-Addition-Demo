extends Node3D


@export var sliceList = [] #contains list of slices that are in the disk at the beginning of the scene
var count = 1
var totalRadians = (11*PI)/60
var scene = [3,2,1]
# 3 slice = 0.59 radians ~ 33 degrees, 2 slice = 0.392 radians ~ 22 degrees, 1 slice = 0.195 radians ~ 11 degrees
var sliceRadians = [0.58, 0.392, 0.195]
var directionSignal #signal to let us know when user is turning or not
var extraSlices = []

#keeps track of where in the circle the starting slice is (ie the offset in radians of segment33)
var startOffset = 0

#variable to choose which slice to start adding additional slices next to, and which slice to finish with adding slices
var startSlice = 1
var endSlice = 7

var goalCube
var goalCylinder
var user

# Called when the node enters the scene tree for the first time.
func _ready():
	var sliceCount = 0
	#an example of calling a method in another script
	#var x = $SliceList/Segment34.returnNodeRadians() #get_child(1)
	push_error(self)
	for segment in self.get_children():
		sliceList.append(segment)
		sliceCount+=1
		segment.setAngleSoFar(totalRadians)
		totalRadians += segment.returnNodeRadians()
	scene[0] = preload("res://StitchDiskScenes/TestSlices/segment33.tscn")
	scene[1] = preload("res://StitchDiskScenes/TestSlices/segment22.tscn")
	scene[2] = preload("res://StitchDiskScenes/TestSlices/segment11.tscn")
	totalRadians = 0
	#print(sliceList)
	directionSignal = get_parent().get_child(0).isRotating
	directionSignal.connect(addSlicesTest)
	goalCube = self.find_child("LookAtCube", true)
	goalCylinder = self.find_child("LookAtCylinder", true)
	#print(goalCube, " ", goalCylinder)
	user = get_parent().get_child(0)
	#addSlicesTest(1)
	
#test function that just adds smaller slices between every single existing slice	
func addSlicesTest(direction):
	print("signal turn ", direction)
	if(direction == 0): #if the user has stopped turning, we want to remove the added slices
		#remove slices here
		while(extraSlices.size() >= 1): #check if there are extra slices
			var currentSlice = extraSlices[0] #grab the first added slice
			#find it's index in the slice list
			#note: not working properly currently due to slice never being added to said list
			var ind = sliceList.find(currentSlice) - 1
			#remove the slice from slice list - again doesnt work rn
			sliceList.erase(currentSlice)
			#turn the other slices before the removed slice to seal the gap made by the remove slice
			while(ind >= 0):
				#print("start new instance move over ", ind)
				moveOverOnce(ind, sliceRadians[2])
				ind-=1
			#remove the current slice from the extra slices list
			extraSlices.remove_at(0)
			#remove the current slice from the scene (like Unity's destroy method)
			currentSlice.free()
			startOffset = startOffset + 0.195
	#adds slices when the user is turning in a CCW direction	
	elif(direction == 1):
		var startEnd = findStartSlice(direction) #grabs the start and end slices between which we can add extra slices#
		print(startEnd)
		var counter =  startEnd[0] #adds additional slice after the first slice - will need to change this later
		endSlice = startEnd[1] + 1 #the plus one is there so that when more stuff is added to the slice list, it still adds slices
		#wrap back around to the beginning of the array -this still needs a lot of improvement #change this later
		totalRadians = ((counter-1) * 0.575) + startOffset #the point at which our extra slices start getting added
		print(counter, " IS THE CURRENT Start slice index")
		var nextIndex = partialArrayRotation(counter, endSlice, counter+1, 1, 1)
		while(nextIndex != -1):
			push_warning("lots of repeating... ", nextIndex)
#			if(counter < endSlice%sliceList.size()):
#				counter = counter%sliceList.size()
#				endSlice = endSlice%sliceList.size() + 1
#				print("cut counter and endSlice", counter , endSlice)
			moveOverAdd(nextIndex, sliceRadians[2], startEnd[2])
			#else:
				#moveOverAdd(counter, sliceRadians[2])
			totalRadians += sliceList[nextIndex].returnNodeRadians()
			#print("before slice ", totalRadians)
			addSliceToList(2, nextIndex, totalRadians )
			#print("after slice ", totalRadians)
			nextIndex = partialArrayRotation(counter, endSlice, nextIndex, 1, 2)
		totalRadians = 0

	elif (direction == -1):
		#do the same thing but the opposite side
		pass
	
#creates a new slice to put in between the other slices	
func addSliceToList(sliceType, index, rotation):
	#create a new slice
	var instancedScene = scene[sliceType].instantiate()
	#make it a child of the node this script is attached to (stitchDisk)
	add_child(instancedScene)
	#set it to be just below the regular slices (less awful patterns when they overlap, too little to be noticed)
	instancedScene.transform.origin = Vector3(0,-0.502,0)
	#rotate it to fit into the gap left
	instancedScene.rotate_y(rotation)
	#add the width of this slice to the amount we want to rotate in future
	totalRadians += sliceRadians[2]
	#print("total radians after slice list: ", totalRadians)
	#add slice to sliceList (does seem to work now - called segment11, Node3D@6, Node3D@7)
	sliceList.insert(index, instancedScene)
	#add it to the list of extra slices
	extraSlices.append(instancedScene)
	
func moveOverAdd(index, sliceRadian, stopMoving):
	for sliceIndex in range(0,sliceList.size()):
		if(sliceIndex >= index):
			sliceList[sliceIndex].rotate_y(sliceRadian)
			sliceList[sliceIndex].addToAngle(sliceRadian)
			#print(sliceIndex, sliceRadian)

			
			
func moveOverRemove(index, sliceRadian):
	for sliceIndex in range(0,sliceList.size()):
		if(sliceIndex <= index):
			sliceList[index].rotate_y(sliceRadian)
			sliceList[sliceIndex].addToAngle(sliceRadian)
			#print("ran move over ", sliceRadian, sliceList[index])
		else:
			return
			
func moveOverOnce(index, sliceRadian):
	sliceList[index].rotate_y(sliceRadian)
	sliceList[index].addToAngle(sliceRadian)
	#print("Moved slice ", sliceList[index], " by ", sliceRadian)
	

func findStartSlice(dir):
	#find current goal slice
	var startOb = getGoal()
	var endSlice = findEndSlice(startOb, dir)
	print(startOb[1], " found as goal")
	#if(startOb[0] > startOb[1]):
		#print("end slice is greater than start slice")
		#startOb[1] = startOb[1] + sliceList.size()
	var prevSlice = arrayRotation(startOb[0], startOb[0]+1, 1)
	if(dir == 1):
		#grabs the slice after which stuff can be added
		#check slices in positive direction after goal slice
		#print(sliceList[startOb], "found slice")
		while(user.check_if_facing(sliceList[prevSlice].get_child(1),0.3)):
			prevSlice = arrayRotation(startOb[0], prevSlice, 1)
		return [prevSlice, startOb[1], endSlice]
		
#		for x in range(startOb[0]+1, sliceList.size()):
#			#print(sliceList[x].get_child(1))
#			if(!user.check_if_facing(sliceList[x].get_child(1),0.3)):
#				return [x, startOb[1], endSlice]
#
#		for x in range(0, startOb[1]):
#			if(!user.check_if_facing(sliceList[x].get_child(1),0.3)):
#				return [x, startOb[1], endSlice]
		
		pass
	elif(dir == -1):
		return [0, 0]
		#check slices in a negative direction before goal slice
		pass
	
	#find direction user turning
	#find first slice considered out of view
	#set that to be start slice
	#for slice in slices:
		#if(!user.checkIfFacing(slice, 0.5)):
			#return sliceList.find(slice);
func findEndSlice(startEnd, direction):
	var startSlice = startEnd[0] #currently facing object
	var endSlice = startEnd[1] #currently moving towards object
	var currentCheck = partialArrayRotation(startEnd[0], startEnd[1], startEnd[0]+1,direction,1)
	for i in range (max((startSlice%sliceList.size())-3, 0), endSlice):
		push_warning("current slice checking on...", i)
		if(user.check_if_facing(sliceList[i].get_child(1),0.3)):
				return i
	

#check if user is facing either current goal slice - with a threshold of 0 set, it will guarantee one or the other goal slice
#returns first the slice of the goal we are currently closer to, then the presumed end point of the goal slice
func getGoal():
	var a = user.check_if_facing(goalCube, 0)
	#print(goalCube.get_parent(), " ", a, goalCube.transform.basis)
	var b = user.check_if_facing(goalCylinder, 0)
	#print(goalCylinder, " ", b)
	if(b):
		#print("SAW CYLINDER", b)
		#						currently facing				goal
		return [sliceList.find(goalCylinder.get_parent()), sliceList.find(goalCube.get_parent())]
	if(a):
		#print("SAW CUBE!", a, goalCube, goalCube.transform.origin)
		return [sliceList.find(goalCube.get_parent()), sliceList.find(goalCylinder.get_parent())]
	pass


#gets the next index in an array rotation based on the current index, the starting index and the direction
func arrayRotation(startValue, currValue, direction):
	if(startValue -1  == currValue):
		return -1
	elif(direction == 1):
		currValue += 1
		if(currValue >= sliceList.size()):
			currValue = 0
		return currValue
	elif(direction == -1):
		currValue -= 1
		if(currValue < 0):
			currValue = sliceList.size() - 1
	return currValue
	
	
func partialArrayRotation(startValue, endValue, currValue, direction, step):
	push_warning("entered  partial rotation with currValue ", currValue)
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
	

