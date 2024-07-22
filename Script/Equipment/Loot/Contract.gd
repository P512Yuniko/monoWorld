extends RigidBody2D

@export var type = 0
@export var cash = 0
@export var time = 0
@export var progress = 0
@export var random = false
func _ready():
	if random:
		type = randi_range(0,4)
	$Sprite2D.frame = type
	match type:
		0:
			cash = 2000
			time = -1
			progress = 1
		1:
			cash = 2000
			time = -1
			progress = 1
		2:
			cash = 2000
			time = -1
			progress = 3
		3:
			cash = 2000
			time = -1
			progress = 1
		4:
			cash = 2000
			time = -1
			progress = 1
	$Price.text = str(cash)
	

