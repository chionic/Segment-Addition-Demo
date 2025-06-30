extends Node3D

@export var nodeRadians = 0.19548
@export var defaultNode = false


	
func returnNodeRadians():
	#print(self, " ", nodeRadians)
	return nodeRadians
	
func isDefault():
	return defaultNode

