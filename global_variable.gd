extends Node

var numberTurns = 0
var end = false

signal hasEnded()


func setEnd():
	hasEnded.emit()
	push_warning("emitted has ended signal")
	end = true


