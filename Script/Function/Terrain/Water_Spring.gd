extends Node2D

var velocity = 0
var force = 0
var height = 0
var target_height = 0
var index = 0
var motion_factor = 0.015
signal splash

func water_update(spring_constant, dampening):
	height = position.y
	var x = height - target_height
	var loss = -dampening * velocity
	force = - spring_constant * x + loss
	velocity += force
	position.y += velocity

func initialize(x_position,id):
	height = position.y
	target_height = position.y
	velocity = 0
	position.x = x_position
	index = id

func set_collision_width(value):
	$Area2D/CollisionShape2D.shape.size.x = value

@onready var splash_particle = preload("res://Screen/Asset/Entity/Effect/Splash.tscn")
func _on_Area2D_body_entered(body):
	var s = splash_particle.instantiate()
	if body.get_class() == "RigidBody2D":
		s.amount = 1 + int(body.linear_velocity.y/500)
		s.initial_velocity_max = abs(body.linear_velocity.y)/2 + abs(body.linear_velocity.x)/8
		var speed = (body.linear_velocity.y - abs(body.linear_velocity.x)/4) * motion_factor
		emit_signal("splash",index,speed)
	if body.get_class() == "CharacterBody2D":
		s.amount = 1 + int(body.velocity.y/500)
		s.initial_velocity_max = abs(body.velocity.y)/2 + abs(body.velocity.x)/4
		var speed = (body.velocity.y - abs(body.velocity.x)) * motion_factor
		emit_signal("splash",index,speed)
	s.global_position = body.global_position
	get_tree().get_root().add_child(s)
	
