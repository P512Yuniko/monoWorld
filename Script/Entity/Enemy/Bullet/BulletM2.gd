extends RigidBody2D
var dmg = 0
var count = 0
@onready var hit = preload("res://Screen/Asset/Entity/Bullet/Hit.tscn")
func _physics_process(_delta):
	$Area2D.dmg = dmg
	count += 1
	if count > 200:
		queue_free()
func _on_area_2d_body_entered(_body):
	var ins = hit.instantiate()
	ins.global_position = global_position
	ins.rotation = rotation
	get_tree().get_root().add_child(ins)
	queue_free()
