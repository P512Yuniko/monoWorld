extends RigidBody2D
var dmg = 0
var type = 0
var id = 0
@onready var boom = preload("res://Screen/Asset/Entity/Bullet/Explosive.tscn")
func _physics_process(_delta):
	if linear_damp > -1:
		linear_damp -= 0.5
	$AnimationPlayer.play("Process")
func _on_body_entered(_body):
	if !(_body.is_in_group("Conqueror") and _body.id == id):
		var ins = boom.instantiate()
		ins.dmg = 240
		ins.id = id
		ins.global_position = global_position
		ins.rotation = global_rotation
		get_tree().get_root().call_deferred("add_child",ins)
		queue_free() 
