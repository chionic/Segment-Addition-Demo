#The logging system requires permission from the Android device (eg Quest 2) to save a log file to the system
#this can usually be given the first time the application is started up and is not repeated unless a new version
#of the application is downloaded onto the device
# see: https://docs.godotengine.org/en/stable/classes/class_mainloop.html#signals

extends Node

var returned = "/sdcard/Android/media/logFiles/" #folder on the Android device to store log files in
#two log files created - one gives very detailed frame-by-frame turn direction and change, the other more
#general details of the turn (direction, started, stopped, questionnaire responses  etc)
var fileName
var frameOrientation
var file2

func _ready():
	print("started logging system")
	#Possible save locations:
	#var returned = OS.get_user_data_dir() +"//save_game2.dat"
	#var returned = "user://logs/"
	
	#this one saves it in a folder where the game save files are on the Oculus Quest 2:
	#var returned = "/sdcard/android/data/org.godotengine.TestVR/files/"
	
	#create unique file names for each log based on the day and timestamp (makes it easier to refer back to)
	var time = Time.get_datetime_dict_from_system()
	var timeString = ("%02d_%02d_%02d%02d%02d" % [time.day, time.month,time.hour, time.minute, time.second])
	fileName = "Log_" + timeString + ".log"
	frameOrientation = "TurnDetailed_" + timeString + ".log"
	
	
	#dir_contents(returned) #sanity check for checking android file system
	
	#opens a file (or creates it if it doesn't exist) 
	#if the file exists, it will append the third variable (message to the file)
	#activate this again to start logging
	#updatedSave(returned, fileName, "hello world 2")

	pass

	
func updatedSave(content):
	FileAccess.open(returned+fileName, FileAccess.READ_WRITE)
	var file
	if(FileAccess.file_exists(returned+fileName)):
		file = FileAccess.open(returned+fileName, FileAccess.READ_WRITE)
	if (file == null):
		print("Error! We Don't Have A Save File To Load")
		return
	else:
		file.seek_end(-1)
		file.store_string(content)
		print("the file contains: "+file.get_file_as_string(returned+fileName))
		print(file.get_path())
	file.close()
	
	FileAccess.open(returned+frameOrientation, FileAccess.READ_WRITE)
	if(FileAccess.file_exists(returned+frameOrientation)):
		file2 = FileAccess.open(returned+frameOrientation, FileAccess.READ_WRITE)
	if (file2 == null):
		print("Error! We Don't Have A Save File2 To Load")
		return
	else:
		file2.seek_end(-1)
		file2.store_string(content)
		print("the file contains: "+file2.get_file_as_string(returned+frameOrientation))
		print(file2.get_path())
	print(file2.get_error())
	print(file2.get_path())
	
	print("TRIED TO CREATE LOG FILE")

func addToLog(message):
	var timestamp = Time.get_datetime_string_from_system(true, true)
	var milliseconds = Time.get_ticks_msec()
	var file = FileAccess.open(returned+fileName, FileAccess.READ_WRITE)
	message = timestamp + " | " + str(milliseconds) + " | " + message + "\n"
	if(file == null):
		print("Error, no file found!")
		return	
	else:
		file.seek_end(-1)
		file.store_string(str(message))
		file.close()
		
func logB(message):
	var timestamp = Time.get_datetime_string_from_system(true, true)
	var milliseconds = Time.get_ticks_msec()
	message = timestamp + " | " + str(milliseconds) + " | " + message + "\n"
	if(file2 == null):
		print("Error, no file2 found!")
		return
		
	else:
		file2.seek_end(-1)
		file2.store_string(str(message))
		return
		
func closeFiles():
	file2.close()

	
	
func dir_contents(path):
	var dir = DirAccess.open(path)
	print(dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
