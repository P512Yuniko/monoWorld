extends Node2D

var level = 5
var speed = [1,-1]
var rotate = 0.0
var point = load("res://Screen/Asset/Function/Hack/Point.tscn")
func _ready():
	$Circle.frame = level - 1
	for i in level:
		var ins = point.instantiate()
		ins.level = level
		ins.rotation = deg_to_rad(360/level) * i
		add_child(ins)
	rotate = speed.pick_random() * level
func _process(_delta):
	rotation_degrees += rotate/2
	
