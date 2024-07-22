extends Button
@export var cost = 0
var code = 0
var right = true
var left = true
func _process(_delta):
	if is_hovered():
		$Box.modulate = Color(1,1,1)
	else:
		$Box.modulate = Color(0.7,0.7,0.7)

