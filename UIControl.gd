extends Control

#Menu 'screens' reference list
var StartQuestion
var BigSmall
var Presence
var Comfort
var Usability
var Sickness
var Final
var turn = 0
var logger

# horizontal sliders reference list to get what the user input into each
var presenceSlider
var comfortSlider
var usabilitySlider
var sicknessSlider

var wasHidden = false

var container #references the parent node from the other scene this is contained in (ie 2d to 3d sub-viewport)
var player_vars #singleton ref


var sliderMoved = false



# Called when the node enters the scene tree for the first time.
func _ready():
	#sub menus:
	StartQuestion = self.get_child(0).get_child(0)
	Final = self.get_child(0).get_child(6)
	BigSmall = self.get_child(0).get_child(1)
	Presence = self.get_child(0).get_child(2)
	Comfort = self.get_child(0).get_child(3)
	Usability = self.get_child(0).get_child(4)
	Sickness = self.get_child(0).get_child(5)
	
	#sliders:
	presenceSlider = Presence.find_child("HSlider")
	comfortSlider = Comfort.find_child("HSlider")
	usabilitySlider = Usability.find_child("HSlider")
	sicknessSlider = Sickness.find_child("HSlider")
	

	logger = get_tree().get_root().get_child(-1).get_child(-1)
	container = get_parent().get_parent().get_parent()
	player_vars = get_node("/root/GlobalVariable")
	player_vars.hasEnded.connect(finalMessage)
	push_warning("The player vars is: ", player_vars)
	pass

#special instance when the application first begins. 
#make sure the user knows how to use the survey by asking them to press a button first
func startQuestionnaire():
	StartQuestion.show()
	
func _on_button_pressed_start():
	push_warning("on button pressed start ran")
	logger.addToLog("The user started the rotation procedure")
	StartQuestion.hide()
	BigSmall.show()
	get_tree().paused = false
	container.hide()

#menu navigation
#when the button on a previous screen is pressed, changes which submenu screen becomes active
#also logs results of the questionnaire
func startFirstScreen():
	BigSmall.show()

func _on_button_pressed_Big():
	#log here	#push_warning("entered big")
	logger.addToLog(" The turn felt: Bigger | Turn Number: " + str(player_vars.numberTurns+1))
	BigSmall.hide()
	Presence.show()
	
func _on_button_pressed_Same():
	logger.addToLog(" The turn felt: The Same | Turn Number: " + str(player_vars.numberTurns+1))
	BigSmall.hide()
	Presence.show()


func _on_button_pressed_Small():
	#push_warning("entered small")
	logger.addToLog(" The turn felt: Smaller | Turn Number: " + str(player_vars.numberTurns+1))
	BigSmall.hide()
	Presence.show()


func _on_button_pressed_presence():
	if(sliderMoved):
		#get the relevant slider and log the result
		#push_warning("entered presence")
		logger.addToLog(" Presence: " + str(presenceSlider.value) + 
		" | Turn Number: " + str(player_vars.numberTurns+1) )
		presenceSlider.value = 4
		sliderMoved = false
		Presence.hide()
		Comfort.show()
	
func _on_button_pressed_comfort():
	if(sliderMoved):
		#get the relevant slider and log the result
		#push_warning("entered comfort")
		logger.addToLog(" Comfort: " + str(comfortSlider.value ) + 
		" | Turn Number: " + str(player_vars.numberTurns+1))
		comfortSlider.value = 4
		sliderMoved = false
		Comfort.hide()
		Usability.show()
	
func _on_button_pressed_usability():
	if(sliderMoved):
		#push_warning("entered usability")
		player_vars.numberTurns += 1
		logger.addToLog(" Usability: " + str(usabilitySlider.value ) + " | Turn Number: " + str(player_vars.numberTurns))
		usabilitySlider.value = 4
		sliderMoved = false
		Usability.hide()
		if(player_vars.numberTurns%5 == 0):
			Sickness.show()
		else:
			BigSmall.show()
			get_tree().paused = false
			wasHidden = true
			container.hide()
			#self.hide()
		
func _on_button_pressed_sickness():
	if(sliderMoved):
		#push_warning("entered sickness")
		logger.addToLog(" Sickness: " + str(sicknessSlider.value )+ 
		" | Turn Number: " + str(player_vars.numberTurns))
		if(sicknessSlider.value < 2):
			get_tree().quit()
		sicknessSlider.value = 5
		Sickness.hide()
		BigSmall.show()
		sliderMoved = false
		get_tree().paused = false
		wasHidden = true
		container.hide()
		#self.hide()
	
func moveSlider():
	#print("Moved slider")
	sliderMoved = true
	
func finalMessage():
	BigSmall.hide()
	Final.show()
	
	
