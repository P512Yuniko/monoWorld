extends Node2D

var hard
var ground
@onready var ground_step = preload("res://Screen/Asset/Entity/Effect/Step.tscn")
@onready var ground_jump = preload("res://Screen/Asset/Entity/Effect/Jump.tscn")
@onready var ground_land = preload("res://Screen/Asset/Entity/Effect/Land.tscn")

var land = true
func step():
	if ground:
		var state = randi_range(0,1)
		if state == 0:
			$Hard1.play()
		else:
			$Hard2.play()
		var ins = ground_step.instantiate()
		ins.global_position = global_position
		get_tree().get_root().add_child(ins)
	else:
		$Hard1.stop()
		$Hard2.stop()
func jump():
	var ins = ground_jump.instantiate()
	ins.global_position = global_position
	get_tree().get_root().add_child(ins)
func _process(_delta):
	if !land and ground:
		var ins = ground_land.instantiate()
		ins.global_position = $Slide.global_position
		get_tree().get_root().add_child(ins)
		land = true
	if !ground:
		land = false
