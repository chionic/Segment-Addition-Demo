extends Node3D

var sliceList = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var count = 1
var totalRadians = 0
var scene = [3,2,1]
# 3 slice, 2 slice, 1 slice
var sliceRadians = [0.59, 0.392, 0.195]
# Called when the node enters the scene tree for the first time.
func _ready():
	var sliceCount = 0
	#an example of calling a method in another script
	#var x = $SliceList/Segment34.returnNodeRadians() #get_child(1)
	#print(x)
	for segment in $SliceList.get_children():
		sliceList[sliceCount] = segment
		sliceCount+=1
		segment.getAngleSoFar(totalRadians)
		totalRadians += segment.returnNodeRadians()
	scene[0] = preload("res://StitchDiskScenes/TestSlices/segment33.tscn")
	scene[1] = preload("res://StitchDiskScenes/TestSlices/segment22.tscn")
	scene[2] = preload("res://StitchDiskScenes/TestSlices/segment11.tscn")
	while(totalRadians < 2*PI):
		var instancedScene = scene[2].instantiate()
		sliceList[count] = instancedScene
		add_child(instancedScene)
		instancedScene.transform.origin = Vector3(0,0,0)
		instancedScene.rotate_y(totalRadians)
		totalRadians += sliceRadians[2]
		count+=1
		#print(totalRadians)
	calcAngle()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	calcAngle()
	pass

#No longer relevant with current slices
#func grabStartPos(slice):
#	return slice.get_child(0).get_child(2).transform.origin
	
#func grabEndPos(slice):
#	return slice.get_child(0).get_child(1).transform.origin
	
#func addSlice(type, position):

func calcAngle():
	#since the player is rotating in only one axis, it might actually be worth using the rotation property instead.
	#get direction player is currently facing
	print($PlayerPC.transform.basis.z)
	
	#get where obstacle the player should be turning towards is
	#get the area 'behind' the player (out of 140 fov)
	#get the area outside the players focus (out of 60 fov)
	
