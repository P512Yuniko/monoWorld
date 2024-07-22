extends Area2D

var level = 1
func _ready():
	$Point.position.y = -25 * level
	$CollisionShape2D.position.y = -25 * level
