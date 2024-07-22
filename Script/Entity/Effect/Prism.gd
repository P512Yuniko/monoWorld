extends Sprite2D

func _ready():
	$Timer.start(randf_range(0.5,1))

func _on_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1,1,1,0), 0.5)
	tween.play()
	tween.tween_callback(queue_free)
