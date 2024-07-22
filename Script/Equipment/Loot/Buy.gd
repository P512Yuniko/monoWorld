extends RigidBody2D

var open = false

func _ready():
	$Sprite2D/Sprite2D2.position.y = 0
	$Sprite2D/Sprite2D3.position.y = 0
	$Sprite2D/Sprite2D4.position.y = -8
	$Sprite2D/Sprite2D5.position.y = -16
	$Sprite2D/Sprite2D6.position.y = -24
	$Sprite2D/Sprite2D7.position.y = -32
	$Sprite2D/Sprite2D2/Sprite2D8.hide()
func interact():
	open = true
	$Sprite2D/Sprite2D2.position.y = -64
	$Sprite2D/Sprite2D3.position.y = 0
	$Sprite2D/Sprite2D4.position.y = -16
	$Sprite2D/Sprite2D5.position.y = -32
	$Sprite2D/Sprite2D6.position.y = -48
	$Sprite2D/Sprite2D7.position.y = -64
	$Sprite2D/Sprite2D2/Sprite2D8.show()
	
