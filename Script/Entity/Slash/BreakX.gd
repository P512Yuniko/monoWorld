extends Node2D
@onready var prims = preload("res://Screen/Asset/Entity/Effect/Prims2.tscn")
func _ready():
	var ins = prims.instantiate()
	ins.position = global_position
	ins.apply_impulse(Vector2(randi_range(-1000,1000),randi_range(-1000,1000)).rotated(0), Vector2())
	get_tree().get_root().add_child(ins)
	$AnimationPlayer.play("process") 
