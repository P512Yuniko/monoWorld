extends RigidBody2D

var time = 20
var trigged = false

func _process(_delta):
	if trigged:
		global_rotation = 0
		$Sprite2D.hide()
		$Particles.emitting = true
		$Particles2.emitting = true
		$CollisionShape2D.disabled = true
		$Area2D/CollisionShape2D.disabled = false
		freeze = true
		if !$Timer.time_left > 0:
			$Timer.start(10)
	else:
		$Sprite2D.show()
		$CollisionShape2D.disabled = false
		$Particles.emitting = false
		$Particles2.emitting = false
		$Area2D/CollisionShape2D.disabled = true
func _on_body_entered(_body):
	trigged = true

func _on_timer_timeout():
	$Area2D.gravity = 980
	$Area2D.linear_damp = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 1)
	tween.play()
	tween.tween_callback(queue_free)

