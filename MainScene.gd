extends Node3D

var xr_interface: XRInterface
var logger


#setup script - tries to turn Vsync off and just gets openxr working
func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		push_error("OpenXR initialised successfully")
		#save("this is a message for debugging")
		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		var vp: Viewport = get_viewport()
		vp.use_xr = true
		
		# asks for read/write permissions on android the first time this app is opened
		#note that this means the very first time a new version of this app is booted no log file is created
		logger = get_child(-1)
		#print("LOGGER: ", logger)
		OS.request_permissions()
		var sceneName = get_tree().get_current_scene().get_name()
		#print("Scene: ", sceneName)
		logger.updatedSave("Started Scene " + sceneName + " \n")
		#print(get_child(0).name)
		
	else:
		push_error("OpenXR not initialized, please check if your headset is connected")
	
