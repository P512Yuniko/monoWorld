extends RigidBody2D
var time = 0
var dmg = 0
func _process(_delta):
	if time > 0:
		time -= 1
		modulate.r = lerpf(modulate.r,0,0.05)
		modulate.g = modulate.r
		modulate.b = modulate.r
		modulate.a = 1
	else:
		var tween = create_tween()
		tween.tween_property(self, "modulate",Color(0,0,0,0),1)
		tween.play()
		tween.tween_callback(queue_free)
