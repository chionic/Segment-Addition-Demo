extends Node3D

#the first node the use can see
var firstSeen
var backupFirst
#the first node the user cannot see, this keeps track of the last node that EXITED the screen, ie last node safe to change
var lastSeen 
var backupLast

var currSeen = [0,0,0,0,0,0,0,0,0,0]

#connected signal list
var signalConnections


# Called when the node enters the scene tree for the first time.
func _ready():
	#grab all the visibility nodes and connect their signals
	pass # Replace with function body.


func createCurrSeen(siz):
	siz = siz - 10
	for i in siz:
		currSeen.append(0)
	print(currSeen)

func _on_visible_on_screen_notifier_3d_screen_entered(arg):
	#print("NODE ENTERED SCREEN WITH INDEX ", arg)
	currSeen[arg] = 1
	firstSeen = arg
	pass # Replace with function body.


func _on_visible_on_screen_notifier_3d_screen_exited(arg):
	#print("NODE EXITED SCREEN WITH INDEX ", arg)
	currSeen[arg] = 0
	lastSeen = arg
	pass # Replace with function body.
	
func getLastSeen():
	return lastSeen
	
func findVisible():
	var first =currSeen.find(1)
	var last = currSeen.rfind(1)
	#this takes care of the scenario where the user has 0/10 centred in their view
	#altered to include the -2 because the last slice in the list can be hidden with the changes made to the slice order
	if((last == currSeen.size()-1 or last == currSeen.size()-2) and first == 0):
		var end = currSeen.size()-1
		if(currSeen[currSeen.size()-1] == 0):
			end = currSeen.size()-2 
		while(currSeen[end] == 1):
			end-=1
			if(currSeen[end] == 0):
				end-=1
		last = end+2
		var start = 0
		while(currSeen[start] == 1):
			start+=1
			if(currSeen[start] == 0):
				start+=1
		first = start -2
	#if there is a split condition (eg [0,1,0,1,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0,0] or [0,0,1,1,0,0,0,0,0,0,1,1,0,1,0,1,0,1,0,1]
	#elif(last - first > 10):
		#find the largest 0/1 consecutive subset and use that as the seen scenarios
	#	pass
	#push_error("findVisible, first: ", first, " last: ", last, "currSeen: ", currSeen)
	return [first,last]
	
	
func findVisibleEdgeCase(goalSlice, dir, lastHiddenIndex):
	#push_warning("entered findVisibleEdgeCase ", currSeen)
	var centre = goalSlice
	#look left and loop
	var doubleZero = false
	var left = goalSlice
	while(!doubleZero):
		#push_warning("current left: ", left)
		if(left == 1):
			if(currSeen[left-1] == 1):
				left = 0
			elif(currSeen[left] == 1):
				left = 1
			else:
				left = 2
		elif(currSeen[left-1] == 0 and currSeen[left-2]==0):
			doubleZero = true;
		else:
			left-=1
	#push_warning("found left ", left)
	var right = goalSlice
	doubleZero = false
	var size = currSeen.size() - 1
	while(!doubleZero):
		if(right == size-2):
			if(currSeen[size] == 1):
				left = size
			elif(currSeen[size - 1] == 1):
				left = size - 1
			else:
				left = size -2
		elif(currSeen[right+1] == 0 and currSeen[right+2]==0):
			doubleZero = true;
		else:
			right+=1
	#push_warning("found right ", right)		
	if(abs(right - lastHiddenIndex) < abs(left - lastHiddenIndex)):
		#push_warning("returned ", right," ",left )
		return [right, left]
	else:
		#push_warning("returned ", left, " ", right)
		return [left, right]
	
func findVisibleFromGoal(goalSlice, dir):
	#push_warning("entered findVisibleEdgeCase ", currSeen)
	var centre = goalSlice
	#look left and loop
	var doubleZero = false
	var left = goalSlice
	while(!doubleZero):
		#push_warning("current left: ", left)
		if(left == 1):
			if(currSeen[left-1] == 1):
				left = 0
			elif(currSeen[left] == 1):
				left = 1
			else:
				left = 2
		elif(currSeen[left-1] == 0 and currSeen[left-2]==0):
			doubleZero = true;
		else:
			left-=1
	#push_warning("found left ", left)
	var right = goalSlice
	doubleZero = false
	var size = currSeen.size() - 1
	while(!doubleZero):
		if(right == size-2):
			if(currSeen[size] == 1):
				left = size
			elif(currSeen[size - 1] == 1):
				left = size - 1
			else:
				left = size -2
		elif(currSeen[right+1] == 0 and currSeen[right+2]==0):
			doubleZero = true;
		else:
			right+=1
	#push_warning("found right ", right)		
	return [left,right]
	
	
func findVisibleEdgeCase2(goalSlice, dir):
	#push_warning("entered findVisibleEdgeCase2 ", currSeen, " with goalSlice: ", goalSlice, " dir ", dir)
	var centre = goalSlice
	#look left and loop
	var doubleZero = false
	var left = goalSlice
	while(!doubleZero):
		#push_warning("current left: ", left)
		if(left == 1):
			if(currSeen[left-1] == 1):
				left = 0
			elif(currSeen[left] == 1):
				left = 1
			else:
				left = 2
			doubleZero = true
		elif(currSeen[left-1] == 0 and currSeen[left-2]==0):
			doubleZero = true
		else:
			left-=1
	#push_warning("found left ", left)
	var right = goalSlice
	doubleZero = false
	var size = currSeen.size() - 1
	while(!doubleZero):
		#push_warning("current right: ", right)
		if(right == size-2):
			if(currSeen[size] == 1):
				left = size
			elif(currSeen[size - 1] == 1):
				left = size - 1
			else:
				left = size -2
			doubleZero = true
		elif(currSeen[right+1] == 0 and currSeen[right+2]==0):
			doubleZero = true
		else:
			right+=1
	#push_warning("found right ", right)
	#if(goalSlice == 9):
	#push_warning("entered if for goalSlice, ", goalSlice)	
	if(dir == -1):
		return [left, right]
	else:
		return [right, left]
#	if(dir == -1):
#		push_warning("returned ", left, " then ", right )
#		return [left, right]
#
#	else:
#		push_warning("returned ", right, " ", left)
#		return [right, left]
#	else:
#		push_warning("entered else for goalSlice, ", goalSlice)
#		if(dir == -1):
#			push_warning("returned ", right, " then ", left)
#			return [right, left]
#
#		else:
#			push_warning("returned ", left, " ", right)
#			return [left, right]
