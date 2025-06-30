extends XRCamera3D

var prevTrans
# Called when the node enters the scene tree for the first time.
func _ready():
	print("transformanything")
	prevTrans = transform
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(transform != prevTrans):
		print(transform)
		prevTrans = transform
	pass
