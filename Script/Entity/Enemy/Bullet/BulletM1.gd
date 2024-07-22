extends RigidBody2D
var dmg = 0
@onready var hit = preload("res://Screen/Asset/Entity/Effect/Hit.tscn")
func _on_body_entered(_body):
	var ins = hit.instantiate()
	ins.global_position = global_position
	ins.rotation = rotation
	get_tree().get_root().add_child(ins)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
	tween.play()
	tween.tween_callback(queue_free)
	queue_free()

func _on_area_2d_area_entered(_area):
	if !$Area2D.get_parent().is_in_group("danger"):
		queue_free()
