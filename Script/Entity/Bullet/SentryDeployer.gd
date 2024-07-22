extends RigidBody2D
var facing = 1
@onready var sentry = preload("res://Screen/Asset/Entity/Ally/Sentry.tscn")
func _process(_delta):
	if $Down.is_colliding():
		gravity_scale = 1
		$Spawn.global_rotation_degrees = 0
	elif $Left.is_colliding():
		gravity_scale = 0
		$Spawn.global_rotation_degrees = 90
	elif $Right.is_colliding():
		gravity_scale = 0
		$Spawn.global_rotation_degrees = -90
	else:
		gravity_scale = 1
	if $Down.is_colliding() or $Left.is_colliding() or $Right.is_colliding():
		var ins = sentry.instantiate()
		ins.facing = facing
		ins.global_position = $Spawn.global_position
		ins.rotation = $Spawn.global_rotation
		ins.get_node("Grounded").global_rotation = $Spawn.global_rotation
		get_tree().get_root().add_child(ins)
		queue_free()
func _on_body_entered(body):
	if body.is_in_group("target"):
		Operator.emit_signal("hit")
	
