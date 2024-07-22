extends RigidBody2D

func _ready():
	set_collision_mask_value(1,false)
	set_collision_mask_value(3,false)
	set_collision_mask_value(5,true)
	await get_tree().create_timer(randf_range(2,5)).timeout
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.2)
	tween.play()
	tween.tween_callback(queue_free)

func _on_body_entered(_body):
	$AudioStreamPlayer2D.play()
	$AudioStreamPlayer2D.volume_db -= 2
	set_collision_mask_value(1,true)
	set_collision_mask_value(3,true)
	
